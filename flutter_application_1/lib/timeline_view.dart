import 'package:flutter/material.dart';
import 'org_node.dart';
import 'node_manager.dart';
import 'package:intl/intl.dart';
import 'task_detail_view.dart' as task_detail_view;

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
      appBar: AppBar(
        title: const Text('Timeline'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            onPressed: _showRangeSettings,
            icon: const Icon(Icons.date_range),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.manager,
        builder: (context, _) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: (endOffset >= startOffset)
                ? (endOffset - startOffset + 1)
                : 0,
            itemBuilder: (context, index) {
              final day = today.add(Duration(days: startOffset + index));
              return _buildDaySection(day, allNodes);
            },
          );
        },
      ),
    );
  }

  Widget _buildDaySection(DateTime day, List<OrgNode> allNodes) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(
      const Duration(hours: 23, minutes: 59, seconds: 59),
    );

    final List<_TimelineEvent> events = [];

    for (var node in allNodes) {
      // Scheduled
      if (node.scheduled != null &&
          node.scheduled!.isAfter(
            startOfDay.subtract(const Duration(seconds: 1)),
          ) &&
          node.scheduled!.isBefore(endOfDay)) {
        events.add(
          _TimelineEvent(
            time: node.scheduled!,
            label: 'SCH',
            node: node,
            color: Colors.green,
          ),
        );
      }
      // Deadlines
      if (node.deadline != null &&
          node.deadline!.isAfter(
            startOfDay.subtract(const Duration(seconds: 1)),
          ) &&
          node.deadline!.isBefore(endOfDay)) {
        events.add(
          _TimelineEvent(
            time: node.deadline!,
            label: 'DL',
            node: node,
            color: Colors.red,
          ),
        );
      }
      // Clock Logs
      for (var log in node.clockLogs) {
        if (log.start.isAfter(
              startOfDay.subtract(const Duration(seconds: 1)),
            ) &&
            log.start.isBefore(endOfDay)) {
          events.add(
            _TimelineEvent(
              time: log.start,
              label: 'IN',
              node: node,
              color: Colors.blue,
              detail: 'Clock In',
            ),
          );
        }
        if (log.end != null &&
            log.end!.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            log.end!.isBefore(endOfDay)) {
          events.add(
            _TimelineEvent(
              time: log.end!,
              label: 'OUT',
              node: node,
              color: Colors.blueGrey,
              detail: 'Clock Out',
            ),
          );
        }
      }
      // Done / Closed
      final isDone = widget.manager.isDone(node);
      if (isDone &&
          node.closedAt != null &&
          node.closedAt!.isAfter(
            startOfDay.subtract(const Duration(seconds: 1)),
          ) &&
          node.closedAt!.isBefore(endOfDay)) {
        events.add(
          _TimelineEvent(
            time: node.closedAt!,
            label: 'DONE',
            node: node,
            color: Colors.green,
            detail: 'Task Closed',
          ),
        );
      }
    }

    events.sort((a, b) => a.time.compareTo(b.time));

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
        if (events.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 32, bottom: 16),
            child: Text(
              'No activity scheduled.',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          )
        else
          ...events.map((e) => _buildTimelineItem(e)),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildTimelineItem(_TimelineEvent event) {
    final timeStr = DateFormat('HH:mm').format(event.time);
    final statusColor = widget.manager.getColorForState(event.node.todoState);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time and Label
          SizedBox(
            width: 80,
            child: Row(
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade700,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: event.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    event.label,
                    style: TextStyle(
                      color: event.color,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 2,
            height: 40,
            color: event.color.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => task_detail_view.TaskDetailView(
                    node: event.node,
                    manager: widget.manager,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.node.todoState,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.node.content +
                            (event.detail != null ? ' (${event.detail})' : ''),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          decoration: widget.manager.isDone(event.node)
                              ? TextDecoration.lineThrough
                              : null,
                          color: widget.manager.isDone(event.node)
                              ? Colors.grey
                              : null,
                        ),
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

class _TimelineEvent {
  final DateTime time;
  final String label;
  final OrgNode node;
  final Color color;
  final String? detail;

  _TimelineEvent({
    required this.time,
    required this.label,
    required this.node,
    required this.color,
    this.detail,
  });
}
