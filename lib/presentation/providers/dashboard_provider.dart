import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

final dashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response = await ref.watch(businessApiProvider).dashboard();
  final payload = Map<String, dynamic>.from(response.data as Map);
  return Map<String, dynamic>.from(payload['data'] as Map? ?? {});
});
