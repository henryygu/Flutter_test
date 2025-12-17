import 'package:flutter/material.dart';
import 'org_node.dart';
import 'node_manager.dart';
import 'task_detail_view.dart';

class KanbanView extends StatelessWidget {
  final NodeManager manager;

  const KanbanView({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    final allNodes = _collectAllNodes(manager.rootNodes);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: manager.kanbanColumns.map((state) {
            final tasksInState = allNodes
                .where((n) => n.todoState == state)
                .toList();
            return _buildKanbanColumn(context, state, tasksInState);
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showColumnSettings(context),
        child: const Icon(Icons.view_column),
      ),
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context,
    String state,
    List<OrgNode> tasks,
  ) {
    final color = manager.getColorForState(state);

    return DragTarget<OrgNode>(
      onAcceptWithDetails: (details) {
        manager.setNodeState(details.data, state);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? color.withValues(alpha: 0.1)
                : Colors.blueGrey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: candidateData.isNotEmpty ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      state,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final node = tasks[index];
                    return _KanbanCard(node: node, manager: manager);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showColumnSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Visible Columns',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...manager.todoStates.map(
                (state) => CheckboxListTile(
                  title: Text(state),
                  value: manager.kanbanColumns.contains(state),
                  onChanged: (val) {
                    final current = List<String>.from(manager.kanbanColumns);
                    if (val == true) {
                      current.add(state);
                      // Keep order same as todoStates
                      current.sort(
                        (a, b) => manager.todoStates
                            .indexOf(a)
                            .compareTo(manager.todoStates.indexOf(b)),
                      );
                    } else {
                      current.remove(state);
                    }
                    manager.setKanbanColumns(current);
                    setModalState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<OrgNode> _collectAllNodes(List<OrgNode> nodes) {
    final List<OrgNode> result = [];
    for (var node in nodes) {
      result.add(node);
      result.addAll(_collectAllNodes(node.children));
    }
    return result;
  }
}

class _KanbanCard extends StatelessWidget {
  final OrgNode node;
  final NodeManager manager;

  const _KanbanCard({required this.node, required this.manager});

  @override
  Widget build(BuildContext context) {
    return Draggable<OrgNode>(
      data: node,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            node.content.isEmpty ? 'Untitled' : node.content,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildCard(context)),
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.1)),
        ),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TaskDetailView(node: node, manager: manager),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.content.isEmpty ? 'Untitled Task' : node.content,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (node.scheduled != null || node.deadline != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (node.scheduled != null)
                        _Tag(
                          icon: Icons.event,
                          label: _formatDate(node.scheduled!),
                          color: Colors.green,
                        ),
                      if (node.deadline != null) ...[
                        const SizedBox(width: 4),
                        _Tag(
                          icon: Icons.notification_important,
                          label: _formatDate(node.deadline!),
                          color: Colors.red,
                        ),
                      ],
                    ],
                  ),
                ],
                if (node.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: node.tags
                        .map(
                          (tag) => _Tag(
                            icon: Icons.local_offer,
                            label: tag,
                            color: Colors.blueAccent,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.month}/${dt.day}";
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Tag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
