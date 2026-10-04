import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
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
      // Host without port — required for Herd/Valet IP-access routing (see AppConstants).
      'Host': AppConstants.devHost,
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
      // Host without port — required for Herd/Valet IP-access routing (see AppConstants).
      'Host': AppConstants.devHost,
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

  // Dev visibility: settings/biometric requests were invisible in logs before.
  dio.interceptors.add(PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    error: true,
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
    final biometricEnabled = await isBiometricLoginEnabled();
    // When biometric login is enabled, do not silently open the app with a
    // cached token. The device must unlock the session first.
    if (token != null && !biometricEnabled) {
      await getProfile();
    }
  }

  Future<bool> isBiometricLoginEnabled() async {
    return (await secureStorage.read(key: AppConstants.biometricLoginEnabledKey)) == 'true';
  }

  Future<bool> canUseBiometrics() async {
    final auth = LocalAuthentication();
    try {
      return await auth.canCheckBiometrics && await auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> enableBiometricLogin() async {
    final auth = LocalAuthentication();
    try {
      if (!await auth.canCheckBiometrics || !await auth.isDeviceSupported()) return false;
      final verified = await auth.authenticate(
        localizedReason: 'Verify your identity to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      if (!verified) return false;

      await secureStorage.write(key: AppConstants.biometricLoginEnabledKey, value: 'true');
      try {
        await authUserApiClient.put('/security-settings/biometric', data: {'enabled': true});
      } catch (_) {
        // Device unlock remains local-first; the preference syncs next time.
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disableBiometricLogin() async {
    await secureStorage.delete(key: AppConstants.biometricLoginEnabledKey);
    try {
      await authUserApiClient.put('/security-settings/biometric', data: {'enabled': false});
    } catch (_) {}
  }

  Future<AsyncValue<User?>> biometricLogin() async {
    state = const AsyncValue.loading();
    try {
      if (!await isBiometricLoginEnabled()) {
        state = const AsyncValue.data(null);
        return state;
      }
      final token = await secureStorage.read(key: AppConstants.accessTokenKey);
      if (token == null || token.isEmpty) {
        await disableBiometricLogin();
        state = const AsyncValue.data(null);
        return state;
      }
      final auth = LocalAuthentication();
      final verified = await auth.authenticate(
        localizedReason: 'Verify your identity to unlock Field Visit',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      if (!verified) {
        state = const AsyncValue.data(null);
        return state;
      }
      return await getProfile();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return state;
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
        final refreshToken = data['token']['refresh_token'];
        if (refreshToken is String && refreshToken.isNotEmpty) {
          await secureStorage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
        }
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
