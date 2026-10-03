import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/presentation/providers/auth_provider.dart';
import 'package:field_visit_app/presentation/screens/account_screen.dart';
import 'package:field_visit_app/presentation/screens/dashboard_screen.dart';
import 'package:field_visit_app/presentation/screens/map_screen.dart';
import 'package:field_visit_app/presentation/screens/more_screen.dart';
import 'package:field_visit_app/presentation/screens/notifications_screen.dart';
import 'package:field_visit_app/presentation/providers/notifications_provider.dart';
import 'package:field_visit_app/presentation/screens/kpi_screen.dart';
import 'package:field_visit_app/presentation/screens/outlets_screen.dart';
import 'package:field_visit_app/presentation/screens/qr_scanner_screen.dart';
import 'package:field_visit_app/presentation/screens/reports_screen.dart';
import 'package:field_visit_app/presentation/screens/security_settings_screen.dart';
import 'package:field_visit_app/presentation/screens/storage_settings_screen.dart';
import 'package:field_visit_app/presentation/screens/visits_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),   // 0: Dashboard
    OutletsScreen(),     // 1: Outlets
    VisitsScreen(),      // 2: Visits
    MapScreen(),         // 3: Route Map
    MoreScreen(),        // 4: All Modules
  ];

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _openScreen(Widget screen) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF1F5F2),

      // Top Green Header (Cellfin Layout with FieldVisit Branding)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: AppColors.cellfinGreen,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Hamburger Menu Button
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),

                  const SizedBox(width: 4),

                  // White Logo Pill/Card for FieldVisit
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF136B3E),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Center(
                            child: Icon(Icons.location_city_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                        const SizedBox(width: 6),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Field',
                                style: TextStyle(
                                  color: Color(0xFF136B3E),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              TextSpan(
                                text: 'Visit',
                                style: TextStyle(
                                  color: Color(0xFFFFB300), // Golden Yellow
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Profile Icon
                  IconButton(
                    tooltip: 'My Profile',
                    icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 24),
                    onPressed: () => _openScreen(const AccountScreen()),
                  ),

                  // Notifications Bell with Unread Badge
                  Consumer(
                    builder: (context, ref, _) {
                      final unread = ref.watch(unreadNotificationsCountProvider);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            tooltip: 'Alerts',
                            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                            onPressed: () => _openScreen(const NotificationsScreen()),
                          ),
                          if (unread > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  // Logout Icon
                  IconButton(
                    tooltip: 'Logout',
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // Side Drawer Menu with FieldVisit Organization branding
      drawer: _buildFieldVisitDrawer(context),

      // Body Content
      body: IndexedStack(index: _currentIndex, children: _screens),

      // Bottom Navigation Bar with Floating Center Scan QR Button
      bottomNavigationBar: _buildFieldVisitBottomBar(context),
    );
  }

  /// Cellfin Style Bottom Navigation Bar with Center Floating QR Check-in Button
  Widget _buildFieldVisitBottomBar(BuildContext context) {
    return Container(
      color: AppColors.cellfinGreen,
      height: 68,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Dashboard
              _buildBottomNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isSelected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),

              // 2. Outlets
              _buildBottomNavItem(
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront_rounded,
                label: 'Outlets',
                isSelected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),

              // Spacer for the center circular button
              const SizedBox(width: 60),

              // 4. Visits
              _buildBottomNavItem(
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment_rounded,
                label: 'Visits',
                isSelected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),

              // 5. More / Modules
              _buildBottomNavItem(
                icon: Icons.grid_view_rounded,
                activeIcon: Icons.grid_view_rounded,
                label: 'More',
                isSelected: _currentIndex == 4,
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),

          // Center Circular Floating "Scan QR" Button
          Positioned(
            top: -24,
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())),
              borderRadius: BorderRadius.circular(35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'CHECK-IN',
                          style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Icon(
                          Icons.qr_code_2_rounded,
                          color: Color(0xFF136B3E),
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Scan QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFFFFB300) : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFB300) : Colors.white,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Side Drawer Menu with FieldVisit branding
  Widget _buildFieldVisitDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Top Green Area with Logo Card
            Container(
              width: double.infinity,
              height: 140,
              color: AppColors.cellfinGreen,
              child: Center(
                child: Container(
                  width: 210,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF136B3E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.location_city_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Field',
                                  style: TextStyle(
                                    color: Color(0xFF136B3E),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Visit',
                                  style: TextStyle(
                                    color: Color(0xFFFFB300),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Field Operations & Sales',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Drawer Menu List with Field Visit Modules
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildDrawerTile(Icons.home_rounded, 'Home Dashboard', () => _selectTab(0)),
                  _buildDrawerTile(Icons.storefront_rounded, 'Outlets & Stores', () => _selectTab(1)),
                  _buildDrawerTile(Icons.assignment_rounded, 'My Field Visits', () => _selectTab(2)),
                  _buildDrawerTile(Icons.fact_check_rounded, 'Target & KPIs', () => _openScreen(const KpiScreen())),
                  _buildDrawerTile(Icons.map_rounded, 'Field Route & Map', () => _openScreen(const MapScreen())),
                  _buildDrawerTile(Icons.bar_chart_rounded, 'Targets & Reports', () => _openScreen(const ReportsScreen())),
                  _buildDrawerTile(Icons.settings_rounded, 'Settings', () => _openScreen(const SecuritySettingsScreen())),
                  if ((ref.watch(authProvider).valueOrNull?.roles ?? []).any((role) => role == 'super-admin' || role == 'special-super-admin'))
                    _buildDrawerTile(Icons.cloud_outlined, 'Storage Settings', () => _openScreen(const StorageSettingsScreen())),
                  _buildDrawerTile(Icons.person_outline_rounded, 'My Profile', () => _openScreen(const AccountScreen())),
                  _buildDrawerTile(Icons.logout_rounded, 'Logout', () => ref.read(authProvider.notifier).logout()),
                ],
              ),
            ),

            // Bottom Footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Version 2.4.0 (Build 395)',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF136B3E), width: 1.5),
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: Color(0xFF136B3E), size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ফিল্ড ভিজিট এন্টারপ্রাইজ',
                            style: TextStyle(
                              color: Color(0xFF136B3E),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'ফিল্ড ফোর্স ও সেলস অটোমেশন সিস্টেম',
                            style: TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF374151), size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      onTap: onTap,
    );
  }
}
