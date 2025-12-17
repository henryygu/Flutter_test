import 'package:flutter/material.dart';
import 'org_node.dart';
import 'node_manager.dart';
import 'package:intl/intl.dart';

class TimelineView extends StatefulWidget {
  final NodeManager manager;

  const TimelineView({super.key, required this.manager});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  int startOffset = 0;
  int endOffset = 7;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allNodes = widget.manager.collectAllNodes(widget.manager.rootNodes);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListenableBuilder(
        listenable: widget.manager,
        builder: (context, _) {
          return Column(
            children: [
              _buildTimelineHeader(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: (endOffset >= startOffset)
                      ? (endOffset - startOffset + 1)
                      : 0,
                  itemBuilder: (context, index) {
                    final day = today.add(Duration(days: startOffset + index));
                    return _buildDaySection(day, allNodes);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimelineHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'TIMELINE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.blueGrey,
            ),
          ),
          IconButton.filledTonal(
            onPressed: _showRangeSettings,
            icon: const Icon(Icons.date_range),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(DateTime day, List<OrgNode> allNodes) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(
      const Duration(hours: 23, minutes: 59, seconds: 59),
    );

    final dayTasks = allNodes.where((n) {
      final target = n.scheduled ?? n.deadline;
      if (target == null) return false;
      return target.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          target.isBefore(endOfDay);
    }).toList();

    // Sort by time
    dayTasks.sort((a, b) {
      final ta = a.scheduled ?? a.deadline!;
      final tb = b.scheduled ?? b.deadline!;
      return ta.compareTo(tb);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            DateFormat('EEEE, d MMMM yyyy').format(day),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
        if (dayTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 32, bottom: 16),
            child: Text(
              'No tasks scheduled.',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          )
        else
          ...dayTasks.map((node) => _buildTimelineItem(node)),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildTimelineItem(OrgNode node) {
    final time = node.scheduled ?? node.deadline!;
    final timeStr = DateFormat('HH:mm').format(time);
    final color = widget.manager.getColorForState(node.todoState);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              timeStr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade700,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 2, height: 40, color: color.withValues(alpha: 0.3)),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Navigate to task detail or show popup
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        node.todoState,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        node.content,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRangeSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Timeline Range',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Start Offset',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          startOffset = int.tryParse(v) ?? startOffset,
                      controller: TextEditingController(
                        text: startOffset.toString(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'End Offset',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          endOffset = int.tryParse(v) ?? endOffset,
                      controller: TextEditingController(
                        text: endOffset.toString(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  this.setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
