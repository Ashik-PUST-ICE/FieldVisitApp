import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/business_api.dart';
import 'package:field_visit_app/data/models/beat.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

final beatsProvider =
    StateNotifierProvider<BeatsNotifier, AsyncValue<List<Beat>>>((ref) {
  return BeatsNotifier(ref.watch(businessApiProvider));
});

class BeatsNotifier extends StateNotifier<AsyncValue<List<Beat>>> {
  final BusinessApi api;

  BeatsNotifier(this.api) : super(const AsyncValue.data([])) {
    fetchBeats();
  }

  Future<void> fetchBeats({Map<String, dynamic>? query}) async {
    state = const AsyncValue.loading();
    try {
      final response = await api.beats(query: query);
      final payload = Map<String, dynamic>.from(response.data as Map);
      final raw = payload['data'];
      final list = raw is Map ? raw['data'] : raw;
      final beats = (list as List<dynamic>? ?? const [])
          .map((item) => Beat.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      state = AsyncValue.data(beats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    await api.createBeat(data);
    await fetchBeats();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await api.updateBeat(id, data);
    await fetchBeats();
  }

  Future<void> remove(int id) async {
    await api.deleteBeat(id);
    await fetchBeats();
  }

  Future<List<Map<String, dynamic>>> outlets(int beatId) async {
    final response = await api.beatOutlets(beatId);
    final payload = Map<String, dynamic>.from(response.data as Map);
    final raw = payload['data'];
    final list = raw is Map ? raw['data'] : raw;
    return (list as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> addOutlet(int beatId, int outletId, int sequence) async {
    await api
        .addBeatOutlet(beatId, {'outlet_id': outletId, 'sequence': sequence});
  }

  Future<void> removeOutlet(int beatId, int beatOutletId) async {
    await api.removeBeatOutlet(beatId, beatOutletId);
  }

  Future<void> refresh() => fetchBeats();
}
