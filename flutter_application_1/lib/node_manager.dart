import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'org_node.dart';
import 'persistence_manager.dart';

class NodeManager extends ChangeNotifier {
  final List<OrgNode> _rootNodes = [];
  final PersistenceManager _persistence = PersistenceManager();

  List<String> _todoStates = ['TODO', 'WAITING', 'STALLED', 'DONE'];
  Map<String, Color> _stateColors = {
    'TODO': Colors.red,
    'WAITING': Colors.orange,
    'STALLED': Colors.blueGrey,
    'DONE': Colors.green,
  };

  NodeManager() {
    _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
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
    } else {
      // First run or empty file
      _rootNodes.add(OrgNode(content: "Welcome to Flutter Org Mode"));
      _rootNodes.add(
        OrgNode(
          content: "This data is saved as Markdown in your documents folder!",
        ),
      );
    }
    notifyListeners();
  }

  void _saveToDisk() {
    _persistence.saveNodes(_rootNodes, _todoStates, _stateColors);
  }

  List<OrgNode> get rootNodes => _rootNodes;
  List<String> get todoStates => _todoStates;
  Map<String, Color> get stateColors => _stateColors;

  @override
  void notifyListeners() {
    super.notifyListeners();
    _saveToDisk();
  }

  void addRootNode(String content) {
    _rootNodes.add(OrgNode(content: content));
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
      node.addLog('State changed from $oldState to $newState');
      notifyListeners();
    }
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
}
