import 'package:flutter/material.dart';
import 'org_node.dart';
import 'node_manager.dart';
import 'org_node_widget.dart';
import 'agenda_models.dart';
import 'package:uuid/uuid.dart';

class AgendaView extends StatelessWidget {
  final NodeManager manager;

  const AgendaView({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    final sections = manager.agendaSections;
    final allNodes = _collectAllNodes(manager.rootNodes);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeader(
                    'Agenda Dashboard',
                    Icons.dashboard_customize_outlined,
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _showSectionManager(context),
                    tooltip: 'Manage Sections',
                    icon: const Icon(Icons.settings),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (sections.isEmpty)
                _buildEmptyState('No sections configured. Add one in settings!')
              else
                ...sections.map(
                  (s) => _buildSection(context, s, allNodes, now),
                ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    AgendaSection section,
    List<OrgNode> allNodes,
    DateTime now,
  ) {
    final filtered = allNodes.where((n) {
      // 1. Date Filter
      bool dateMatch = false;
      final targetDate = n.deadline ?? n.scheduled;

      switch (section.dateFilter) {
        case DateFilter.overdue:
          dateMatch =
              targetDate != null &&
              targetDate.isBefore(DateTime(now.year, now.month, now.day));
          break;
        case DateFilter.today:
          dateMatch = targetDate != null && isSameDay(targetDate, now);
          break;
        case DateFilter.week:
          if (targetDate == null) break;
          final nextWeek = now.add(const Duration(days: 7));
          dateMatch =
              targetDate.isAfter(now.subtract(const Duration(days: 1))) &&
              targetDate.isBefore(nextWeek);
          break;
        case DateFilter.month:
          dateMatch =
              targetDate != null &&
              targetDate.month == now.month &&
              targetDate.year == now.year;
          break;
        case DateFilter.none:
          dateMatch = true;
          break;
      }

      // 2. Tag Filter
      bool tagMatch =
          section.tags.isEmpty || n.tags.any((t) => section.tags.contains(t));

      // 3. State Filter
      bool stateMatch =
          section.states.isEmpty || section.states.contains(n.todoState);

      return dateMatch && tagMatch && stateMatch;
    }).toList();

    if (filtered.isEmpty) return const SizedBox();

    // Sort: Deadlines first
    filtered.sort((a, b) {
      final da = a.deadline ?? a.scheduled;
      final db = b.deadline ?? b.scheduled;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(section.title, Icons.label_important_outline),
        const SizedBox(height: 12),
        ...filtered.map(
          (n) => OrgNodeWidget(
            node: n,
            manager: manager,
            showChildren: false,
            showIndentation: false,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _showSectionManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final sections = manager.agendaSections;
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Manage Sections',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.blue,
                      ),
                      onPressed: () => _showEditSectionDialog(context, null),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final list = List<AgendaSection>.from(sections);
                      final item = list.removeAt(oldIndex);
                      list.insert(newIndex, item);
                      manager.setAgendaSections(list);
                      setModalState(() {});
                    },
                    children: sections
                        .map(
                          (s) => ListTile(
                            key: ValueKey(s.id),
                            leading: const Icon(Icons.drag_handle),
                            title: Text(s.title),
                            subtitle: Text(
                              '${s.dateFilter.name} | ${s.tags.length} tags | ${s.states.length} states',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () =>
                                      _showEditSectionDialog(context, s),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    final list = List<AgendaSection>.from(
                                      sections,
                                    );
                                    list.remove(s);
                                    manager.setAgendaSections(list);
                                    setModalState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditSectionDialog(BuildContext context, AgendaSection? existing) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    DateFilter selectedDateFilter = existing?.dateFilter ?? DateFilter.none;
    Set<String> selectedTags = Set<String>.from(existing?.tags ?? {});
    Set<String> selectedStates = Set<String>.from(existing?.states ?? {});

    final allTags = _collectAllNodes(
      manager.rootNodes,
    ).expand((n) => n.tags).toSet().toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Section' : 'Edit Section'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Section Title',
                    hintText: 'e.g. Overdue Tasks',
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'DATE FILTER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                DropdownButton<DateFilter>(
                  isExpanded: true,
                  value: selectedDateFilter,
                  items: DateFilter.values
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedDateFilter = val!),
                ),
                const SizedBox(height: 24),
                const Text(
                  'TAGS (ANY OF)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Wrap(
                  spacing: 4,
                  children: allTags
                      .map(
                        (tag) => FilterChip(
                          label: Text(
                            '#$tag',
                            style: const TextStyle(fontSize: 10),
                          ),
                          selected: selectedTags.contains(tag),
                          onSelected: (val) => setDialogState(
                            () => val
                                ? selectedTags.add(tag)
                                : selectedTags.remove(tag),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'STATES (ANY OF)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Wrap(
                  spacing: 4,
                  children: manager.todoStates
                      .map(
                        (state) => FilterChip(
                          label: Text(
                            state,
                            style: const TextStyle(fontSize: 10),
                          ),
                          selected: selectedStates.contains(state),
                          onSelected: (val) => setDialogState(
                            () => val
                                ? selectedStates.add(state)
                                : selectedStates.remove(state),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty) return;
                final newSections = List<AgendaSection>.from(
                  manager.agendaSections,
                );
                final newSect = AgendaSection(
                  id: existing?.id ?? const Uuid().v4(),
                  title: titleController.text,
                  dateFilter: selectedDateFilter,
                  tags: selectedTags,
                  states: selectedStates,
                );
                if (existing != null) {
                  final idx = newSections.indexWhere(
                    (s) => s.id == existing.id,
                  );
                  newSections[idx] = newSect;
                } else {
                  newSections.add(newSect);
                }
                manager.setAgendaSections(newSections);
                Navigator.pop(context);
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.blueGrey,
          ),
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<OrgNode> _collectAllNodes(List<OrgNode> nodes) {
    final List<OrgNode> result = [];
    for (var node in nodes) {
      result.add(node);
      result.addAll(_collectAllNodes(node.children));
    }
    return result;
  }
}
