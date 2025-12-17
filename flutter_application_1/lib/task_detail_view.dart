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
  final TextEditingController _propKeyController = TextEditingController();
  final TextEditingController _propValController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descController.text = widget.node.description;
  }

  @override
  void dispose() {
    _descController.dispose();
    _commentController.dispose();
    _propKeyController.dispose();
    _propValController.dispose();
    _tagController.dispose();
    super.dispose();
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
                            color: color.withValues(alpha: 0.3),
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
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) =>
                    widget.manager.updateNodeDescription(widget.node, val),
              ),

              const Divider(height: 48),

              // Tags Section
              _buildTagsSection(context),

              const Divider(height: 48),

              // Properties Section
              _buildPropertiesSection(context),

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
                  (child) => OrgNodeWidget(
                    node: child,
                    manager: widget.manager,
                    depth: 0,
                  ),
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
        _MetadataItem(
          label: 'Scheduled',
          value: widget.node.scheduled == null
              ? 'Set Date'
              : DateFormat('MMM dd HH:mm').format(widget.node.scheduled!),
          icon: Icons.event,
          color: widget.node.scheduled != null ? Colors.green : Colors.grey,
          onTap: () => _pickDate(context, isDeadline: false),
        ),
        _MetadataItem(
          label: 'Deadline',
          value: widget.node.deadline == null
              ? 'Set Date'
              : DateFormat('MMM dd HH:mm').format(widget.node.deadline!),
          icon: Icons.notification_important,
          color: widget.node.deadline != null ? Colors.red : Colors.grey,
          onTap: () => _pickDate(context, isDeadline: true),
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

  Widget _buildPropertiesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('CUSTOM PROPERTIES', Icons.settings_outlined),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddPropertyDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.node.properties.isEmpty)
          const Text(
            'No custom metadata defined.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 13,
              color: Colors.grey,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.node.properties.entries
                .map(
                  (e) => Chip(
                    label: Text(
                      '${e.key}: ${e.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () =>
                        widget.manager.removeProperty(widget.node, e.key),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
                .toList(),
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
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isManual
              ? Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
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
                          color: isSelected
                              ? color
                              : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : color.withValues(alpha: 0.3),
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

  void _pickDate(BuildContext context, {required bool isDeadline}) async {
    final initial =
        (isDeadline ? widget.node.deadline : widget.node.scheduled) ??
        DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: isDeadline ? 'SET DEADLINE' : 'SCHEDULE TASK',
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );

      final finalDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? initial.hour,
        pickedTime?.minute ?? initial.minute,
      );

      if (isDeadline) {
        widget.manager.setDeadline(widget.node, finalDateTime);
      } else {
        widget.manager.setScheduled(widget.node, finalDateTime);
      }
    }
  }

  void _showAddPropertyDialog(BuildContext context) {
    _propKeyController.clear();
    _propValController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Property'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _propKeyController,
              decoration: const InputDecoration(
                hintText: 'Key (e.g. PRIORITY)',
              ),
            ),
            TextField(
              controller: _propValController,
              decoration: const InputDecoration(hintText: 'Value (e.g. HIGH)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.manager.setProperty(
                widget.node,
                _propKeyController.text,
                _propValController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('TAGS', Icons.local_offer_outlined),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.node.tags.map(
              (tag) => Chip(
                label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                onDeleted: () => widget.manager.removeTag(widget.node, tag),
                deleteIcon: const Icon(Icons.close, size: 14),
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 14),
              label: const Text('Add Tag', style: TextStyle(fontSize: 12)),
              onPressed: () => _showAddTagDialog(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddTagDialog(BuildContext context) {
    _tagController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: _tagController,
          decoration: const InputDecoration(hintText: 'Tag name (no spaces)'),
          autofocus: true,
          onSubmitted: (val) {
            widget.manager.addTag(widget.node, val.trim());
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.manager.addTag(widget.node, _tagController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
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
  final VoidCallback? onTap;

  const _MetadataItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
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
        ),
      ),
    );
  }
}
