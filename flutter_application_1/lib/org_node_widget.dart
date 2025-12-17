import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'org_node.dart';
import 'node_manager.dart';
import 'task_detail_view.dart';

class OrgNodeWidget extends StatelessWidget {
  final OrgNode node;
  final NodeManager manager;
  final int depth;
  final bool showChildren;
  final bool showIndentation;

  const OrgNodeWidget({
    super.key,
    required this.node,
    required this.manager,
    this.depth = 0,
    this.showChildren = true,
    this.showIndentation = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRoot = depth == 0;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Indentation
              if (!isRoot && showIndentation) SizedBox(width: depth * 12.0),

              // Expand/Collapse Icon
              if (node.children.isNotEmpty && showChildren)
                IconButton(
                  icon: Icon(
                    node.isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.7),
                  ),
                  onPressed: () => manager.toggleExpanded(node),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 24,
                )
              else
                const SizedBox(width: 24),

              const SizedBox(width: 8),

              // TODO State Badge
              GestureDetector(
                onTap: () => _showStatePicker(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStateColor(node.todoState),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getStateColor(node.todoState).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    node.todoState,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: node.content)
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: node.content.length),
                    ),
                  onChanged: (val) => manager.updateNodeContent(node, val),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'New task...',
                    hintStyle: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isRoot ? FontWeight.w600 : FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSurface,
                    decoration: node.todoState == 'DONE'
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(
                    icon: Icons.center_focus_strong,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TaskDetailView(node: node, manager: manager),
                      ),
                    ),
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.6),
                  ),
                  _ActionButton(
                    icon: Icons.access_time_filled,
                    onPressed: () => manager.isClockedIn(node)
                        ? manager.clockOut(node)
                        : manager.clockIn(node),
                    color: manager.isClockedIn(node)
                        ? Colors.green
                        : Colors.grey.withOpacity(0.5),
                  ),
                  _ActionButton(
                    icon: Icons.calendar_month,
                    onPressed: () => _showDatePickerMenu(context),
                    color: (node.scheduled != null || node.deadline != null)
                        ? Colors.green
                        : Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.6),
                  ),
                  _ActionButton(
                    icon: Icons.add_circle_outline,
                    onPressed: () => manager.addChild(node, ''),
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.6),
                  ),
                ],
              ),
            ],
          ),

          // Metadata Row
          if (node.scheduled != null ||
              node.deadline != null ||
              node.clockLogs.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: (depth * 12.0) + 64,
                bottom: 8,
                top: 2,
              ),
              child: Wrap(
                spacing: 12,
                children: [
                  if (node.scheduled != null)
                    _MetadataTag(
                      label: 'SCH: ${_formatDate(node.scheduled!)}',
                      color: Colors.green,
                      onTap: () => _pickDate(context, isDeadline: false),
                    ),
                  if (node.deadline != null)
                    _MetadataTag(
                      label: 'DL: ${_formatDate(node.deadline!)}',
                      color: Colors.red,
                      onTap: () => _pickDate(context, isDeadline: true),
                    ),
                  if (node.clockLogs.isNotEmpty)
                    _MetadataTag(
                      label: '🕒 ${_formatDuration(node.totalTimeSpent)}',
                      color: Colors.blueGrey,
                    ),
                  ...node.properties.entries.map(
                    (e) => _MetadataTag(
                      label: '${e.key}: ${e.value}',
                      color: Colors.purple,
                    ),
                  ),
                  ...node.tags.map(
                    (tag) =>
                        _MetadataTag(label: '#$tag', color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
          if (node.description.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: (depth * 12.0) + 64, bottom: 8),
              child: Text(
                node.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );

    if (isRoot && showIndentation) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                content,
                if (node.isExpanded && showChildren) ..._buildChildren(),
              ],
            ),
          ),
        ),
      );
    } else {
      return Column(
        children: [
          content,
          if (node.isExpanded && showChildren) ..._buildChildren(),
        ],
      );
    }
  }

  List<Widget> _buildChildren() {
    return node.children
        .map(
          (child) =>
              OrgNodeWidget(node: child, manager: manager, depth: depth + 1),
        )
        .toList();
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
                  children: manager.todoStates.map((state) {
                    final isSelected = node.todoState == state;
                    return InkWell(
                      onTap: () {
                        manager.setNodeState(node, state);
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
                              ? _getStateColor(state)
                              : _getStateColor(state).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : _getStateColor(state).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          state,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : _getStateColor(state),
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

  void _showDatePickerMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event, color: Colors.green),
              title: const Text('Schedule Task'),
              subtitle: Text(
                node.scheduled == null
                    ? 'Not scheduled'
                    : DateFormat('MMM dd, yyyy').format(node.scheduled!),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickDate(context, isDeadline: false);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.notification_important,
                color: Colors.red,
              ),
              title: const Text('Set Deadline'),
              subtitle: Text(
                node.deadline == null
                    ? 'No deadline'
                    : DateFormat('MMM dd, yyyy').format(node.deadline!),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickDate(context, isDeadline: true);
              },
            ),
            if (node.scheduled != null || node.deadline != null)
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Clear Dates'),
                onTap: () {
                  manager.setScheduled(node, null);
                  manager.setDeadline(node, null);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _pickDate(BuildContext context, {required bool isDeadline}) async {
    final initialDate =
        (isDeadline ? node.deadline : node.scheduled) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: isDeadline ? 'SET DEADLINE' : 'SCHEDULE TASK',
    );
    if (picked != null) {
      if (isDeadline) {
        manager.setDeadline(node, picked);
      } else {
        manager.setScheduled(node, picked);
      }
    }
  }

  Color _getStateColor(String state) => manager.getColorForState(state);

  String _formatDate(DateTime dt) => DateFormat('MMM dd').format(dt);

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
    return "${d.inMinutes}m ${d.inSeconds.remainder(60)}s";
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20, color: color),
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      splashRadius: 20,
    );
  }
}

class _MetadataTag extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _MetadataTag({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
