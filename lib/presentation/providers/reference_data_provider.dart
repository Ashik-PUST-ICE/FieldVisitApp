import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/business_api.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

final unitsProvider = StateNotifierProvider<ReferenceNotifier,
        AsyncValue<List<Map<String, dynamic>>>>(
    (ref) => ReferenceNotifier(ref.watch(businessApiProvider), true));
final competitorsProvider = StateNotifierProvider<ReferenceNotifier,
        AsyncValue<List<Map<String, dynamic>>>>(
    (ref) => ReferenceNotifier(ref.watch(businessApiProvider), false));

class ReferenceNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final BusinessApi api;
  final bool units;
  ReferenceNotifier(this.api, this.units) : super(const AsyncValue.data([])) {
    fetch();
  }
  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final response = units ? await api.units() : await api.competitors();
      final payload = Map<String, dynamic>.from(response.data as Map);
      final raw = payload['data'];
      final list = raw is Map ? raw['data'] : raw;
      state = AsyncValue.data((list as List<dynamic>? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(Map<String, dynamic> data, int? id) async {
    if (units) {
      if (id == null)
        await api.createUnit(data);
      else
        await api.updateUnit(id, data);
    } else {
      if (id == null)
        await api.createCompetitor(data);
      else
        await api.updateCompetitor(id, data);
    }
    await fetch();
  }

  Future<void> remove(int id) async {
    if (units)
      await api.deleteUnit(id);
    else
      await api.deleteCompetitor(id);
    await fetch();
  }
}
