import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'node_manager.dart';
import 'property_models.dart';
import 'glass_card.dart';
import 'dart:ui';

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
  late List<PropertyDefinition> _localPropDefs;

  final TextEditingController _newStateController = TextEditingController();
  final TextEditingController _newTagController = TextEditingController();
  final TextEditingController _newPropKeyController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localStates = List.from(widget.manager.todoStates);
    _localColors = Map.from(widget.manager.stateColors);
    _localDoneStates = Set.from(widget.manager.doneStates);
    _localTags = List.from(widget.manager.allTags);
    _localPropDefs = List.from(widget.manager.propertyDefinitions);
    _apiKeyController.text = widget.manager.apiKey ?? '';
  }

  @override
  void dispose() {
    _newStateController.dispose();
    _newTagController.dispose();
    _newPropKeyController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _save() {
    widget.manager.setTodoStates(_localStates, _localColors);
    widget.manager.setDoneStates(_localDoneStates);
    widget.manager.setAllTags(_localTags);
    widget.manager.setAllPropertyKeys(_localPropDefs);
    widget.manager.setApiKey(_apiKeyController.text.trim());
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(
                context,
              ).colorScheme.surface.withBlue(60).withOpacity(0.9),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Workflow States', Icons.sync_alt),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(8),
                blur: 20,
                opacity: 0.08,
                child: SizedBox(
                  height: 300,
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
                        Padding(
                          key: ValueKey(_localStates[i] + i.toString()),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            blur: 5,
                            opacity: 0.05,
                            child: ListTile(
                              leading: GestureDetector(
                                onTap: () => _pickColor(_localStates[i]),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color:
                                        _localColors[_localStates[i]] ??
                                        Colors.grey,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (_localColors[_localStates[i]] ??
                                                    Colors.grey)
                                                .withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.palette,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              title: Text(
                                _localStates[i],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
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
                                            _localDoneStates.add(
                                              _localStates[i],
                                            );
                                          } else {
                                            _localDoneStates.remove(
                                              _localStates[i],
                                            );
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const Text(
                                    'Done State',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.drag_handle,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newStateController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add new state...',
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      final val = _newStateController.text.toUpperCase().trim();
                      if (val.isNotEmpty && !_localStates.contains(val)) {
                        setState(() {
                          _localStates.add(val);
                          _localColors[val] = Colors.blue;
                          _newStateController.clear();
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('Global Tags', Icons.local_offer_outlined),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._localTags.map(
                      (tag) => Chip(
                        label: Text(
                          '#$tag',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onDeleted: () {
                          setState(() => _localTags.remove(tag));
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide.none,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Add Tag',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _showAddTagDialog(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionHeader(
                'Property Definitions',
                Icons.list_alt_outlined,
              ),
              const SizedBox(height: 16),
              ..._localPropDefs.map((def) => _buildPropDefItem(def)),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => _showAddPropDefDialog(),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Definition'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('AI Settings', Icons.smart_toy_outlined),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'Enter your API Key',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Data Management', Icons.storage_outlined),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text(
                        'Export Markdown',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Copy all tasks to clipboard'),
                      trailing: const Icon(Icons.content_copy_outlined),
                      onTap: () async {
                        final buffer = StringBuffer();
                        for (var node in widget.manager.rootNodes) {
                          buffer.write(node.toMarkdown());
                        }
                        await Clipboard.setData(
                          ClipboardData(text: buffer.toString()),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!')),
                        );
                      },
                    ),
                    const Divider(indent: 16, endIndent: 16, height: 1),
                    ListTile(
                      title: const Text(
                        'Import Markdown File',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Select a .md or .txt file'),
                      trailing: const Icon(Icons.file_upload_outlined),
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['md', 'txt'],
                        );

                        if (result != null &&
                            result.files.single.path != null) {
                          final file = File(result.files.single.path!);
                          final content = await file.readAsString();
                          widget.manager.importFromMarkdown(content);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Imported successfully!'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropDefItem(PropertyDefinition def) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        blur: 10,
        opacity: 0.05,
        child: ListTile(
          title: Text(
            def.key,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            'Type: ${def.type.name.toUpperCase()}${def.options.isNotEmpty ? " (${def.options.join(', ')})" : ""}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _localPropDefs.remove(def);
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  void _showAddTagDialog() {
    _newTagController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Global Tag'),
        content: TextField(controller: _newTagController, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = _newTagController.text.trim();
              if (val.isNotEmpty) {
                setState(() => _localTags.add(val));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddPropDefDialog() {
    _newPropKeyController.clear();
    PropertyType selectedType = PropertyType.text;
    List<String> options = [];
    final optController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Property Definition'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newPropKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Property Key (e.g. COST)',
                  ),
                ),
                DropdownButtonFormField<PropertyType>(
                  value: selectedType,
                  items: PropertyType.values
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t.name)),
                      )
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                if (selectedType == PropertyType.options) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: optController,
                          decoration: const InputDecoration(
                            labelText: 'New Option',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (optController.text.isNotEmpty) {
                            setDialogState(() {
                              options.add(optController.text.trim());
                              optController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 4,
                    children: options
                        .map(
                          (o) => Chip(
                            label: Text(o),
                            onDeleted: () =>
                                setDialogState(() => options.remove(o)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final key = _newPropKeyController.text.toUpperCase().trim();
                if (key.isNotEmpty) {
                  setState(() {
                    _localPropDefs.add(
                      PropertyDefinition(
                        key: key,
                        type: selectedType,
                        options: options,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
