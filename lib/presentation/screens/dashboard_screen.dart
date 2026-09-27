import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/providers/auth_provider.dart';
import 'package:field_visit_app/presentation/providers/dashboard_provider.dart';
import 'package:field_visit_app/presentation/screens/map_screen.dart';
import 'package:field_visit_app/presentation/screens/outlets_screen.dart';
import 'package:field_visit_app/presentation/screens/visits_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final dashboard = ref.watch(dashboardProvider);
    return Scaffold(
      body: user == null
          ? const Center(child: Text('Please login'))
          : dashboard.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _DashboardError(error: error, onRetry: () => ref.invalidate(dashboardProvider)),
              data: (data) => RefreshIndicator(
                    onRefresh: () async => ref.invalidate(dashboardProvider),
                    child: ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      children: [
                        _profileHeader(context, user),
                        const SizedBox(height: 8),
                        Card(child: Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 8), child: Column(children: [
                          Row(children: [
                            CircleAvatar(radius: 19, backgroundColor: const Color(0xFFE7F3FF), child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U', style: const TextStyle(color: Color(0xFF1877F2), fontWeight: FontWeight.w700))),
                            const SizedBox(width: 10),
                            Expanded(child: InkWell(onTap: () => _open(context, const VisitsScreen()), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(20)), child: const Text('What is your next field visit?')))),
                          ]),
                          const Divider(height: 18),
                          Row(children: [Expanded(child: _quickAction(Icons.play_arrow, 'Start visit', () => _open(context, const VisitsScreen()))), const SizedBox(width: 4), Expanded(child: _quickAction(Icons.store, 'Outlets', () => _open(context, const OutletsScreen()))), const SizedBox(width: 4), Expanded(child: _quickAction(Icons.map, 'Map', () => _open(context, const MapScreen())))])
                        ]))),
                        const SizedBox(height: 8),
                        _sectionTitle('Today at a glance'),
                        Card(child: Column(children: [
                          _statRow(context, Icons.storefront_outlined, 'Outlets', data['total_outlets'], const OutletsScreen()),
                          _statRow(context, Icons.assignment_outlined, 'Visited today', data['visited_today'], const VisitsScreen()),
                          _statRow(context, Icons.pending_actions, 'Pending today', data['pending_today'], const VisitsScreen()),
                          _statRow(context, Icons.check_circle_outline, 'Completed today', data['completed_today'], const VisitsScreen()),
                          _statRow(context, Icons.shopping_cart_outlined, 'Orders today', data['orders_today_count']),
                          _statRow(context, Icons.track_changes, 'Coverage', '${data['coverage_percentage'] ?? 0}%', const MapScreen(), true),
                        ])),
                        const SizedBox(height: 8),
                        _sectionTitle('Recent visits'),
                        ..._recentVisits(data['recent_visits']),
                      ],
                    ),
                  ),
            ),
    );
  }

  static Widget _profileHeader(BuildContext context, dynamic user) => Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 8), child: Row(children: [CircleAvatar(radius: 24, backgroundColor: const Color(0xFFE7F3FF), child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U', style: const TextStyle(color: Color(0xFF1877F2), fontSize: 20, fontWeight: FontWeight.w700))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Welcome back', style: TextStyle(color: Colors.grey[600], fontSize: 13)), Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), Text(user.roles?.join(' • ') ?? 'Field officer', style: TextStyle(color: Colors.grey[600], fontSize: 12))]))]));

  static Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 6), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)));

  static Widget _quickAction(IconData icon, String title, VoidCallback onTap) => InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: const Color(0xFF1877F2)), const SizedBox(width: 5), Flexible(child: Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))])));

  static Widget _statRow(BuildContext context, IconData icon, String title, dynamic value, [Widget? target, bool last = false]) => InkWell(onTap: target == null ? null : () => _open(context, target), child: Column(children: [ListTile(leading: CircleAvatar(radius: 18, backgroundColor: const Color(0xFFE7F3FF), child: Icon(icon, size: 19, color: const Color(0xFF1877F2))), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), trailing: Text('${value ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1877F2)))), if (!last) const Divider(height: 1, indent: 64)]));

  static List<Widget> _recentVisits(dynamic value) {
    final visits = value is List ? value : const [];
    if (visits.isEmpty) return [const Card(child: ListTile(title: Text('No recent visits')) )];
    return visits.map<Widget>((item) {
      final visit = Map<String, dynamic>.from(item as Map);
      return Card(child: ListTile(leading: const Icon(Icons.assignment), title: Text('Visit #${visit['id'] ?? '-'}'), subtitle: Text('Status: ${visit['status'] ?? 'unknown'}')));
    }).toList();
  }

  static void _open(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class _DashboardError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _DashboardError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Dashboard error: $error'), ElevatedButton(onPressed: onRetry, child: const Text('Retry'))]));
}

