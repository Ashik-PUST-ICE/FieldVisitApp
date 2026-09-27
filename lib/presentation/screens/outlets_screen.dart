import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_theme.dart';
import 'package:field_visit_app/data/models/outlet.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';

class OutletsScreen extends ConsumerWidget {
  const OutletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outletsAsync = ref.watch(outletsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Outlets')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(outletsProvider.notifier).refresh(),
        child: outletsAsync.when(
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
                  onPressed: () => ref.read(outletsProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (outlets) {
            if (outlets.isEmpty) {
              return const Center(child: Text('No outlets found'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: outlets.length,
              itemBuilder: (context, index) {
                final outlet = outlets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.store, color: Colors.white),
                    ),
                    title: Text(outlet.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(outlet.address ?? 'No address'),
                        if (outlet.qrStatus != null)
                          Text('QR: ${outlet.qrStatus}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to outlet detail
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add outlet
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
