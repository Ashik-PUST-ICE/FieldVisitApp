import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/providers/auth_provider.dart';
import 'package:field_visit_app/presentation/providers/dashboard_provider.dart';
import 'package:field_visit_app/presentation/screens/map_screen.dart';
import 'package:field_visit_app/presentation/screens/outlets_screen.dart';
import 'package:field_visit_app/presentation/screens/visits_screen.dart';
import 'package:field_visit_app/presentation/screens/login_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final dashboard = ref.watch(dashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today at a glance'),
        actions: [
          IconButton(onPressed: () => ref.invalidate(dashboardProvider), icon: const Icon(Icons.refresh)),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please login'))
          : dashboard.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _DashboardError(error: error, onRetry: () => ref.invalidate(dashboardProvider)),
              data: (data) => RefreshIndicator(
                    onRefresh: () async => ref.invalidate(dashboardProvider),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                CircleAvatar(radius: 25, backgroundColor: const Color(0xFFE0F5ED), child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U', style: const TextStyle(color: Color(0xFF16805F), fontWeight: FontWeight.bold, fontSize: 20))),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Good day,', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])), Text(user.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF123047))), const SizedBox(height: 2), Text(user.roles?.join(' • ') ?? 'Field officer', style: TextStyle(color: Colors.grey[600]))])),
                              ]),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            _card(context, Icons.storefront_outlined, 'Outlets', data['total_outlets'], () => _open(context, const OutletsScreen())),
                            _card(context, Icons.assignment, 'Visited today', data['visited_today'], () => _open(context, const VisitsScreen())),
                            _card(context, Icons.pending_actions, 'Pending today', data['pending_today'], () => _open(context, const VisitsScreen())),
                            _card(context, Icons.check_circle, 'Completed today', data['completed_today'], () => _open(context, const VisitsScreen())),
                            _card(context, Icons.shopping_cart, 'Orders today', data['orders_today_count']),
                            _card(context, Icons.track_changes, 'Coverage', '${data['coverage_percentage'] ?? 0}%', () => _open(context, const MapScreen())),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('Recent visits', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        ..._recentVisits(data['recent_visits']),
                      ],
                    ),
                  ),
            ),
    );
  }

  static Widget _card(BuildContext context, IconData icon, String title, dynamic value, [VoidCallback? onTap]) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFEAF7F2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 24, color: const Color(0xFF16805F))),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${value ?? 0}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF123047))),
            ]),
          ),
        ),
      );

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

