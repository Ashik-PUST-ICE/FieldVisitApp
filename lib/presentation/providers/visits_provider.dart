import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/business_api.dart';
import 'package:field_visit_app/data/models/visit.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

final visitsProvider = StateNotifierProvider<VisitsNotifier, AsyncValue<List<Visit>>>((ref) {
  return VisitsNotifier(ref.watch(businessApiProvider));
});

class VisitsNotifier extends StateNotifier<AsyncValue<List<Visit>>> {
  final BusinessApi api;

  VisitsNotifier(this.api) : super(const AsyncValue.data([])) {
    fetchVisits();
  }

  Future<void> fetchVisits({Map<String, dynamic>? queryParams}) async {
    state = const AsyncValue.loading();
    try {
      final response = await api.visits(query: queryParams);
      final payload = Map<String, dynamic>.from(response.data as Map);
      final raw = payload['data'];
      final list = raw is Map ? raw['data'] : raw;
      final visits = (list as List<dynamic>? ?? const [])
          .map((item) => Visit.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      state = AsyncValue.data(visits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> start({required int outletId, required String latitude, required String longitude}) async {
    await api.startVisit({'outlet_id': outletId, 'latitude': latitude, 'longitude': longitude});
    await fetchVisits();
  }

  Future<void> verifyLocation(int id, {required String latitude, required String longitude}) async {
    await api.verifyVisitLocation(id, {'latitude': latitude, 'longitude': longitude});
    await fetchVisits();
  }

  Future<void> complete(int id, {String? remarks}) async {
    await api.completeVisit(id, {if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim()});
    await fetchVisits();
  }

  Future<void> remove(int id) async {
    await api.deleteVisit(id);
    await fetchVisits();
  }

  Future<void> refresh() => fetchVisits();
}
