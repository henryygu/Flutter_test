class AgendaSection {
  String id;
  String title;

  // Date range relative to today (e.g., -1 for yesterday, 0 for today, 1 for tomorrow)
  int startOffset;
  int endOffset;

  bool useScheduled;
  bool useDeadline;

  Set<String> tags;
  Set<String> states;

  AgendaSection({
    required this.id,
    required this.title,
    this.startOffset = 0,
    this.endOffset = 0,
    this.useScheduled = true,
    this.useDeadline = true,
    this.tags = const {},
    this.states = const {},
  });

  String serialize() {
    return '$id|$title|$startOffset|$endOffset|${useScheduled ? 1 : 0}|${useDeadline ? 1 : 0}|${tags.join(',')}|${states.join(',')}';
  }

  static AgendaSection deserialize(String data) {
    final parts = data.split('|');
    if (parts.isEmpty || parts[0].isEmpty) {
      return AgendaSection(id: 'unknown', title: 'New Section');
    }
    if (parts.length < 8) {
      // Compatibility for older format versions
      return AgendaSection(
        id: parts[0],
        title: parts.length > 1 ? parts[1] : 'Section',
      );
    }
    return AgendaSection(
      id: parts[0],
      title: parts[1],
      startOffset: int.tryParse(parts[2]) ?? 0,
      endOffset: int.tryParse(parts[3]) ?? 0,
      useScheduled: parts[4] == '1',
      useDeadline: parts[5] == '1',
      tags: parts[6].isEmpty ? {} : parts[6].split(',').toSet(),
      states: parts[7].isEmpty ? {} : parts[7].split(',').toSet(),
    );
  }
}
