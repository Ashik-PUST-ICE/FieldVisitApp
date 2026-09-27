import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/auth_api.dart';
import 'package:field_visit_app/presentation/providers/auth_provider.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(
    publicClient: ref.watch(authApiClientProvider),
    userClient: ref.watch(authUserApiClientProvider),
  );
});
