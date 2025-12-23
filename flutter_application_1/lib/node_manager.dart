import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'org_node.dart';
import 'persistence_manager.dart';
import 'agenda_models.dart';
import 'property_models.dart';
import 'ai_service.dart';

class NodeManager extends ChangeNotifier {
  final List<OrgNode> _rootNodes = [];
  final PersistenceManager _persistence = PersistenceManager();
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  List<String> _todoStates = ['TODO', 'WAITING', 'STALLED', 'DONE'];
  Map<String, Color> _stateColors = {
    'TODO': const Color(0xFF6366F1), // Bright Indigo
    'WAITING': const Color(0xFF818CF8), // Soft Indigo
    'STALLED': const Color(0xFF94A3B8), // Muted Slate
    'DONE': const Color(0xFF4F46E5), // Deep Indigo (Solid)
  };

  Set<String> _doneStates = {'DONE'};

  List<String> _kanbanColumns = ['TODO', 'WAITING', 'STALLED', 'DONE'];

  List<AgendaSection> _agendaSections = [
    AgendaSection(id: '1', title: 'Overdue', startOffset: -30, endOffset: -1),
    AgendaSection(id: '2', title: 'Due Today', startOffset: 0, endOffset: 0),
    AgendaSection(
      id: '3',
      title: 'Personal (Coming Up)',
      startOffset: 1,
      endOffset: 7,
      tags: {'Personal'},
    ),
  ];

  List<String> _allTags = ['Work', 'Personal', 'Shopping'];
  List<PropertyDefinition> _propertyDefinitions = [
    PropertyDefinition(
      key: 'PRIORITY',
      type: PropertyType.options,
      options: ['HIGH', 'MEDIUM', 'LOW'],
    ),
    PropertyDefinition(key: 'LOCATION', type: PropertyType.text),
    PropertyDefinition(key: 'ASSIGNEE', type: PropertyType.text),
    PropertyDefinition(key: 'DONE', type: PropertyType.boolean),
  ];

  String? _apiKey;

  NodeManager() {
    _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    _isLoading = true;
    notifyListeners();
    final data = await _persistence.loadData();
    final List<OrgNode> loadedNodes = data['nodes'] ?? [];

    _rootNodes.clear();
    if (loadedNodes.isNotEmpty) {
      _rootNodes.addAll(loadedNodes);
      if (data['states'] != null) {
        _todoStates = List<String>.from(data['states']);
      }
      if (data['colors'] != null) {
        _stateColors = Map<String, Color>.from(data['colors']);
      }
      if (data['kanban'] != null) {
        _kanbanColumns = List<String>.from(data['kanban']);
      }
      if (data['sections'] != null) {
        _agendaSections = List<AgendaSection>.from(data['sections']);
      }
      if (data['doneStates'] != null) {
        _doneStates = Set<String>.from(data['doneStates']);
      }
      if (data['allTags'] != null) {
        _allTags = List<String>.from(data['allTags']);
      }
      _propertyDefinitions = (data['allPropKeys'] as List<String>)
          .map((s) => PropertyDefinition.deserialize(s))
          .toList();

      if (data['apiKey'] != null) {
        _apiKey = data['apiKey'];
      }
    } else {
      // First run or empty file
      _rootNodes.add(OrgNode(content: "Welcome to Flutter Org Mode"));
      _rootNodes.add(
        OrgNode(
          content: "This data is saved as Markdown in your documents folder!",
        ),
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  void _saveToDisk() {
    _persistence.saveNodes(
      _rootNodes,
      _todoStates,
      _stateColors,
      _kanbanColumns,
      _agendaSections,
      _doneStates.toList(),
      _allTags,
      _propertyDefinitions.map((d) => d.serialize()).toList(),
      _apiKey,
    );
  }

  List<OrgNode> get rootNodes => _rootNodes;
  List<String> get todoStates => _todoStates;
  Map<String, Color> get stateColors => _stateColors;
  List<String> get kanbanColumns => _kanbanColumns;
  List<AgendaSection> get agendaSections => _agendaSections;
  Set<String> get doneStates => _doneStates;
  List<String> get allTags => _allTags;
  List<PropertyDefinition> get propertyDefinitions => _propertyDefinitions;
  String? get apiKey => _apiKey;

  bool isDone(OrgNode node) => _doneStates.contains(node.todoState);

  @override
  void notifyListeners() {
    super.notifyListeners();
    _saveToDisk();
  }

  void addRootNode(String content) {
    _rootNodes.add(OrgNode(content: content));
    notifyListeners();
  }

  void deleteNode(OrgNode node) {
    if (_rootNodes.contains(node)) {
      _rootNodes.remove(node);
    } else {
      _deleteRecursive(_rootNodes, node);
    }
    if (_activeClockNode == node) {
      _activeClockNode = null;
    }
    notifyListeners();
  }

  bool _deleteRecursive(List<OrgNode> nodes, OrgNode target) {
    for (var node in nodes) {
      if (node.children.contains(target)) {
        node.children.remove(target);
        return true;
      }
      if (_deleteRecursive(node.children, target)) return true;
    }
    return false;
  }

  void importFromMarkdown(String markdown) {
    final newNodes = _persistence.parseMarkdown(markdown);
    _rootNodes.addAll(newNodes);
    notifyListeners();
  }

  void setTodoStates(List<String> states, Map<String, Color> colors) {
    _todoStates = states;
    _stateColors = colors;
    notifyListeners();
  }

  Color getColorForState(String state) {
    return _stateColors[state] ?? Colors.blue;
  }

  void setNodeState(OrgNode node, String newState) {
    if (node.todoState != newState) {
      final oldState = node.todoState;
      node.todoState = newState;
      if (isDone(node)) {
        node.closedAt ??= DateTime.now();
        node.addLog('CLOSED: Task marked as Done');
      } else if (_doneStates.contains(oldState)) {
        node.closedAt = null;
        node.addLog('REOPENED: Task moved out of Done');
      }
      node.addLog('State changed from $oldState to $newState');
      notifyListeners();
    }
  }

  void setDoneStates(Set<String> states) {
    _doneStates = states;
    notifyListeners();
  }

  void updateNodeContent(OrgNode node, String newContent) {
    if (node.content != newContent) {
      node.content = newContent;
      notifyListeners();
    }
  }

  void updateNodeDescription(OrgNode node, String newDesc) {
    if (node.description != newDesc) {
      node.description = newDesc;
      notifyListeners();
    }
  }

  void addManualLog(OrgNode node, String message) {
    if (message.isNotEmpty) {
      node.addLog('Manual: $message');
      notifyListeners();
    }
  }

  void setScheduled(OrgNode node, DateTime? date) {
    node.scheduled = date;
    node.addLog(
      date == null
          ? 'Removed scheduled date'
          : 'Scheduled for ${DateFormat('yyyy-MM-dd').format(date)}',
    );
    notifyListeners();
  }

  void setDeadline(OrgNode node, DateTime? date) {
    node.deadline = date;
    node.addLog(
      date == null
          ? 'Removed deadline'
          : 'Deadline set for ${DateFormat('yyyy-MM-dd').format(date)}',
    );
    notifyListeners();
  }

  void setProperty(OrgNode node, String key, String value) {
    if (key.isNotEmpty) {
      if (!_propertyDefinitions.any((d) => d.key == key)) {
        _propertyDefinitions.add(PropertyDefinition(key: key));
      }
      node.properties[key] = value;
      notifyListeners();
    }
  }

  void removeProperty(OrgNode node, String key) {
    if (node.properties.containsKey(key)) {
      node.properties.remove(key);
      notifyListeners();
    }
  }

  void toggleExpanded(OrgNode node) {
    node.isExpanded = !node.isExpanded;
    notifyListeners();
  }

  void addChild(OrgNode parent, String content) {
    final newNode = OrgNode(content: content);
    parent.children.add(newNode);
    parent.isExpanded = true;
    parent.addLog('Added child: ${newNode.id}');
    notifyListeners();
  }

  OrgNode? _activeClockNode;
  OrgNode? get activeClockNode => _activeClockNode;

  void clockIn(OrgNode node) {
    if (_activeClockNode != null && _activeClockNode != node) {
      clockOut(_activeClockNode!);
    }

    final log = TimeLog(start: DateTime.now());
    node.clockLogs.add(log);
    node.addLog('Clocked IN');
    _activeClockNode = node;
    notifyListeners();
  }

  void clockOut(OrgNode node) {
    final activeLogIndex = node.clockLogs.indexWhere((log) => log.end == null);
    if (activeLogIndex != -1) {
      node.clockLogs[activeLogIndex].end = DateTime.now();
      node.addLog(
        'Clocked OUT. Duration: ${node.clockLogs[activeLogIndex].duration}',
      );
    }
    if (_activeClockNode == node) {
      _activeClockNode = null;
    }
    notifyListeners();
  }

  bool isClockedIn(OrgNode node) {
    return node.clockLogs.any((log) => log.end == null);
  }

  // Find a node by ID (useful for navigation if needed)
  OrgNode? findNodeById(String id) {
    return _findRecursive(_rootNodes, id);
  }

  OrgNode? _findRecursive(List<OrgNode> nodes, String id) {
    for (var node in nodes) {
      if (node.id == id) return node;
      final found = _findRecursive(node.children, id);
      if (found != null) return found;
    }
    return null;
  }

  void addTag(OrgNode node, String tag) {
    if (tag.isNotEmpty && !node.tags.contains(tag)) {
      if (!_allTags.contains(tag)) {
        _allTags.add(tag);
      }
      node.tags.add(tag);
      notifyListeners();
    }
  }

  void removeTag(OrgNode node, String tag) {
    if (node.tags.contains(tag)) {
      node.tags.remove(tag);
      notifyListeners();
    }
  }

  void setKanbanColumns(List<String> cols) {
    _kanbanColumns = cols;
    notifyListeners();
  }

  void setAgendaSections(List<AgendaSection> sections) {
    _agendaSections = sections;
    _saveToDisk();
    notifyListeners();
  }

  void setAllTags(List<String> tags) {
    _allTags = tags;
    notifyListeners();
  }

  void setAllPropertyKeys(List<PropertyDefinition> keys) {
    _propertyDefinitions = keys;
    notifyListeners();
  }

  List<OrgNode> collectAllNodes(List<OrgNode> nodes) {
    final List<OrgNode> result = [];
    for (var node in nodes) {
      result.add(node);
      result.addAll(collectAllNodes(node.children));
    }
    return result;
  }

  void setApiKey(String key) {
    _apiKey = key;
    notifyListeners();
  }

  Future<void> magicAdd(String prompt) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API Key not set');
    }
    final service = AIService(_apiKey!);
    final newNodes = await service.generateTasks(prompt);

    // Create a container for the new tasks or add them to root
    if (newNodes.isNotEmpty) {
      if (newNodes.length == 1) {
        // If single task, just add it
        _rootNodes.add(newNodes.first);
      } else {
        // If multiple, maybe group them? Or just add all
        // Adding all to root for now
        _rootNodes.addAll(newNodes);
      }
      notifyListeners();
    }
  }
}
