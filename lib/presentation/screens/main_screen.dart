import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/screens/dashboard_screen.dart';
import 'package:field_visit_app/presentation/screens/outlets_screen.dart';
import 'package:field_visit_app/presentation/screens/visits_screen.dart';
import 'package:field_visit_app/presentation/screens/map_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    OutletsScreen(),
    VisitsScreen(),
    MapScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarItemType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Outlets'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Visits'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }
}
