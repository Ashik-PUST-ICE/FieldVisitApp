import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/business_api.dart';
import 'package:field_visit_app/data/models/location.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

/// Children of one node in the hierarchy, keyed by `'type:parentId'`.
///
/// Keying on the parent is what makes the cascade cheap: picking a division
/// asks for its districts once and caches them, and switching to another
/// division does not refetch the 8 divisions.
final locationChildrenProvider = StateNotifierProvider<LocationChildrenNotifier,
    AsyncValue<Map<String, List<Location>>>>((ref) {
  return LocationChildrenNotifier(ref.watch(businessApiProvider));
});

class LocationChildrenNotifier
    extends StateNotifier<AsyncValue<Map<String, List<Location>>>> {
  final BusinessApi api;

  LocationChildrenNotifier(this.api) : super(const AsyncValue.data({})) {
    loadDivisions();
  }

  static String keyFor(String type, int? parentId) => '$type:${parentId ?? 0}';

  Future<void> _load(String type, int? parentId) async {
    try {
      final rows = await api.locations(type: type, parentId: parentId);
      final current = state.valueOrNull ?? const <String, List<Location>>{};
      state = AsyncValue.data({
        ...current,
        keyFor(type, parentId): rows,
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Divisions are requested immediately; every deeper level waits for the
  /// user to actually pick its parent.
  Future<void> loadDivisions() => _load('division', null);

  Future<void> loadLevel(String type, int? parentId) async {
    final cached = state.valueOrNull?[keyFor(type, parentId)];
    if (cached != null) return;
    return _load(type, parentId);
  }

  /// A level with no children (union / ward / village are not pre-seeded)
  /// resolves to an empty list rather than an error, so the field can fall
  /// back to free text instead of showing a red failure.
  Future<void> ensureLoaded(String type, int? parentId) async {
    if (state.valueOrNull?[keyFor(type, parentId)] != null) return;
    await _load(type, parentId);
  }
}
