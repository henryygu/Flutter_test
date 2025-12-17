import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'org_node.dart';
import 'node_manager.dart';
import 'org_node_widget.dart';

class TaskDetailView extends StatelessWidget {
  final OrgNode node;
  final NodeManager manager;

  const TaskDetailView({super.key, required this.node, required this.manager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Focus Task
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.todoState,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        node.content.isEmpty ? '<No Content>' : node.content,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      Text(
                        'Created: ${DateFormat('yyyy-MM-dd HH:mm').format(node.created)}',
                      ),
                      if (node.scheduled != null)
                        Text(
                          'Scheduled: ${DateFormat('yyyy-MM-dd').format(node.scheduled!)}',
                        ),
                      if (node.deadline != null)
                        Text(
                          'Deadline: ${DateFormat('yyyy-MM-dd').format(node.deadline!)}',
                        ),
                      Text(
                        'Total Time: ${_formatDuration(node.totalTimeSpent)}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'History Log',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (node.history.isEmpty)
                const Text(
                  'No history recorded yet.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ...node.history.reversed.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(entry.timestamp),
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.message,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 48),
              const Text(
                'Sub-tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (node.children.isEmpty)
                const Text(
                  'No sub-tasks.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ...node.children.map(
                (child) => OrgNodeWidget(node: child, manager: manager),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => manager.addChild(node, ''),
        child: const Icon(Icons.add_task),
      ),
    );
  }

  String _formatDuration(Duration d) {
    return "${d.inHours}h ${d.inMinutes.remainder(60)}m ${d.inSeconds.remainder(60)}s";
  }
}
