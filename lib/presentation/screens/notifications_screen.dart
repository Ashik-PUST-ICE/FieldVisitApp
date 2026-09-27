import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), actions: [IconButton(onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(), icon: const Icon(Icons.done_all))]),
      body: RefreshIndicator(onRefresh: () => ref.read(notificationsProvider.notifier).refresh(), child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(_error(e))),
        data: (items) => items.isEmpty ? ListView(children: const [SizedBox(height: 240), Center(child: Text('No notifications'))]) : ListView.separated(padding: const EdgeInsets.all(12), itemCount: items.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, i) { final n = items[i]; final read = n['read_at'] != null; return ListTile(leading: Icon(read ? Icons.notifications_none : Icons.notifications_active), title: Text('${n['title'] ?? n['type'] ?? 'Notification'}'), subtitle: Text('${n['message'] ?? ''}\n${n['created_at'] ?? ''}'), isThreeLine: true, onTap: read ? null : () => ref.read(notificationsProvider.notifier).markRead((n['id'] as num).toInt())); }),
      )),
    );
  }
}

String _error(Object e) => e is DioException && e.response?.data is Map ? ((e.response!.data as Map)['message'] ?? e.message).toString() : e.toString();
