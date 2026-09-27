import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/business_api.dart';
import 'package:field_visit_app/data/models/outlet.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

final outletsProvider = StateNotifierProvider<OutletsNotifier, AsyncValue<List<Outlet>>>((ref) {
  return OutletsNotifier(ref.watch(businessApiProvider));
});

class OutletsNotifier extends StateNotifier<AsyncValue<List<Outlet>>> {
  final BusinessApi api;

  OutletsNotifier(this.api) : super(const AsyncValue.data([])) {
    fetchOutlets();
  }

  Future<void> fetchOutlets({Map<String, dynamic>? queryParams}) async {
    state = const AsyncValue.loading();
    try {
      final response = await api.outlets(query: queryParams);
      final payload = Map<String, dynamic>.from(response.data as Map);
      final raw = payload['data'];
      final list = raw is Map ? raw['data'] : raw;
      final outlets = (list as List<dynamic>? ?? const [])
          .map((item) => Outlet.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      state = AsyncValue.data(outlets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    await api.createOutlet(data);
    await fetchOutlets();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await api.updateOutlet(id, data);
    await fetchOutlets();
  }

  Future<void> remove(int id) async {
    await api.deleteOutlet(id);
    await fetchOutlets();
  }

  Future<void> regenerateQr(int id) async {
    await api.regenerateOutletQr(id);
    await fetchOutlets();
  }

  Future<void> deactivateQr(int id) async {
    await api.deactivateOutletQr(id);
    await fetchOutlets();
  }

  Future<void> refresh() => fetchOutlets();
}
