import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:field_visit_app/core/constants/app_constants.dart';
import 'package:field_visit_app/core/utils/api_client.dart';
import 'package:field_visit_app/data/models/user.dart';

final authApiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.authBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: AppConstants.accessTokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await storage.delete(key: AppConstants.accessTokenKey);
        await storage.delete(key: AppConstants.userKey);
      }
      return handler.next(error);
    },
  ));

  dio.interceptors.add(PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    error: true,
  ));

  return ApiClient(dio: dio, secureStorage: storage);
});

final authUserApiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.authUserBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: AppConstants.accessTokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
  ));

  return ApiClient(dio: dio, secureStorage: storage);
});

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(
    ref.watch(authApiClientProvider),
    ref.watch(authUserApiClientProvider),
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiClient authApiClient;
  final ApiClient authUserApiClient;
  final ApiClient businessApiClient;
  final FlutterSecureStorage secureStorage;

  AuthNotifier(this.authApiClient, this.authUserApiClient, this.businessApiClient, this.secureStorage)
      : super(const AsyncValue.data(null)) {
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
      final response = await authUserApiClient.get('/me');
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
      final response = await authApiClient.post(
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
      await authUserApiClient.post('/logout');
    } catch (_) {}
    await secureStorage.deleteAll();
    state = const AsyncValue.data(null);
  }
}
