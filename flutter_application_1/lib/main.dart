import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'node_manager.dart';
import 'org_node_widget.dart';
import 'agenda_view.dart';
import 'options_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrgApp());
}

class OrgApp extends StatelessWidget {
  const OrgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Org Mode',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
          surface: const Color(0xFFF6F2FF),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
          surface: const Color(0xFF1C1B1F),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF2B2930),
        ),
      ),
      home: const HomeScreen(),
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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_getPageTitle()),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
          body: _buildPage(),
          floatingActionButton: _selectedIndex == 0
              ? FloatingActionButton(
                  onPressed: () => _manager.addRootNode(""),
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            destinations: const [
              NavigationDestination(icon: Icon(Icons.list), label: 'Tree'),
              NavigationDestination(
                icon: Icon(Icons.calendar_today),
                label: 'Agenda',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Options',
              ),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
          ),
        );
      },
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Org Tree';
      case 1:
        return 'Agenda View';
      case 2:
        return 'Settings';
      default:
        return 'Org Mode';
    }
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildTreeView();
      case 1:
        return AgendaView(manager: _manager);
      case 2:
        return OptionsView(manager: _manager);
      default:
        return const SizedBox();
    }
  }

  Widget _buildTreeView() {
    if (_manager.rootNodes.isEmpty) {
      return const Center(child: Text("Press + to add a root task"));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _manager.rootNodes.length,
      itemBuilder: (context, index) {
        return OrgNodeWidget(
          node: _manager.rootNodes[index],
          manager: _manager,
        );
      },
    );
  }
}
