import 'package:flutter/material.dart';
import 'package:field_visit_app/presentation/screens/account_screen.dart';
import 'package:field_visit_app/presentation/screens/assignments_screen.dart';
import 'package:field_visit_app/presentation/screens/auth_settings_screen.dart';
import 'package:field_visit_app/presentation/screens/beats_screen.dart';
import 'package:field_visit_app/presentation/screens/directory_screen.dart';
import 'package:field_visit_app/presentation/screens/notifications_screen.dart';
import 'package:field_visit_app/presentation/screens/orders_screen.dart';
import 'package:field_visit_app/presentation/screens/products_screen.dart';
import 'package:field_visit_app/presentation/screens/qr_scanner_screen.dart';
import 'package:field_visit_app/presentation/screens/reports_screen.dart';
import 'package:field_visit_app/presentation/screens/reference_data_screen.dart';
import 'package:field_visit_app/presentation/screens/role_permissions_screen.dart';
import 'package:field_visit_app/presentation/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = const <_MoreItem>[
      _MoreItem('Beats', Icons.route, const BeatsScreen()), _MoreItem('Orders', Icons.shopping_cart, const OrdersScreen()), _MoreItem('Products', Icons.inventory_2, const ProductsScreen()), _MoreItem('Alerts', Icons.notifications, const NotificationsScreen()), _MoreItem('Reports', Icons.analytics, const ReportsScreen()), _MoreItem('Reference data', Icons.settings_input_component, const ReferenceDataScreen()), _MoreItem('Assignments', Icons.person_pin, const AssignmentsScreen()), _MoreItem('Auth settings', Icons.security, const AuthSettingsScreen()), _MoreItem('Users & companies', Icons.manage_accounts, const DirectoryScreen()), _MoreItem('Role access', Icons.vpn_key, const RolePermissionsScreen()), _MoreItem('Scan QR', Icons.qr_code_scanner, const QrScannerScreen()), _MoreItem('My account', Icons.account_circle, const AccountScreen()),
    ];
    final dark = ref.watch(themeProvider);
    return Scaffold(appBar: AppBar(title: const Text('More'), actions: [IconButton(tooltip: dark ? 'Light mode' : 'Dark mode', onPressed: () => ref.read(themeProvider.notifier).toggle(), icon: Icon(dark ? Icons.light_mode : Icons.dark_mode))]), body: GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15), itemCount: items.length, itemBuilder: (_, index) { final item = items[index]; return Card(child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item.icon, size: 32, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 10), Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600))]))); }));
  }
}
class _MoreItem { final String title; final IconData icon; final Widget screen; const _MoreItem(this.title, this.icon, this.screen); }
