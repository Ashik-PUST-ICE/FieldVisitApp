import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:field_visit_app/core/constants/app_constants.dart';
import 'package:field_visit_app/core/utils/api_client.dart';
import 'package:field_visit_app/data/models/outlet.dart';

final outletsProvider = StateNotifierProvider<OutletsNotifier, AsyncValue<List<Outlet>>>((ref) {
  return OutletsNotifier(ref.watch(apiClientProvider));
});

class OutletsNotifier extends StateNotifier<AsyncValue<List<Outlet>>> {
  final ApiClient apiClient;

  OutletsNotifier(this.apiClient) : super(const AsyncValue.data([])) {
    fetchOutlets();
  }

  Future<void> fetchOutlets({Map<String, dynamic>? queryParams}) async {
    state = const AsyncValue.loading();
    try {
      final response = await apiClient.get(
        '/outlets',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data']['data'];
        final outlets = (data as List).map((json) => Outlet.fromJson(json)).toList();
        state = AsyncValue.data(outlets);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await fetchOutlets();
  }
}
