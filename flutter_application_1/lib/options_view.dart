import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'node_manager.dart';

class OptionsView extends StatefulWidget {
  final NodeManager manager;

  const OptionsView({super.key, required this.manager});

  @override
  State<OptionsView> createState() => _OptionsViewState();
}

class _OptionsViewState extends State<OptionsView> {
  late List<String> _localStates;
  late Map<String, Color> _localColors;
  late Set<String> _localDoneStates;
  late List<String> _localTags;
  late List<String> _localPropKeys;
  final TextEditingController _newStateController = TextEditingController();
  final TextEditingController _newTagController = TextEditingController();
  final TextEditingController _newPropKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localStates = List.from(widget.manager.todoStates);
    _localColors = Map.from(widget.manager.stateColors);
    _localDoneStates = Set.from(widget.manager.doneStates);
    _localTags = List.from(widget.manager.allTags);
    _localPropKeys = List.from(widget.manager.allPropertyKeys);
  }

  @override
  void dispose() {
    _newStateController.dispose();
    _newTagController.dispose();
    _newPropKeyController.dispose();
    super.dispose();
  }

  void _save() {
    widget.manager.setTodoStates(_localStates, _localColors);
    widget.manager.setDoneStates(_localDoneStates);
    widget.manager.setAllTags(_localTags);
    widget.manager.setAllPropertyKeys(_localPropKeys);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences saved successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _pickColor(String state) {
    Color pickerColor = _localColors[state] ?? Colors.blue;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Symbol Color: $state'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              setState(() {
                _localColors[state] = color;
              });
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Apply'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Workflow States', Icons.sync_alt),
            const SizedBox(height: 8),
            const Text(
              'Define the lifecycle of your tasks. Drag to reorder, or tap the circle to change the signature color.',
              style: TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),
            const SizedBox(height: 24),
            Container(
              height: 350,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ReorderableListView(
                padding: const EdgeInsets.all(8),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _localStates.removeAt(oldIndex);
                    _localStates.insert(newIndex, item);
                  });
                },
                children: [
                  for (int i = 0; i < _localStates.length; i++)
                    Card(
                      key: ValueKey(_localStates[i] + i.toString()),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () => _pickColor(_localStates[i]),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  _localColors[_localStates[i]] ?? Colors.grey,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (_localColors[_localStates[i]] ??
                                              Colors.grey)
                                          .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.palette,
                              size: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        title: Text(
                          _localStates[i],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        subtitle: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _localDoneStates.contains(
                                  _localStates[i],
                                ),
                                visualDensity: VisualDensity.compact,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _localDoneStates.add(_localStates[i]);
                                    } else {
                                      _localDoneStates.remove(_localStates[i]);
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Done Category',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.drag_handle,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('Add State', Icons.add),
            const SizedBox(height: 8),
            TextField(
              controller: _newStateController,
              decoration: InputDecoration(
                hintText: 'e.g., DEFERRED',
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () {
                    if (_newStateController.text.isNotEmpty) {
                      final name = _newStateController.text.toUpperCase();
                      setState(() {
                        if (!_localStates.contains(name)) {
                          _localStates.add(name);
                          _localColors[name] = Colors.blue;
                        }
                        _newStateController.clear();
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Tag Management
            _buildSectionHeader('Global Tags', Icons.local_offer),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._localTags.map(
                  (tag) => Chip(
                    label: Text('#$tag'),
                    onDeleted: () {
                      setState(() => _localTags.remove(tag));
                    },
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('Add Tag'),
                  onPressed: () => _showAddDialog(
                    'Add Global Tag',
                    _newTagController,
                    (val) {
                      if (!_localTags.contains(val)) _localTags.add(val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Property Key Management
            _buildSectionHeader('Property Keys', Icons.list_alt),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._localPropKeys.map(
                  (key) => Chip(
                    label: Text(key),
                    onDeleted: () {
                      setState(() => _localPropKeys.remove(key));
                    },
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('Add Key'),
                  onPressed: () => _showAddDialog(
                    'Add Meta Key',
                    _newPropKeyController,
                    (val) {
                      val = val.toUpperCase();
                      if (!_localPropKeys.contains(val))
                        _localPropKeys.add(val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('Data & Storage', Icons.storage),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Export to Markdown'),
                    subtitle: const Text('Copy all tasks to clipboard'),
                    trailing: const Icon(Icons.copy),
                    onTap: () async {
                      final buffer = StringBuffer();
                      for (var node in widget.manager.rootNodes) {
                        buffer.write(node.toMarkdown());
                      }
                      await Clipboard.setData(
                        ClipboardData(text: buffer.toString()),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Markdown copied!')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Local Storage Path'),
                    subtitle: const Text(
                      kIsWeb ? 'Web Browser' : 'Documents/tasks.md',
                    ),
                    leading: const Icon(Icons.info_outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  void _showAddDialog(
    String title,
    TextEditingController controller,
    Function(String) onAdd,
  ) {
    controller.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (val) {
            setState(() => onAdd(val.trim()));
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => onAdd(controller.text.trim()));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
