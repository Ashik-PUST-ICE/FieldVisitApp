import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/business_api.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return NotificationsNotifier(ref);
});

final unreadNotificationsCountProvider = StateNotifierProvider<UnreadCountNotifier, int>((ref) {
  return UnreadCountNotifier(ref.watch(businessApiProvider));
});

class UnreadCountNotifier extends StateNotifier<int> {
  final BusinessApi api;
  UnreadCountNotifier(this.api) : super(0) {
    fetch();
  }

  Future<void> fetch() async {
    try {
      final res = await api.unreadCount();
      final payload = Map<String, dynamic>.from(res.data as Map);
      final raw = payload['data'];
      final count = raw is Map ? raw['count'] : raw;
      state = int.tryParse(count?.toString() ?? '0') ?? 0;
    } catch (_) {}
  }

  void decrement() {
    if (state > 0) state--;
  }

  void clear() {
    state = 0;
  }
}

class NotificationsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref ref;
  BusinessApi get api => ref.read(businessApiProvider);

  NotificationsNotifier(this.ref) : super(const AsyncValue.data([])) {
    fetch();
  }

  Future<void> fetch({bool unreadOnly = false}) async {
    state = const AsyncValue.loading();
    try {
      final response = await api.notifications(query: {'unread_only': unreadOnly ? 1 : 0});
      final payload = Map<String, dynamic>.from(response.data as Map);
      final raw = payload['data'];
      final list = raw is Map ? raw['data'] : raw;
      state = AsyncValue.data((list as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList());
      // Also update count
      ref.read(unreadNotificationsCountProvider.notifier).fetch();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRead(int id) async {
    await api.markNotificationRead(id);
    ref.read(unreadNotificationsCountProvider.notifier).decrement();
    await fetch();
  }

  Future<void> markAllRead() async {
    await api.markAllNotificationsRead();
    ref.read(unreadNotificationsCountProvider.notifier).clear();
    await fetch();
  }

  Future<void> refresh() => fetch();
}
