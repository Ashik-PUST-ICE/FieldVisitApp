import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

final reportsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(businessApiProvider);
  final results = await Future.wait([api.visitReport(), api.orderReport(), api.officerPerformance()]);
  Map<String, dynamic> data(dynamic response) {
    final payload = Map<String, dynamic>.from(response.data as Map);
    final value = payload['data'];
    return value is Map ? Map<String, dynamic>.from(value) : {'rows': value};
  }
  return {'visits': data(results[0]), 'orders': data(results[1]), 'officers': data(results[2])};
});
