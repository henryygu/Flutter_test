import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'org_node.dart';
import 'node_manager.dart';

class AgendaView extends StatelessWidget {
  final NodeManager manager;

  const AgendaView({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    final allNodes = _collectAllNodes(manager.rootNodes);
    final today = DateTime.now();

    final todayTasks = allNodes.where((n) {
      if (n.scheduled != null && isSameDay(n.scheduled!, today)) return true;
      if (n.deadline != null && isSameDay(n.deadline!, today)) return true;
      return false;
    }).toList();

    final allTodos = allNodes.where((n) => n.todoState != 'DONE').toList();

    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildHeader('Your Day', Icons.calendar_today),
          const SizedBox(height: 16),
          if (todayTasks.isEmpty)
            _buildEmptyState('No tasks scheduled for today.')
          else
            ...todayTasks.map((n) => _buildEnhancedTile(context, n)),

          const SizedBox(height: 32),
          _buildHeader('Pending Tasks', Icons.pending_actions),
          const SizedBox(height: 16),
          if (allTodos.isEmpty)
            _buildEmptyState('All caught up!')
          else
            ...allTodos.map((n) => _buildEnhancedTile(context, n)),
        ],
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

  Widget _buildEnhancedTile(BuildContext context, OrgNode node) {
    final color = manager.getColorForState(node.todoState);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          title: Text(
            node.content.isEmpty ? '<Empty>' : node.content,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      node.todoState,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (node.scheduled != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '📅 ${DateFormat('MMM dd').format(node.scheduled!)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 16,
            color: Colors.grey,
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
