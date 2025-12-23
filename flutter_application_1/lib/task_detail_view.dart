import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'org_node.dart';
import 'node_manager.dart';
import 'org_node_widget.dart';
import 'property_models.dart';
import 'glass_card.dart';

class TaskDetailView extends StatefulWidget {
  final OrgNode node;
  final NodeManager manager;

  const TaskDetailView({super.key, required this.node, required this.manager});

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _propKeyController = TextEditingController();
  final TextEditingController _propValController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descController.text = widget.node.description;
  }

  @override
  void dispose() {
    _descController.dispose();
    _commentController.dispose();
    _propKeyController.dispose();
    _propValController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Focus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context),
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
              ).colorScheme.surface.withBlue(50).withOpacity(0.9),
            ],
          ),
        ),
        child: ListenableBuilder(
          listenable: widget.manager,
          builder: (context, _) {
            final color = widget.manager.getColorForState(
              widget.node.todoState,
            );

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // Focused Header
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  blur: 30,
                  opacity: 0.12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _showStatePicker(context),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            widget.node.todoState,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.node.content.isEmpty
                            ? 'Untitled Task'
                            : widget.node.content,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.2,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Metadata Row
                _buildMetadataSection(context),

                const Divider(height: 48),

                // Description Section
                _buildModernSection(
                  context,
                  title: 'DESCRIPTION',
                  icon: Icons.description_outlined,
                  child: TextField(
                    controller: _descController,
                    maxLines: null,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Add a detailed description...',
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainer.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) =>
                        widget.manager.updateNodeDescription(widget.node, val),
                  ),
                ),

                const SizedBox(height: 24),

                // Tags Section
                _buildModernSection(
                  context,
                  title: 'TAGS',
                  icon: Icons.local_offer_outlined,
                  child: _buildTagsWrap(context),
                ),

                const SizedBox(height: 24),

                // Properties Section
                _buildModernSection(
                  context,
                  title: 'PROPERTIES',
                  icon: Icons.settings_outlined,
                  action: IconButton(
                    onPressed: () => _showAddPropertyDialog(context),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                  ),
                  child: _buildPropertiesWrap(context),
                ),

                const SizedBox(height: 24),

                // Sub-tasks Section
                _buildSectionTitle('SUB-TASKS', Icons.account_tree_outlined),
                const SizedBox(height: 12),
                if (widget.node.children.isEmpty)
                  const Text(
                    'No sub-tasks nested here.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  )
                else
                  ...widget.node.children.map(
                    (child) => OrgNodeWidget(
                      node: child,
                      manager: widget.manager,
                      depth: 0,
                    ),
                  ),

                const Divider(height: 48),

                // Comments Section
                _buildSectionTitle('COMMENTS & LOGS', Icons.forum_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: () {
                        if (_commentController.text.isNotEmpty) {
                          widget.manager.addManualLog(
                            widget.node,
                            _commentController.text,
                          );
                          _commentController.clear();
                        }
                      },
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Log Entries
                if (widget.node.history.isEmpty)
                  const Center(
                    child: Text(
                      'No activity yet',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ...widget.node.history.reversed.map(
                    (entry) => _buildLogEntry(context, entry),
                  ),

                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.manager.addChild(widget.node, ''),
        icon: const Icon(Icons.add),
        label: const Text('Add Sub-task'),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetadataItem(
          label: 'Created',
          value: DateFormat('MMM dd, yyyy').format(widget.node.created),
          icon: Icons.calendar_today,
        ),
        _MetadataItem(
          label: 'Scheduled',
          value: widget.node.scheduled == null
              ? 'Set Date'
              : DateFormat('MMM dd HH:mm').format(widget.node.scheduled!),
          icon: Icons.event,
          color: widget.node.scheduled != null ? Colors.green : Colors.grey,
          onTap: () => _pickDate(context, isDeadline: false),
        ),
        _MetadataItem(
          label: 'Deadline',
          value: widget.node.deadline == null
              ? 'Set Date'
              : DateFormat('MMM dd HH:mm').format(widget.node.deadline!),
          icon: Icons.notification_important,
          color: widget.node.deadline != null ? Colors.red : Colors.grey,
          onTap: () => _pickDate(context, isDeadline: true),
        ),
        _MetadataItem(
          label: 'Total Time',
          value: _formatDuration(widget.node.totalTimeSpent),
          icon: Icons.timer_outlined,
          color: Colors.blueGrey,
        ),
      ],
    );
  }

  Widget _buildPropertyChip(BuildContext context, String key, String value) {
    final def = widget.manager.propertyDefinitions.firstWhere(
      (d) => d.key == key,
      orElse: () => PropertyDefinition(key: key),
    );
    return InkWell(
      onTap: () => _editPropertyValue(context, def, value),
      child: Chip(
        label: Text('$key: $value', style: const TextStyle(fontSize: 12)),
        onDeleted: () => widget.manager.removeProperty(widget.node, key),
        deleteIcon: const Icon(Icons.close, size: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _editPropertyValue(
    BuildContext context,
    PropertyDefinition def,
    String currentValue,
  ) {
    _propValController.text = currentValue;
    showDialog(
      context: context,
      builder: (context) => _buildValueInputDialog(context, def, (newVal) {
        widget.manager.setProperty(widget.node, def.key, newVal);
      }),
    );
  }

  void _showAddPropertyDialog(BuildContext context) {
    _propKeyController.clear();
    _propValController.clear();
    showDialog(
      context: context,
      builder: (context) {
        final availableDefs = widget.manager.propertyDefinitions;
        PropertyDefinition? selectedDef;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Property'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _propKeyController,
                  decoration: const InputDecoration(
                    hintText: 'Key (e.g. COST)',
                  ),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedDef = availableDefs.firstWhere(
                        (d) => d.key == val.toUpperCase().trim(),
                        orElse: () =>
                            PropertyDefinition(key: val.toUpperCase().trim()),
                      );
                    });
                  },
                ),
                if (availableDefs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Known Definitions:',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: availableDefs
                        .map(
                          (def) => ChoiceChip(
                            label: Text(
                              def.key,
                              style: const TextStyle(fontSize: 10),
                            ),
                            selected: selectedDef?.key == def.key,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  selectedDef = def;
                                  _propKeyController.text = def.key;
                                });
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                if (selectedDef != null)
                  _buildValueInput(
                    context,
                    selectedDef!,
                    (val) => _propValController.text = val,
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final key = _propKeyController.text.trim().toUpperCase();
                  if (key.isNotEmpty) {
                    widget.manager.setProperty(
                      widget.node,
                      key,
                      _propValController.text.trim(),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildValueInput(
    BuildContext context,
    PropertyDefinition def,
    Function(String) onChanged,
  ) {
    switch (def.type) {
      case PropertyType.boolean:
        return StatefulBuilder(
          builder: (context, setInnerState) => SwitchListTile(
            title: const Text('Value', style: TextStyle(fontSize: 14)),
            value: _propValController.text.toLowerCase() == 'true',
            onChanged: (val) {
              setInnerState(() => _propValController.text = val.toString());
              onChanged(val.toString());
            },
          ),
        );
      case PropertyType.number:
        return TextField(
          decoration: const InputDecoration(labelText: 'Number Value'),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: onChanged,
        );
      case PropertyType.options:
        return DropdownButtonFormField<String>(
          items: def.options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              _propValController.text = val;
              onChanged(val);
            }
          },
          decoration: const InputDecoration(labelText: 'Select Option'),
        );
      case PropertyType.text:
        return TextField(
          decoration: const InputDecoration(labelText: 'Text Value'),
          onChanged: onChanged,
        );
    }
  }

  Widget _buildValueInputDialog(
    BuildContext context,
    PropertyDefinition def,
    Function(String) onSave,
  ) {
    String localVal = _propValController.text;
    return AlertDialog(
      title: Text('Edit ${def.key}'),
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (def.type == PropertyType.boolean)
              SwitchListTile(
                title: const Text('Value'),
                value: localVal.toLowerCase() == 'true',
                onChanged: (val) =>
                    setDialogState(() => localVal = val.toString()),
              )
            else if (def.type == PropertyType.number)
              TextField(
                controller: TextEditingController(text: localVal),
                decoration: const InputDecoration(labelText: 'Number'),
                keyboardType: TextInputType.number,
                onChanged: (val) => localVal = val,
              )
            else if (def.type == PropertyType.options)
              DropdownButtonFormField<String>(
                initialValue: def.options.contains(localVal) ? localVal : null,
                items: def.options
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (val) => setDialogState(() => localVal = val!),
              )
            else
              TextField(
                controller: TextEditingController(text: localVal),
                decoration: const InputDecoration(labelText: 'Value'),
                onChanged: (val) => localVal = val,
              ),
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
            onSave(localVal);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _showAddTagDialog(BuildContext context) {
    _tagController.clear();
    showDialog(
      context: context,
      builder: (context) {
        final availableTags = widget.manager.allTags;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Tag'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(hintText: 'Tag name'),
                  autofocus: true,
                  onSubmitted: (val) {
                    widget.manager.addTag(widget.node, val.trim());
                    Navigator.pop(context);
                  },
                ),
                if (availableTags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Recently used:',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: availableTags
                        .map(
                          (tag) => ActionChip(
                            label: Text(
                              '#$tag',
                              style: const TextStyle(fontSize: 10),
                            ),
                            onPressed: () {
                              widget.manager.addTag(widget.node, tag);
                              Navigator.pop(context);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.manager.addTag(
                    widget.node,
                    _tagController.text.trim(),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogEntry(BuildContext context, LogEntry entry) {
    final isManual = entry.message.startsWith('Manual:');
    final message = isManual
        ? entry.message.replaceFirst('Manual:', '').trim()
        : entry.message;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isManual
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isManual
              ? Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text(
                  DateFormat('HH:mm').format(entry.timestamp),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.blueGrey,
                  ),
                ),
                Text(
                  DateFormat('MMM dd').format(entry.timestamp),
                  style: const TextStyle(fontSize: 8, color: Colors.blueGrey),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isManual ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  void _showStatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Change Status',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.manager.todoStates.map((state) {
                  final color = widget.manager.getColorForState(state);
                  final isSelected = widget.node.todoState == state;
                  return InkWell(
                    onTap: () {
                      widget.manager.setNodeState(widget.node, state);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        state,
                        style: TextStyle(
                          color: isSelected ? Colors.white : color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickDate(BuildContext context, {required bool isDeadline}) async {
    final initial =
        (isDeadline ? widget.node.deadline : widget.node.scheduled) ??
        DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      final finalDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? initial.hour,
        pickedTime?.minute ?? initial.minute,
      );
      if (isDeadline) {
        widget.manager.setDeadline(widget.node, finalDateTime);
      } else {
        widget.manager.setScheduled(widget.node, finalDateTime);
      }
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
    return "${d.inMinutes}m ${d.inSeconds.remainder(60)}s";
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text(
          'This will permanently remove this task and all its sub-tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              widget.manager.deleteNode(widget.node);
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to list
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            if (action != null) action,
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          blur: 15,
          opacity: 0.05,
          child: child,
        ),
      ],
    );
  }

  Widget _buildTagsWrap(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...widget.node.tags.map(
          (tag) => Chip(
            label: Text(
              '#$tag',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onDeleted: () => widget.manager.removeTag(widget.node, tag),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        ActionChip(
          label: const Text('Add Tag', style: TextStyle(fontSize: 12)),
          onPressed: () => _showAddTagDialog(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertiesWrap(BuildContext context) {
    if (widget.node.properties.isEmpty) {
      return Text(
        'No custom properties set.',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).disabledColor,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.node.properties.entries
          .map((e) => _buildPropertyChip(context, e.key, e.value))
          .toList(),
    );
  }
}

class _MetadataItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const _MetadataItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: BorderRadius.circular(20),
        blur: 10,
        opacity: 0.06,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
