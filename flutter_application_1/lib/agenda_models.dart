enum DateFilter { overdue, today, week, month, none }

class AgendaSection {
  String id;
  String title;
  DateFilter dateFilter;
  Set<String> tags;
  Set<String> states;

  AgendaSection({
    required this.id,
    required this.title,
    this.dateFilter = DateFilter.none,
    this.tags = const {},
    this.states = const {},
  });

  String serialize() {
    return '$id|$title|${dateFilter.name}|${tags.join(',')}|${states.join(',')}';
  }

  static AgendaSection deserialize(String data) {
    final parts = data.split('|');
    if (parts.length < 5) {
      return AgendaSection(id: 'err', title: 'Error Decoding');
    }
    return AgendaSection(
      id: parts[0],
      title: parts[1],
      dateFilter: DateFilter.values.firstWhere(
        (e) => e.name == parts[2],
        orElse: () => DateFilter.none,
      ),
      tags: parts[3].isEmpty ? {} : parts[3].split(',').toSet(),
      states: parts[4].isEmpty ? {} : parts[4].split(',').toSet(),
    );
  }
}
