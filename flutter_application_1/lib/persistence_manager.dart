import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'org_node.dart';
import 'package:intl/intl.dart';
import 'agenda_models.dart';

class PersistenceManager {
  static const String fileName = 'tasks.md';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  Future<void> saveNodes(
    List<OrgNode> nodes,
    List<String> states,
    Map<String, Color> colors,
    List<String> kanbanColumns,
    List<AgendaSection> sections,
    List<String> doneStates,
    List<String> allTags,
    List<String> allPropKeys,
    String? apiKey,
  ) async {
    if (kIsWeb) return;

    final file = await _localFile;
    final buffer = StringBuffer();

    // Save Config Header
    buffer.writeln('# CONFIG');
    buffer.writeln('STATES: ${states.join(',')}');
    final colorStrings = colors.entries
        .map((e) => '${e.key}:${e.value.toARGB32()}')
        .join(',');
    buffer.writeln('COLORS: $colorStrings');
    buffer.writeln('KANBAN: ${kanbanColumns.join(',')}');
    final sectionStrings = sections.map((s) => s.serialize()).join(';');
    buffer.writeln('SECTIONS: $sectionStrings');
    buffer.writeln('DONE_STATES: ${doneStates.join(',')}');
    buffer.writeln('ALL_TAGS: ${allTags.join(',')}');
    buffer.writeln('ALL_PROP_KEYS: ${allPropKeys.join(',')}');
    if (apiKey != null && apiKey.isNotEmpty) {
      buffer.writeln('API_KEY: $apiKey');
    }
    buffer.writeln();

    for (var node in nodes) {
      buffer.write(node.toMarkdown());
    }
    await file.writeAsString(buffer.toString());
    debugPrint('Saved tasks to ${file.path}');
  }

  Future<Map<String, dynamic>> loadData() async {
    if (kIsWeb)
      return {
        'nodes': <OrgNode>[],
        'states': null,
        'colors': null,
        'apiKey': null,
      };

    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return {
          'nodes': <OrgNode>[],
          'states': null,
          'colors': null,
          'apiKey': null,
        };
      }

      final content = await file.readAsString();
      return _parseMarkdownExtended(content);
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      return {
        'nodes': <OrgNode>[],
        'states': null,
        'colors': null,
        'apiKey': null,
      };
    }
  }

  Map<String, dynamic> _parseMarkdownExtended(String markdown) {
    List<OrgNode> nodes = [];
    List<String>? states;
    Map<String, Color>? colors;
    List<String>? kanban;
    List<AgendaSection>? sections;
    List<String>? doneStates;
    List<String>? allTags;
    List<String>? allPropKeys;
    String? apiKey;

    final lines = markdown.split('\n');

    // Check if it's a config block
    int startLine = 0;
    if (lines.isNotEmpty && lines[0].trim() == '# CONFIG') {
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) {
          startLine = i + 1;
          break;
        }
        if (line.startsWith('STATES:')) {
          states = line.replaceFirst('STATES:', '').trim().split(',');
        } else if (line.startsWith('COLORS:')) {
          final colorData = line.replaceFirst('COLORS:', '').trim().split(',');
          colors = {};
          for (var item in colorData) {
            final parts = item.split(':');
            if (parts.length == 2) {
              final colorVal = int.tryParse(parts[1]);
              if (colorVal != null) {
                colors[parts[0]] = Color(colorVal);
              }
            }
          }
        } else if (line.startsWith('KANBAN:')) {
          kanban = line.replaceFirst('KANBAN:', '').trim().split(',');
        } else if (line.startsWith('SECTIONS:')) {
          final sectData = line.replaceFirst('SECTIONS:', '').trim().split(';');
          sections = sectData
              .where((s) => s.isNotEmpty)
              .map((s) => AgendaSection.deserialize(s))
              .toList();
        } else if (line.startsWith('DONE_STATES:')) {
          doneStates = line.replaceFirst('DONE_STATES:', '').trim().split(',');
        } else if (line.startsWith('ALL_TAGS:')) {
          allTags = line.replaceFirst('ALL_TAGS:', '').trim().split(',');
        } else if (line.startsWith('ALL_PROP_KEYS:')) {
          allPropKeys = line
              .replaceFirst('ALL_PROP_KEYS:', '')
              .trim()
              .split(',');
        } else if (line.startsWith('API_KEY:')) {
          apiKey = line.replaceFirst('API_KEY:', '').trim();
        }
      }
    }

    nodes = parseMarkdown(lines.sublist(startLine).join('\n'));
    return {
      'nodes': nodes,
      'states': states,
      'colors': colors,
      'kanban': kanban,
      'sections': sections,
      'doneStates': doneStates,
      'allTags': allTags,
      'allPropKeys': allPropKeys,
      'apiKey': apiKey,
    };
  }

  // A more robust parser for the specific format we generated
  List<OrgNode> parseMarkdown(String markdown) {
    List<OrgNode> rootNodes = [];
    List<OrgNode> stack = [];

    final lines = markdown.split('\n');
    OrgNode? currentNode;

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Handle Headers (Tasks)
      if (trimmed.startsWith('#')) {
        final match = RegExp(
          r'^(#+)\s+(\w+)\s+(.*?)(?:\s+:(.*):)?$',
        ).firstMatch(trimmed);
        if (match != null) {
          final depth = match.group(1)!.length;
          final state = match.group(2)!;
          var taskContent = match.group(3)!;
          final tagsText = match.group(4);

          final newNode = OrgNode(content: taskContent, todoState: state);
          if (tagsText != null && tagsText.isNotEmpty) {
            newNode.tags = tagsText
                .split(':')
                .where((t) => t.isNotEmpty)
                .toList();
          }

          if (depth == 1) {
            rootNodes.add(newNode);
            stack = [newNode];
          } else {
            // Find parent in stack
            if (depth <= stack.length) {
              stack = stack.sublist(0, depth - 1);
            }
            if (stack.isNotEmpty) {
              stack.last.children.add(newNode);
            }
            stack.add(newNode);
          }
          currentNode = newNode;
        }
      } else if (currentNode != null) {
        // Handle Metadata
        if (trimmed.startsWith('SCHEDULED:')) {
          currentNode.scheduled = _safeParseDate(
            trimmed.replaceFirst('SCHEDULED:', '').trim(),
          );
        } else if (trimmed.startsWith('DEADLINE:')) {
          currentNode.deadline = _safeParseDate(
            trimmed.replaceFirst('DEADLINE:', '').trim(),
          );
        } else if (trimmed.startsWith('CLOSED:')) {
          final match = RegExp(r'\[(.*?)\]').firstMatch(trimmed);
          if (match != null) {
            currentNode.closedAt = _safeParseDateTime(match.group(1)!);
          }
        } else if (trimmed.startsWith('DESC:')) {
          currentNode.description = trimmed.replaceFirst('DESC:', '').trim();
        } else if (trimmed.startsWith(':') && trimmed.endsWith(':')) {
          // Entry into or exit from properties
        } else if (trimmed.startsWith(':')) {
          if (trimmed == ':PROPERTIES:' || trimmed == ':END:') {
            // Header/Footer of properties block
          } else {
            // Property: :KEY: VALUE
            final firstColon = trimmed.indexOf(':');
            final secondColon = trimmed.indexOf(':', firstColon + 1);
            if (firstColon == 0 && secondColon > 0) {
              final key = trimmed.substring(1, secondColon).trim();
              final value = trimmed.substring(secondColon + 1).trim();
              currentNode.properties[key] = value;
            }
          }
        } else if (trimmed.startsWith('CLOCK:')) {
          // CLOCK: [2025-12-17 10:00]--[2025-12-17 10:05]
          final clockMatch = RegExp(
            r'\[(.*?)\]--\[(.*?)\]',
          ).firstMatch(trimmed);
          if (clockMatch != null) {
            final start = _safeParseDateTime(clockMatch.group(1)!);
            final end = _safeParseDateTime(clockMatch.group(2)!);
            if (start != null) {
              currentNode.clockLogs.add(TimeLog(start: start, end: end));
            }
          }
        } else if (trimmed.startsWith('- Log:')) {
          // - Log: 2025-12-17 10:00 | Message
          final logMatch = RegExp(
            r'Log:\s+(.*?)\s+\|\s+(.*)$',
          ).firstMatch(trimmed);
          if (logMatch != null) {
            final ts = _safeParseDateTime(logMatch.group(1)!);
            if (ts != null) {
              currentNode.history.add(
                LogEntry(timestamp: ts, message: logMatch.group(2)!),
              );
            }
          }
        }
      }
    }
    return rootNodes;
  }

  DateTime? _safeParseDate(String str) {
    try {
      return DateFormat('yyyy-MM-dd').parse(str);
    } catch (_) {
      return null;
    }
  }

  DateTime? _safeParseDateTime(String str) {
    try {
      return DateFormat('yyyy-MM-dd HH:mm').parse(str);
    } catch (_) {
      return null;
    }
  }
}
