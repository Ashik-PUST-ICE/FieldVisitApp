import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/providers/theme_provider.dart';
import 'package:field_visit_app/presentation/screens/account_screen.dart';
import 'package:field_visit_app/presentation/screens/dashboard_screen.dart';
import 'package:field_visit_app/presentation/screens/directory_screen.dart';
import 'package:field_visit_app/presentation/screens/map_screen.dart';
import 'package:field_visit_app/presentation/screens/more_screen.dart';
import 'package:field_visit_app/presentation/screens/outlets_screen.dart';
import 'package:field_visit_app/presentation/screens/reports_screen.dart';
import 'package:field_visit_app/presentation/screens/visits_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  final _titles = const ['Home', 'Outlets', 'Visits', 'Map', 'More'];
  final List<Widget> _screens = const [DashboardScreen(), OutletsScreen(), VisitsScreen(), MapScreen(), MoreScreen()];

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
    Navigator.of(context).pop();
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _search() async {
    final result = await showSearch<_SearchItem?>(context: context, delegate: _AppSearchDelegate());
    if (!mounted || result == null) return;
    if (result.tabIndex != null) {
      setState(() => _currentIndex = result.tabIndex!);
    } else if (result.screen != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => result.screen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = ref.watch(themeProvider);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        leading: IconButton(tooltip: 'Menu', icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        actions: [
          IconButton(tooltip: 'Search', onPressed: _search, icon: const Icon(Icons.search)),
          IconButton(tooltip: dark ? 'Light mode' : 'Dark mode', onPressed: () => ref.read(themeProvider.notifier).toggle(), icon: Icon(dark ? Icons.light_mode : Icons.dark_mode)),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF1877F2)),
                accountName: Text('FieldVisit'),
                accountEmail: Text('Field visit management'),
                currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.business, color: Color(0xFF1877F2), size: 30)),
              ),
              _drawerItem(Icons.home, 'Home', 0),
              _drawerItem(Icons.store, 'Outlets', 1),
              _drawerItem(Icons.assignment, 'Visits', 2),
              _drawerItem(Icons.map, 'Map', 3),
              const Divider(height: 8),
              _drawerAction(Icons.analytics, 'Reports', const ReportsScreen()),
              _drawerAction(Icons.manage_accounts, 'Users & companies', const DirectoryScreen()),
              _drawerAction(Icons.account_circle, 'My account', const AccountScreen()),
              _drawerItem(Icons.grid_view, 'All modules', 4),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Outlets'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Visits'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'More'),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        selected: _currentIndex == index,
        selectedTileColor: const Color(0xFFE7F3FF),
        onTap: () => _selectTab(index),
      );

  Widget _drawerAction(IconData icon, String title, Widget screen) => ListTile(leading: Icon(icon), title: Text(title), onTap: () => _openScreen(screen));
}

class _SearchItem {
  const _SearchItem(this.title, this.icon, {this.tabIndex, this.screen});
  final String title;
  final IconData icon;
  final int? tabIndex;
  final Widget? screen;
}

class _AppSearchDelegate extends SearchDelegate<_SearchItem?> {
  final items = const [
    _SearchItem('Home', Icons.home, tabIndex: 0),
    _SearchItem('Outlets', Icons.store, tabIndex: 1),
    _SearchItem('Visits', Icons.assignment, tabIndex: 2),
    _SearchItem('Map', Icons.map, tabIndex: 3),
    _SearchItem('More modules', Icons.grid_view, tabIndex: 4),
    _SearchItem('Reports', Icons.analytics, screen: ReportsScreen()),
    _SearchItem('Users and companies', Icons.manage_accounts, screen: DirectoryScreen()),
    _SearchItem('My account', Icons.account_circle, screen: AccountScreen()),
  ];

  @override
  List<Widget>? buildActions(BuildContext context) => [if (query.isNotEmpty) IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final filtered = items.where((item) => item.title.toLowerCase().contains(query.toLowerCase())).toList();
    if (filtered.isEmpty) return const Center(child: Text('No matching module found'));
    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final item = filtered[index];
        return ListTile(leading: Icon(item.icon), title: Text(item.title), onTap: () => close(context, item));
      },
    );
  }
}
