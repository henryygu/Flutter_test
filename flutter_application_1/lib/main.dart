import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import 'node_manager.dart';
import 'org_node_widget.dart';
import 'agenda_view.dart';
import 'timeline_view.dart';
import 'options_view.dart';
import 'kanban_view.dart';
import 'glass_card.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrgApp());
}

class OrgApp extends StatelessWidget {
  const OrgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NodeManager(),
      child: Consumer<NodeManager>(
        builder: (context, manager, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'OrgFlow',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1),
                brightness: Brightness.light,
                surface: const Color(0xFFF1F5F9),
                primary: const Color(0xFF4F46E5),
              ),
              textTheme: GoogleFonts.outfitTextTheme(
                ThemeData.light().textTheme
                    .apply(
                      bodyColor: const Color(0xFF0F172A),
                      displayColor: const Color(0xFF0F172A),
                    )
                    .copyWith(
                      bodyLarge: const TextStyle(
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                      bodyMedium: const TextStyle(
                        fontSize: 16,
                        letterSpacing: -0.1,
                      ),
                      titleLarge: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: Colors.black.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                color: Colors.white,
              ),
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: const Color(0xFFF1F5F9),
                indicatorColor: const Color(0xFF6366F1).withOpacity(0.12),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(
                      color: Color(0xFF4F46E5),
                      size: 28,
                    );
                  }
                  return IconThemeData(
                    color: const Color(0xFF4F46E5).withOpacity(0.4),
                  );
                }),
                labelTextStyle: WidgetStateProperty.all(
                  const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1),
                brightness: Brightness.dark,
                surface: const Color(0xFF020617),
                surfaceContainer: const Color(0xFF0F172A),
                primary: const Color(0xFF818CF8),
              ),
              textTheme: GoogleFonts.outfitTextTheme(
                ThemeData.dark().textTheme
                    .apply(
                      bodyColor: const Color(0xFFF1F5F9),
                      displayColor: const Color(0xFFF1F5F9),
                    )
                    .copyWith(
                      bodyLarge: const TextStyle(
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                      bodyMedium: const TextStyle(
                        fontSize: 16,
                        letterSpacing: -0.1,
                      ),
                      titleLarge: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                color: const Color(0xFF0F172A),
              ),
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: const Color(0xFF020617),
                indicatorColor: const Color(0xFF6366F1).withOpacity(0.2),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(
                      color: Color(0xFF818CF8),
                      size: 28,
                    );
                  }
                  return IconThemeData(
                    color: const Color(0xFF818CF8).withOpacity(0.4),
                  );
                }),
                labelTextStyle: WidgetStateProperty.all(
                  const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF818CF8),
                  ),
                ),
              ),
            ),
            home: manager.isLoading
                ? const LoadingScreen()
                : const HomeScreen(),
          );
        },
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(40),
                blur: 30,
                opacity: 0.1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'OrgFlow',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Initializing your workspace...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NodeManager _manager = NodeManager();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, child) {
        return Scaffold(
          body: PageTransitionSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation, secondaryAnimation) {
              return SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.horizontal,
                child: child,
              );
            },
            child: Navigator(
              key: ValueKey(_selectedIndex),
              onGenerateRoute: (settings) =>
                  MaterialPageRoute(builder: (context) => _buildPage()),
            ),
          ),
          floatingActionButton: _selectedIndex == 0
              ? FloatingActionButton(
                  onPressed: () => _manager.addRootNode(""),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            destinations: const [
              NavigationDestination(icon: Icon(Icons.list), label: 'Flow'),
              NavigationDestination(
                icon: Icon(Icons.calendar_today),
                label: 'Agenda',
              ),
              NavigationDestination(
                icon: Icon(Icons.timeline),
                label: 'Timeline',
              ),
              NavigationDestination(
                icon: Icon(Icons.view_kanban),
                label: 'Kanban',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Options',
              ),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
        );
      },
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildTreeView();
      case 1:
        return AgendaView(manager: _manager);
      case 2:
        return TimelineView(manager: _manager);
      case 3:
        return KanbanView(manager: _manager);
      case 4:
        return OptionsView(manager: _manager);
      default:
        return const SizedBox();
    }
  }

  Widget _buildTreeView() {
    if (_manager.rootNodes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('OrgFlow'),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: _showMagicAddDialog,
              tooltip: 'Magic Add',
            ),
          ],
        ),
        body: const Center(child: Text("Press + to add a root task")),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('OrgFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _showMagicAddDialog,
            tooltip: 'Magic Add',
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
              Theme.of(context).colorScheme.surface.withBlue(40).withRed(20),
            ],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 80),
          itemCount: _manager.rootNodes.length,
          itemBuilder: (context, index) {
            return OrgNodeWidget(
              node: _manager.rootNodes[index],
              manager: _manager,
            );
          },
        ),
      ),
    );
  }

  void _showMagicAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('Magic Add'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe what you want to do, and I\'ll create checks tasks for you.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. "Plan a hiking trip for Sunday morning"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final prompt = controller.text.trim();
              if (prompt.isNotEmpty) {
                Navigator.pop(context);
                _showLoadingDialog();
                try {
                  await _manager.magicAdd(prompt);
                  if (mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Magic tasks created!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Consulting the oracle...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
