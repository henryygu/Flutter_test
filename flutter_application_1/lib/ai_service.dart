import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'org_node.dart';

class AIService {
  final String apiKey;
  late final GenerativeModel _model;

  AIService(this.apiKey) {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  Future<List<OrgNode>> generateTasks(String prompt) async {
    final structurePrompt =
        '''
You are a task management assistant.
User request: "$prompt"

Create a list of tasks based on this request.
Return the result as a JSON array of objects.
Each object should have:
- "content" (string): The task title.
- "description" (string, optional): A detailed description.
- "todoState" (string): Use "TODO" by default.
- "children" (array, optional): A list of subtasks with the same structure.

Example JSON output:
[
  {
    "content": "Plan Party",
    "description": "Birthday party for John",
    "todoState": "TODO",
    "children": [
      { "content": "Buy Cake", "todoState": "TODO" }
    ]
  }
]

Return strictly valid JSON. Do not include markdown formatting (like ```json ... ```).
''';

    final content = [Content.text(structurePrompt)];
    final response = await _model.generateContent(content);
    final responseText = response.text;

    if (responseText == null) {
      throw Exception('No response from AI');
    }

    // Clean up markdown if present
    String cleanedJson = responseText.trim();
    if (cleanedJson.startsWith('```json')) {
      cleanedJson = cleanedJson.substring(7);
    }
    if (cleanedJson.startsWith('```')) {
      cleanedJson = cleanedJson.substring(3);
    }
    if (cleanedJson.endsWith('```')) {
      cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
    }

    try {
      final List<dynamic> jsonList = jsonDecode(cleanedJson);
      return jsonList.map((e) => _parseNode(e)).toList();
    } catch (e) {
      throw Exception('Failed to parse AI response: $e');
    }
  }

  OrgNode _parseNode(Map<String, dynamic> json) {
    final node = OrgNode(
      content: json['content'] ?? 'Untitled Task',
      description: json['description'] ?? '',
      todoState: json['todoState'] ?? 'TODO',
    );

    if (json['children'] != null) {
      for (var child in json['children']) {
        node.children.add(_parseNode(child));
      }
    }
    return node;
  }
}
