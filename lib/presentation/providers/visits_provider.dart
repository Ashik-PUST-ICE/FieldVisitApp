import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:field_visit_app/core/constants/app_constants.dart';
import 'package:field_visit_app/core/utils/api_client.dart';
import 'package:field_visit_app/data/models/visit.dart';

final visitsProvider = StateNotifierProvider<VisitsNotifier, AsyncValue<List<Visit>>>((ref) {
  return VisitsNotifier(ref.watch(apiClientProvider));
});

class VisitsNotifier extends StateNotifier<AsyncValue<List<Visit>>> {
  final ApiClient apiClient;

  VisitsNotifier(this.apiClient) : super(const AsyncValue.data([])) {
    fetchVisits();
  }

  Future<void> fetchVisits({Map<String, dynamic>? queryParams}) async {
    state = const AsyncValue.loading();
    try {
      final response = await apiClient.get(
        '/visits',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data']['data'];
        final visits = (data as List).map((json) => Visit.fromJson(json)).toList();
        state = AsyncValue.data(visits);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await fetchVisits();
  }
}
