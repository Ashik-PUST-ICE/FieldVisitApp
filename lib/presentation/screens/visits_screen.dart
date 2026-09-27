import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_theme.dart';
import 'package:field_visit_app/data/models/visit.dart';
import 'package:field_visit_app/presentation/providers/visits_provider.dart';

class VisitsScreen extends ConsumerWidget {
  const VisitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(visitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Visits')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(visitsProvider.notifier).refresh(),
        child: visitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(visitsProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (visits) {
            if (visits.isEmpty) {
              return const Center(child: Text('No visits found'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visits.length,
              itemBuilder: (context, index) {
                final visit = visits[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.assignment, color: Colors.white),
                    ),
                    title: Text('Visit #${visit.id}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Outlet ID: ${visit.outletId}'),
                        if (visit.status != null) Text('Status: ${visit.status}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to visit detail
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
