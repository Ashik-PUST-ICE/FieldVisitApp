import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/presentation/providers/auth_provider.dart';
import 'package:field_visit_app/presentation/providers/dashboard_provider.dart';
import 'package:field_visit_app/presentation/screens/account_screen.dart';
import 'package:field_visit_app/presentation/screens/assignments_screen.dart';
import 'package:field_visit_app/presentation/screens/beats_screen.dart';
import 'package:field_visit_app/presentation/screens/directory_screen.dart';
import 'package:field_visit_app/presentation/screens/map_screen.dart';
import 'package:field_visit_app/presentation/screens/more_screen.dart';
import 'package:field_visit_app/presentation/screens/orders_screen.dart';
import 'package:field_visit_app/presentation/screens/outlets_screen.dart';
import 'package:field_visit_app/presentation/screens/products_screen.dart';
import 'package:field_visit_app/presentation/screens/qr_scanner_screen.dart';
import 'package:field_visit_app/presentation/screens/kpi_screen.dart';
import 'package:field_visit_app/presentation/screens/reports_screen.dart';
import 'package:field_visit_app/presentation/screens/role_permissions_screen.dart';
import 'package:field_visit_app/presentation/screens/visits_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0B1220) // Dark slate for dark mode
          : const Color(0xFFF1F5F2), // Soft modern pale mint background
      body: dashboard.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.cellfinGreen),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Connection Error: $error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.cellfinGreen, foregroundColor: Colors.white),
                onPressed: () => ref.invalidate(dashboardProvider),
                child: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
        data: (data) => RefreshIndicator(
          color: AppColors.cellfinGreen,
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Top Green Section with Officer Name & Target Coverage Pill
                _buildFieldVisitHeader(context, user, data),

                // Main Service Cards Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    children: [
                      // First White Card: 8 Core Field Operations
                      _buildFirstFieldCard(context, data),

                      const SizedBox(height: 14),

                      // Second White Card: 8 Field Management & Analytics Modules
                      _buildSecondManagementCard(context, data),

                      const SizedBox(height: 14),

                      // Real-time Field Performance & Summary
                      _buildFieldPerformanceSummary(context, data),

                      const SizedBox(height: 85), // Padding for bottom bar
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top Green area with Field Officer name and Golden Target Pill
  Widget _buildFieldVisitHeader(BuildContext context, dynamic user, Map<String, dynamic> data) {
    final officerName = user != null && user.fullName.isNotEmpty
        ? user.fullName.toUpperCase()
        : 'FIELD OFFICER';
    final coverage = data['coverage_percentage'] ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.cellfinGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Officer Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      officerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'ONLINE • ON DUTY',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Golden Target Coverage Pill Button
              InkWell(
                onTap: () => _open(context, const KpiScreen()),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300), // Golden Yellow
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.check_rounded, color: Color(0xFF136B3E), size: 15),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$coverage% Target',
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// First Card: 8 Field Operations (Start Visit, Outlets, Orders, Route Map, Photos, Products, Beats, QR Check-in)
  Widget _buildFirstFieldCard(BuildContext context, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          // Row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIconItem(
                icon: Icons.play_circle_outline_rounded,
                title: 'Start\nVisit',
                onTap: () => _open(context, const VisitsScreen()),
              ),
              _buildIconItem(
                icon: Icons.storefront_outlined,
                title: 'Outlets\nDirectory',
                onTap: () => _open(context, const OutletsScreen()),
              ),
              _buildIconItem(
                icon: Icons.shopping_bag_outlined,
                title: 'Book\nOrder',
                onTap: () => _open(context, const OrdersScreen()),
              ),
              _buildIconItem(
                icon: Icons.map_outlined,
                title: 'Live\nRoute',
                onTap: () => _open(context, const MapScreen()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Row 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIconItem(
                icon: Icons.camera_alt_outlined,
                title: 'Shelf\nPhotos',
                onTap: () => _open(context, const VisitsScreen()),
              ),
              _buildIconItem(
                icon: Icons.inventory_2_outlined,
                title: 'Product\nCatalog',
                onTap: () => _open(context, const ProductsScreen()),
              ),
              _buildIconItem(
                icon: Icons.alt_route_rounded,
                title: 'Beats &\nRoutes',
                onTap: () => _open(context, const BeatsScreen()),
              ),
              _buildIconItem(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan QR\nCheck-in',
                hasBadge: true,
                onTap: () => _open(context, const QrScannerScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Second Card: 8 Management & Analytics Modules (Circular Mint Badges)
  Widget _buildSecondManagementCard(BuildContext context, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          // Row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCircularMintItem(
                icon: Icons.analytics_rounded,
                title: 'Analytics\nReports',
                onTap: () => _open(context, const ReportsScreen()),
              ),
              _buildCircularMintItem(
                icon: Icons.person_pin_circle_rounded,
                title: 'Officer\nAssignments',
                onTap: () => _open(context, const AssignmentsScreen()),
              ),
              _buildCircularMintItem(
                icon: Icons.corporate_fare_rounded,
                title: 'Directory &\nUsers',
                onTap: () => _open(context, const DirectoryScreen()),
              ),
              _buildCircularMintItem(
                icon: Icons.fact_check_rounded,
                title: 'Target\nKPIs',
                onTap: () => _open(context, const KpiScreen()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Row 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCircularMintItem(
                icon: Icons.travel_explore_rounded,
                title: 'Competitor\nAudit',
                onTap: () => _open(context, const VisitsScreen()),
              ),
              _buildCircularMintItem(
                icon: Icons.security_rounded,
                title: 'Role\nPermissions',
                onTap: () => _open(context, const RolePermissionsScreen()),
              ),
              _buildCircularMintItem(
                icon: Icons.person_outline_rounded,
                title: 'My\nAccount',
                onTap: () => _open(context, const AccountScreen()),
              ),
              _buildCircularMintItem(
                icon: Icons.grid_view_rounded,
                title: 'All\nModules',
                onTap: () => _open(context, const MoreScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Today's Field Performance Summary
  Widget _buildFieldPerformanceSummary(BuildContext context, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visited = data['visited_today'] ?? 0;
    final pending = data['pending_today'] ?? 0;
    final total = data['total_outlets'] ?? 0;
    final orders = data['orders_today_count'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.insights_rounded, color: AppColors.cellfinGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Today\'s Field Summary',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _open(context, const VisitsScreen()),
                child: const Text(
                  'View All Visits',
                  style: TextStyle(color: AppColors.cellfinGreen, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMetricPill('Visited', '$visited', const Color(0xFF136B3E), const Color(0xFFE8F5E9), isDark: isDark),
              const SizedBox(width: 8),
              _buildMetricPill('Pending', '$pending', const Color(0xFFF59E0B), const Color(0xFFFEF3C7), isDark: isDark),
              const SizedBox(width: 8),
              _buildMetricPill('Total Outlets', '$total', const Color(0xFF1E88E5), const Color(0xFFE3F2FD), isDark: isDark),
              const SizedBox(width: 8),
              _buildMetricPill('Orders', '$orders', const Color(0xFF7E57C2), const Color(0xFFEDE7F6), isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color textColor, Color bgColor, {bool isDark = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? bgColor.withOpacity(0.16) : bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: isDark ? Color.lerp(textColor, Colors.white, 0.35) : textColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: (isDark ? Color.lerp(textColor, Colors.white, 0.35) : textColor)?.withOpacity(0.85),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Primary 4x2 Grid icon button
  Widget _buildIconItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SizedBox(
          width: 76,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(icon, size: 36, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF136B3E)),
                        if (hasBadge)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFB300),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF263238),
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Circular mint icon item
  Widget _buildCircularMintItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SizedBox(
          width: 76,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF14532D) : const Color(0xFFD7EEDD), // Soft mint circle
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isDark ? const Color(0xFF6EE7A0) : const Color(0xFF136B3E),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF263238),
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void _open(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
