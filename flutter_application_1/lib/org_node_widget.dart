import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'org_node.dart';
import 'node_manager.dart';
import 'task_detail_view.dart';
import 'glass_card.dart';

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
    this.forceCollapsed = false,
  });

  final bool forceCollapsed;

  @override
  Widget build(BuildContext context) {
    final bool isRoot = depth == 0;
    final bool isActive = manager.isClockedIn(node);

    Widget itemContent = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        opacity: isActive ? 0.15 : 0.08,
        blur: isActive ? 30 : 20,
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
              : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05)),
          width: isActive ? 2 : 1.5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Expansion Icon
                if (node.children.isNotEmpty && showChildren)
                  GestureDetector(
                    onTap: () => manager.toggleExpanded(node),
                    child: AnimatedRotation(
                      turns: node.isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 24),

                const SizedBox(width: 8),

                // Status Badge
                GestureDetector(
                  onTap: () => _showStatePicker(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStateColor(node.todoState).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStateColor(node.todoState).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      node.todoState,
                      style: TextStyle(
                        color: _getStateColor(node.todoState),
                        fontWeight: FontWeight.w800,
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
                      hintText: 'Task name...',
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isRoot ? FontWeight.w700 : FontWeight.w500,
                      decoration: manager.isDone(node)
                          ? TextDecoration.lineThrough
                          : null,
                      color: Theme.of(context).colorScheme.onSurface
                          .withOpacity(manager.isDone(node) ? 0.5 : 1.0),
                    ),
                  ),
                ),

                // Action Buttons
                _ActionButton(
                  icon: Icons.more_horiz,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TaskDetailView(node: node, manager: manager),
                    ),
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
                _ActionButton(
                  icon: isActive
                      ? Icons.stop_circle
                      : Icons.play_circle_outline,
                  onPressed: () =>
                      isActive ? manager.clockOut(node) : manager.clockIn(node),
                  color: isActive
                      ? Colors.redAccent
                      : Theme.of(context).colorScheme.primary,
                ),
              ],
            ),

            // Metadata & Description
            if (!forceCollapsed &&
                (node.tags.isNotEmpty || node.scheduled != null))
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (node.scheduled != null)
                      _MetadataTag(
                        label: _formatDate(node.scheduled!),
                        icon: Icons.calendar_today,
                        color: Colors.blueAccent,
                      ),
                    ...node.tags.map(
                      (tag) => _MetadataTag(
                        label: tag,
                        icon: Icons.tag,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(left: isRoot ? 0 : 20, bottom: 8),
      child: Column(
        children: [
          itemContent,
          if (node.isExpanded && showChildren)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(children: _buildChildren()),
            ),
        ],
      ),
    );
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
                              : _getStateColor(state).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : _getStateColor(state).withValues(alpha: 0.3),
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

  Color _getStateColor(String state) => manager.getColorForState(state);

  String _formatDate(DateTime dt) => DateFormat('MMM dd HH:mm').format(dt);
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
  final IconData icon;
  final Color color;

  const _MetadataTag({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
