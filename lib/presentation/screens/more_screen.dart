import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';
import 'package:field_visit_app/presentation/providers/theme_provider.dart';
import 'package:field_visit_app/presentation/screens/account_screen.dart';
import 'package:field_visit_app/presentation/screens/assignments_screen.dart';
import 'package:field_visit_app/presentation/screens/auth_settings_screen.dart';
import 'package:field_visit_app/presentation/screens/beats_screen.dart';
import 'package:field_visit_app/presentation/screens/directory_screen.dart';
import 'package:field_visit_app/presentation/screens/notifications_screen.dart';
import 'package:field_visit_app/presentation/screens/orders_screen.dart';
import 'package:field_visit_app/presentation/screens/products_screen.dart';
import 'package:field_visit_app/presentation/screens/qr_scanner_screen.dart';
import 'package:field_visit_app/presentation/screens/kpi_screen.dart';
import 'package:field_visit_app/presentation/screens/reference_data_screen.dart';
import 'package:field_visit_app/presentation/screens/reports_screen.dart';
import 'package:field_visit_app/presentation/screens/role_permissions_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'allModules'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: dark ? tr(ref, 'lightMode') : tr(ref, 'darkMode'),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
            icon:
                Icon(dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          _buildCategoryHeader(tr(ref, 'fieldOperations'),
              tr(ref, 'fieldOperationsSub')),
          const SizedBox(height: 10),
          _buildGrid(
              context,
              [
                _ModuleItem(
                  title: tr(ref, 'beatsRoutes'),
                  subtitle: tr(ref, 'beatsRoutesSub'),
                  icon: Icons.alt_route_rounded,
                  gradient: [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
                  screen: const BeatsScreen(),
                ),
                _ModuleItem(
                  title: tr(ref, 'ordersTitle'),
                  subtitle: tr(ref, 'ordersSub'),
                  icon: Icons.shopping_bag_rounded,
                  gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
                  screen: const OrdersScreen(),
                ),
                _ModuleItem(
                  title: tr(ref, 'productsTitle'),
                  subtitle: tr(ref, 'productsSub'),
                  icon: Icons.inventory_2_rounded,
                  gradient: [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
                  screen: const ProductsScreen(),
                ),
                _ModuleItem(
                  title: tr(ref, 'scanQrTitle'),
                  subtitle: tr(ref, 'scanQrSub'),
                  icon: Icons.qr_code_scanner_rounded,
                  gradient: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                  screen: const QrScannerScreen(),
                ),
              ],
              isDark),
          const SizedBox(height: 24),
          _buildCategoryHeader(tr(ref, 'intelligenceReports'),
              tr(ref, 'intelligenceReportsSub')),
          const SizedBox(height: 10),
          _buildGrid(
              context,
              [
                _ModuleItem(
                  title: tr(ref, 'kpi'),
                  subtitle: tr(ref, 'kpiSub'),
                  icon: Icons.fact_check_rounded,
                  gradient: [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
                  screen: const KpiScreen(),
                ),
                _ModuleItem(
                  title: tr(ref, 'analyticsReports'),
                  subtitle: tr(ref, 'analyticsReportsSub'),
                  icon: Icons.analytics_rounded,
                  gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
                  screen: const ReportsScreen(),
                ),
                _ModuleItem(
                  title: tr(ref, 'systemAlerts'),
                  subtitle: tr(ref, 'systemAlertsSub'),
                  icon: Icons.notifications_active_rounded,
                  gradient: [const Color(0xFFEF4444), const Color(0xFFF87171)],
                  screen: const NotificationsScreen(),
                ),
                _ModuleItem(
                  title: tr(ref, 'referenceData'),
                  subtitle: tr(ref, 'referenceDataSub'),
                  icon: Icons.tune_rounded,
                  gradient: [const Color(0xFF06B6D4), const Color(0xFF22D3EE)],
                  screen: const ReferenceDataScreen(),
                ),
                _ModuleItem(
                  title: tr(ref, 'assignments'),
                  subtitle: tr(ref, 'assignmentsSub'),
                  icon: Icons.person_pin_circle_rounded,
                  gradient: [const Color(0xFFEC4899), const Color(0xFFF472B6)],
                  screen: const AssignmentsScreen(),
                ),
              ],
              isDark),
          const SizedBox(height: 24),
          _buildCategoryHeader(tr(ref, 'adminSecurity'),
              tr(ref, 'adminSecuritySub')),
          const SizedBox(height: 10),
          _buildGrid(
              context,
              [
                _ModuleItem(
                  title: tr(ref, 'directory'),
                  subtitle: tr(ref, 'directorySub'),
                  icon: Icons.corporate_fare_rounded,
                  gradient: [const Color(0xFF6366F1), const Color(0xFF818CF8)],
                  screen: const DirectoryScreen(),
                ),
                _ModuleItem(
                  title: tr(ref, 'rolesPermissions'),
                  subtitle: tr(ref, 'rolesPermissionsSub'),
                  icon: Icons.security_rounded,
                  gradient: [const Color(0xFF64748B), const Color(0xFF94A3B8)],
                  screen: const RolePermissionsScreen(),
                ),
                _ModuleItem(
                  title: tr(ref, 'authSettings'),
                  subtitle: tr(ref, 'authSettingsSub'),
                  icon: Icons.lock_person_rounded,
                  gradient: [const Color(0xFF059669), const Color(0xFF10B981)],
                  screen: const AuthSettingsScreen(),
                ),
                _ModuleItem(
                  title: tr(ref, 'myProfile'),
                  subtitle: tr(ref, 'myProfileSub'),
                  icon: Icons.account_circle_rounded,
                  gradient: [const Color(0xFF0D9488), const Color(0xFF0891B2)],
                  screen: const AccountScreen(),
                ),
              ],
              isDark),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _buildGrid(
      BuildContext context, List<_ModuleItem> items, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => item.screen)),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: item.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final Widget screen;

  const _ModuleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.screen,
  });
}
