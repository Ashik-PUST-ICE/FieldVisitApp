import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:field_visit_app/core/constants/app_constants.dart';
import 'package:field_visit_app/core/utils/api_client.dart';
import 'package:field_visit_app/data/models/user.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage: storage);
});

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider), ref.watch(secureStorageProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  AuthNotifier(this.apiClient, this.secureStorage) : super(const AsyncValue.data(null)) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await secureStorage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      await getProfile();
    }
  }

  Future<AsyncValue<User?>> getProfile() async {
    state = const AsyncValue.loading();
    try {
      final response = await apiClient.get(AppConstants.me);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = User.fromJson(response.data['data']['user']);
        await secureStorage.write(key: AppConstants.userKey, value: user.toJson().toString());
        state = AsyncValue.data(user);
        return state;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
    return state;
  }

  Future<AsyncValue<User?>> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await apiClient.post(
        AppConstants.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['token']['access_token'];
        final user = User.fromJson(data['user']);

        await secureStorage.write(key: AppConstants.accessTokenKey, value: token);
        await secureStorage.write(key: AppConstants.userKey, value: user.toJson().toString());

        state = AsyncValue.data(user);
        return state;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
    return state;
  }

  Future<void> logout() async {
    try {
      await apiClient.post(AppConstants.logout);
    } catch (_) {}
    await secureStorage.deleteAll();
    state = const AsyncValue.data(null);
  }
}
