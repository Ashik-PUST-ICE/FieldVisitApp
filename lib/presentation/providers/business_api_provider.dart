import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/utils/api_client.dart';
import 'package:field_visit_app/data/business_api.dart';

final businessApiProvider = Provider<BusinessApi>((ref) {
  return BusinessApi(ref.watch(apiClientProvider));
});
