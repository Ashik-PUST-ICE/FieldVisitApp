import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_theme.dart';
import 'package:field_visit_app/presentation/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please login'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, ${user.fullName}', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text('Email: ${user.email}', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text('Role: ${user.roles?.join(", ") ?? "N/A"}', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildDashboardCard(context, Icons.store, 'Outlets', '0', () {}),
                    _buildDashboardCard(context, Icons.assignment, 'Visits', '0', () {}),
                    _buildDashboardCard(context, Icons.calendar_today, 'Beats', '0', () {}),
                    _buildDashboardCard(context, Icons.shopping_cart, 'Orders', '0', () {}),
                    _buildDashboardCard(context, Icons.map, 'Map', '', () {}),
                    _buildDashboardCard(context, Icons.notifications, 'Notifications', '0', () {}),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, IconData icon, String title, String count, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (count.isNotEmpty)
                Text(count, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
