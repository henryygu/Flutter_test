import 'package:flutter/material.dart';
import 'org_node.dart';
import 'node_manager.dart';
import 'org_node_widget.dart';

class AgendaView extends StatelessWidget {
  final NodeManager manager;

  const AgendaView({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    final filter = manager.agendaFilter;
    final allNodes = _collectAllNodes(manager.rootNodes);
    final now = DateTime.now();

    final filteredTasks = allNodes.where((n) {
      // 1. Check Date Range
      bool dateMatch = false;
      final targetDate = n.deadline ?? n.scheduled;

      if (filter.timeRange == AgendaTimeRange.all) {
        dateMatch = true;
      } else if (targetDate == null) {
        dateMatch = false;
      } else {
        switch (filter.timeRange) {
          case AgendaTimeRange.day:
            dateMatch = isSameDay(targetDate, now);
            break;
          case AgendaTimeRange.week:
            final nextWeek = now.add(const Duration(days: 7));
            dateMatch =
                targetDate.isAfter(now.subtract(const Duration(days: 1))) &&
                targetDate.isBefore(nextWeek);
            break;
          case AgendaTimeRange.month:
            dateMatch =
                targetDate.month == now.month && targetDate.year == now.year;
            break;
          case AgendaTimeRange.all:
            dateMatch = true;
            break;
        }
      }

      // 2. Check Tags
      bool tagMatch =
          filter.includedTags.isEmpty ||
          n.tags.any((t) => filter.includedTags.contains(t));

      // 3. Check States
      bool stateMatch =
          filter.includedStates.isEmpty ||
          filter.includedStates.contains(n.todoState);

      return dateMatch && tagMatch && stateMatch;
    }).toList();

    // Sort: Deadlines first, then Scheduled
    filteredTasks.sort((a, b) {
      final da = a.deadline ?? a.scheduled;
      final db = b.deadline ?? b.scheduled;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeader(
                _getFilterLabel(filter.timeRange),
                Icons.calendar_today,
              ),
              IconButton.filledTonal(
                onPressed: () => _showFilterSettings(context),
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filteredTasks.isEmpty)
            _buildEmptyState('No tasks matching your filters.')
          else
            ...filteredTasks.map(
              (n) => OrgNodeWidget(
                node: n,
                manager: manager,
                showChildren: false,
                showIndentation: false,
              ),
            ),
        ],
      ),
    );
  }

  String _getFilterLabel(AgendaTimeRange range) {
    switch (range) {
      case AgendaTimeRange.day:
        return 'Today';
      case AgendaTimeRange.week:
        return 'This Week';
      case AgendaTimeRange.month:
        return 'This Month';
      case AgendaTimeRange.all:
        return 'All Tasks';
    }
  }

  void _showFilterSettings(BuildContext context) {
    final allTags = _collectAllNodes(
      manager.rootNodes,
    ).expand((n) => n.tags).toSet().toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filter = manager.agendaFilter;
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agenda Filters',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                const Text(
                  'TIME RANGE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: AgendaTimeRange.values.map((range) {
                    final selected = filter.timeRange == range;
                    return ChoiceChip(
                      label: Text(_getFilterLabel(range)),
                      selected: selected,
                      onSelected: (val) {
                        if (val) {
                          filter.timeRange = range;
                          manager.setAgendaFilter(filter);
                          setModalState(() {});
                        }
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                const Text(
                  'TAGS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                if (allTags.isEmpty)
                  const Text(
                    'No tags found',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: allTags.map((tag) {
                      final selected = filter.includedTags.contains(tag);
                      return FilterChip(
                        label: Text('#$tag'),
                        selected: selected,
                        onSelected: (val) {
                          val
                              ? filter.includedTags.add(tag)
                              : filter.includedTags.remove(tag);
                          manager.setAgendaFilter(filter);
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 24),
                const Text(
                  'STATES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: manager.todoStates.map((state) {
                    final selected = filter.includedStates.contains(state);
                    return FilterChip(
                      label: Text(state),
                      selected: selected,
                      onSelected: (val) {
                        val
                            ? filter.includedStates.add(state)
                            : filter.includedStates.remove(state);
                        manager.setAgendaFilter(filter);
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.blueGrey,
          ),
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<OrgNode> _collectAllNodes(List<OrgNode> nodes) {
    final List<OrgNode> result = [];
    for (var node in nodes) {
      result.add(node);
      result.addAll(_collectAllNodes(node.children));
    }
    return result;
  }
}
