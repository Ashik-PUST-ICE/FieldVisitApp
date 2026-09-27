import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/business_api.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

final ordersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return OrdersNotifier(ref.watch(businessApiProvider));
});

class OrdersNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final BusinessApi api;
  OrdersNotifier(this.api) : super(const AsyncValue.data([])) { fetchOrders(); }

  Future<void> fetchOrders() async {
    state = const AsyncValue.loading();
    try {
      final response = await api.orders();
      final payload = Map<String, dynamic>.from(response.data as Map);
      final raw = payload['data'];
      final list = raw is Map ? raw['data'] : raw;
      state = AsyncValue.data((list as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map)).toList());
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> create(Map<String, dynamic> data) async { await api.createOrder(data); await fetchOrders(); }
  Future<void> update(int id, Map<String, dynamic> data) async { await api.updateOrder(id, data); await fetchOrders(); }
  Future<void> remove(int id) async { await api.deleteOrder(id); await fetchOrders(); }

  Future<List<Map<String, dynamic>>> items(int orderId) async {
    final response = await api.orderItems(orderId);
    final payload = Map<String, dynamic>.from(response.data as Map);
    final raw = payload['data'];
    final list = raw is Map ? raw['data'] : raw;
    return (list as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> createItem(int orderId, Map<String, dynamic> data) async {
    await api.createOrderItem(orderId, data);
  }

  Future<void> deleteItem(int orderId, int itemId) async {
    await api.deleteOrderItem(orderId, itemId);
  }

  Future<void> refresh() => fetchOrders();
}
