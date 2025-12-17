import 'package:flutter/material.dart';
import 'org_node.dart';
import 'node_manager.dart';
import 'org_node_widget.dart';

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
            ...todayTasks.map(
              (n) => OrgNodeWidget(
                node: n,
                manager: manager,
                showChildren: false,
                showIndentation: false,
              ),
            ),

          const SizedBox(height: 32),
          _buildHeader('Pending Tasks', Icons.pending_actions),
          const SizedBox(height: 16),
          if (allTodos.isEmpty)
            _buildEmptyState('All caught up!')
          else
            ...allTodos.map(
              (n) => OrgNodeWidget(
                node: n,
                manager: manager,
                showChildren: false,
                showIndentation: false,
              ),
            ),
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
