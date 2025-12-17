import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'org_node.dart';
import 'node_manager.dart';
import 'org_node_widget.dart';

class TaskDetailView extends StatefulWidget {
  final OrgNode node;
  final NodeManager manager;

  const TaskDetailView({super.key, required this.node, required this.manager});

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descController.text = widget.node.description;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Focus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Future share functionality
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.manager,
        builder: (context, _) {
          final color = widget.manager.getColorForState(widget.node.todoState);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Header Area
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _showStatePicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.node.todoState,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.node.content.isEmpty
                          ? 'Untitled Task'
                          : widget.node.content,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Metadata Row
              _buildMetadataSection(context),

              const Divider(height: 48),

              // Description Section
              _buildSectionTitle('DESCRIPTION', Icons.description_outlined),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Add a detailed description here...',
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) =>
                    widget.manager.updateNodeDescription(widget.node, val),
              ),

              const Divider(height: 48),

              // Comments Section
              _buildSectionTitle('COMMENTS & LOGS', Icons.forum_outlined),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: () {
                      if (_commentController.text.isNotEmpty) {
                        widget.manager.addManualLog(
                          widget.node,
                          _commentController.text,
                        );
                        _commentController.clear();
                      }
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Log Entries
              if (widget.node.history.isEmpty)
                const Center(
                  child: Text(
                    'No activity yet',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                )
              else
                ...widget.node.history.reversed.map(
                  (entry) => _buildLogEntry(context, entry),
                ),

              const Divider(height: 48),

              // Sub-tasks
              _buildSectionTitle('SUB-TASKS', Icons.account_tree_outlined),
              const SizedBox(height: 12),
              if (widget.node.children.isEmpty)
                const Text(
                  'No sub-tasks nested here.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                )
              else
                ...widget.node.children.map(
                  (child) =>
                      OrgNodeWidget(node: child, manager: widget.manager),
                ),

              const SizedBox(height: 80), // Space for FAB
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.manager.addChild(widget.node, ''),
        icon: const Icon(Icons.add),
        label: const Text('Add Sub-task'),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetadataItem(
          label: 'Created',
          value: DateFormat('MMM dd, yyyy').format(widget.node.created),
          icon: Icons.calendar_today,
        ),
        if (widget.node.scheduled != null)
          _MetadataItem(
            label: 'Scheduled',
            value: DateFormat('MMM dd').format(widget.node.scheduled!),
            icon: Icons.event,
            color: Colors.green,
          ),
        if (widget.node.deadline != null)
          _MetadataItem(
            label: 'Deadline',
            value: DateFormat('MMM dd').format(widget.node.deadline!),
            icon: Icons.notification_important,
            color: Colors.red,
          ),
        _MetadataItem(
          label: 'Total Time',
          value: _formatDuration(widget.node.totalTimeSpent),
          icon: Icons.timer_outlined,
          color: Colors.blueGrey,
        ),
      ],
    );
  }

  Widget _buildLogEntry(BuildContext context, LogEntry entry) {
    final isManual = entry.message.startsWith('Manual:');
    final message = isManual
        ? entry.message.replaceFirst('Manual:', '').trim()
        : entry.message;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isManual
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isManual
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text(
                  DateFormat('HH:mm').format(entry.timestamp),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.blueGrey,
                  ),
                ),
                Text(
                  DateFormat('MMM dd').format(entry.timestamp),
                  style: const TextStyle(fontSize: 8, color: Colors.blueGrey),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isManual ? FontWeight.w600 : FontWeight.normal,
                  color: isManual
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  void _showStatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Status',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: widget.manager.todoStates.map((state) {
                    final color = widget.manager.getColorForState(state);
                    final isSelected = widget.node.todoState == state;
                    return InkWell(
                      onTap: () {
                        widget.manager.setNodeState(widget.node, state);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : color.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          state,
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
    return "${d.inMinutes}m ${d.inSeconds.remainder(60)}s";
  }
}

class _MetadataItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _MetadataItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? Colors.blueGrey),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color ?? Colors.blueGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
