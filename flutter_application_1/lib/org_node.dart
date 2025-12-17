import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class TimeLog {
  final DateTime start;
  DateTime? end;

  TimeLog({required this.start, this.end});

  Duration get duration {
    final endTime = end ?? DateTime.now();
    return endTime.difference(start);
  }
}

class LogEntry {
  final DateTime timestamp;
  final String message;

  LogEntry({required this.timestamp, required this.message});
}

class OrgNode {
  String id;
  String content;
  String description;
  String todoState;
  bool isExpanded;
  List<OrgNode> children;

  // Timestamps
  DateTime created;
  DateTime? scheduled;
  DateTime? deadline;
  DateTime? closedAt;

  // Clocking
  List<TimeLog> clockLogs;

  // History/Change Log
  List<LogEntry> history;

  // Custom Metadata
  Map<String, String> properties;
  List<String> tags;

  OrgNode({
    String? id,
    this.content = '',
    this.description = '',
    this.todoState = 'TODO',
    this.isExpanded = true,
    List<OrgNode>? children,
    DateTime? created,
    this.scheduled,
    this.deadline,
    this.closedAt,
    List<TimeLog>? clockLogs,
    List<LogEntry>? history,
    Map<String, String>? properties,
    List<String>? tags,
  }) : id = id ?? const Uuid().v4(),
       children = children ?? [],
       created = created ?? DateTime.now(),
       clockLogs = clockLogs ?? [],
       history = history ?? [],
       properties = properties ?? {},
       tags = tags ?? [];

  void addLog(String message) {
    history.add(LogEntry(timestamp: DateTime.now(), message: message));
  }

  // Helper to calculate total time
  Duration get totalTimeSpent {
    Duration total = Duration.zero;
    for (var log in clockLogs) {
      total += log.duration;
    }
    return total;
  }

  // --- Serialization for Persistence ---

  String toMarkdown({int depth = 1}) {
    final buffer = StringBuffer();
    final hashes = '#' * depth;

    // Header: # STATE Content :tag1:tag2:
    final tagsString = tags.isEmpty ? '' : ' :${tags.join(':')}:';
    buffer.writeln('$hashes $todoState $content$tagsString');

    // Timestamps
    if (scheduled != null) {
      buffer.writeln(
        'SCHEDULED: ${DateFormat('yyyy-MM-dd HH:mm').format(scheduled!)}',
      );
    }
    if (deadline != null) {
      buffer.writeln(
        'DEADLINE: ${DateFormat('yyyy-MM-dd HH:mm').format(deadline!)}',
      );
    }
    if (closedAt != null) {
      buffer.writeln(
        'CLOSED: [${DateFormat('yyyy-MM-dd HH:mm').format(closedAt!)}]',
      );
    }

    if (description.isNotEmpty) {
      buffer.writeln('DESC: $description');
    }

    // Properties
    if (properties.isNotEmpty) {
      buffer.writeln(':PROPERTIES:');
      properties.forEach((key, value) {
        buffer.writeln(':$key: $value');
      });
      buffer.writeln(':END:');
    }

    // Clocking logs (using a compact format)
    for (var log in clockLogs) {
      if (log.end != null) {
        buffer.writeln(
          'CLOCK: [${DateFormat('yyyy-MM-dd HH:mm').format(log.start)}]--[${DateFormat('yyyy-MM-dd HH:mm').format(log.end!)}]',
        );
      }
    }

    // History logs
    for (var entry in history) {
      buffer.writeln(
        '- Log: ${DateFormat('yyyy-MM-dd HH:mm').format(entry.timestamp)} | ${entry.message}',
      );
    }

    buffer.writeln(); // Empty line between nodes for readability

    // Children
    for (var child in children) {
      buffer.write(child.toMarkdown(depth: depth + 1));
    }

    return buffer.toString();
  }
}
