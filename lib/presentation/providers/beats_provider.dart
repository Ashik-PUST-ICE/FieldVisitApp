import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:field_visit_app/core/constants/app_constants.dart';
import 'package:field_visit_app/core/utils/api_client.dart';
import 'package:field_visit_app/data/models/beat.dart';

final beatsProvider = StateNotifierProvider<BeatsNotifier, AsyncValue<List<Beat>>>((ref) {
  return BeatsNotifier(ref.watch(apiClientProvider));
});

class BeatsNotifier extends StateNotifier<AsyncValue<List<Beat>>> {
  final ApiClient apiClient;

  BeatsNotifier(this.apiClient) : super(const AsyncValue.data([])) {
    fetchBeats();
  }

  Future<void> fetchBeats({Map<String, dynamic>? queryParams}) async {
    state = const AsyncValue.loading();
    try {
      final response = await apiClient.get(
        '/beats',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data']['data'];
        final beats = (data as List).map((json) => Beat.fromJson(json)).toList();
        state = AsyncValue.data(beats);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await fetchBeats();
  }
}
