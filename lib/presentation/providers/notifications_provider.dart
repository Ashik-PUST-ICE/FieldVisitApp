import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/business_api.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return NotificationsNotifier(ref.watch(businessApiProvider));
});

class NotificationsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final BusinessApi api;
  NotificationsNotifier(this.api) : super(const AsyncValue.data([])) { fetch(); }

  Future<void> fetch({bool unreadOnly = false}) async {
    state = const AsyncValue.loading();
    try {
      final response = await api.notifications(query: {'unread_only': unreadOnly ? 1 : 0});
      final payload = Map<String, dynamic>.from(response.data as Map);
      final raw = payload['data'];
      final list = raw is Map ? raw['data'] : raw;
      state = AsyncValue.data((list as List<dynamic>? ?? const []).map((item) => Map<String, dynamic>.from(item as Map)).toList());
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> markRead(int id) async { await api.markNotificationRead(id); await fetch(); }
  Future<void> markAllRead() async { await api.markAllNotificationsRead(); await fetch(); }
  Future<void> refresh() => fetch();
}
