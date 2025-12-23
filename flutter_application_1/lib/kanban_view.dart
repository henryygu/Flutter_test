import 'package:flutter/material.dart';
import 'org_node.dart';
import 'node_manager.dart';
import 'task_detail_view.dart';
import 'glass_card.dart';

class KanbanView extends StatelessWidget {
  final NodeManager manager;

  const KanbanView({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    final allNodes = manager.collectAllNodes(manager.rootNodes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban Board'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            onPressed: () => _showColumnSettings(context),
            icon: const Icon(Icons.view_column),
          ),
        ],
      ),
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
          margin: const EdgeInsets.only(right: 20),
          child: GlassCard(
            blur: 15,
            opacity: candidateData.isNotEmpty ? 0.15 : 0.05,
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? color
                  : Colors.white.withOpacity(0.05),
              width: 1.5,
            ),
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tasks.length.toString(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final node = tasks[index];
                      return Draggable<OrgNode>(
                        data: node,
                        feedback: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 280,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(node.content),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: _KanbanCard(node: node, manager: manager),
                        ),
                        child: _KanbanCard(node: node, manager: manager),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showColumnSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Kanban Columns",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: manager.todoStates.map((state) {
                      final isSelected = manager.kanbanColumns.contains(state);
                      return FilterChip(
                        label: Text(state),
                        selected: isSelected,
                        onSelected: (val) {
                          final newCols = List<String>.from(
                            manager.kanbanColumns,
                          );
                          if (val) {
                            newCols.add(state);
                          } else {
                            newCols.remove(state);
                          }
                          manager.setKanbanColumns(newCols);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _KanbanCard extends StatelessWidget {
  final OrgNode node;
  final NodeManager manager;

  const _KanbanCard({required this.node, required this.manager});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        blur: 5,
        opacity: 0.08,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            node.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: node.tags.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 6,
                    children: node.tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "#$t",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.7),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TaskDetailView(node: node, manager: manager),
              ),
            );
          },
        ),
      ),
    );
  }
}
