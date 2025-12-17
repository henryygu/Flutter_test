enum PropertyType { text, number, boolean, options }

class PropertyDefinition {
  final String key;
  final PropertyType type;
  final List<String> options;

  PropertyDefinition({
    required this.key,
    this.type = PropertyType.text,
    this.options = const [],
  });

  String serialize() {
    final opts = options.isEmpty ? '' : ':${options.join('|')}';
    return '$key:${type.name}$opts';
  }

  static PropertyDefinition deserialize(String str) {
    final parts = str.split(':');
    if (parts.length < 2) return PropertyDefinition(key: parts[0]);

    final key = parts[0];
    final type = PropertyType.values.firstWhere(
      (e) => e.name == parts[1],
      orElse: () => PropertyType.text,
    );

    List<String> options = [];
    if (parts.length >= 3 && parts[2].isNotEmpty) {
      options = parts[2].split('|');
    }

    return PropertyDefinition(key: key, type: type, options: options);
  }
}
