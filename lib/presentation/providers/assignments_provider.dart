import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/business_api.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

final assignmentsProvider = StateNotifierProvider<AssignmentsNotifier,
        AsyncValue<List<Map<String, dynamic>>>>(
    (ref) => AssignmentsNotifier(ref.watch(businessApiProvider)));

class AssignmentsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final BusinessApi api;
  AssignmentsNotifier(this.api) : super(const AsyncValue.data([])) {
    fetch();
  }
  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final response = await api.assignments();
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
    if (id == null)
      await api.createAssignment(data);
    else
      await api.updateAssignment(id, data);
    await fetch();
  }

  Future<void> remove(int id) async {
    await api.deleteAssignment(id);
    await fetch();
  }
}
