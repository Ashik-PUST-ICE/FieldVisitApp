import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:field_visit_app/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage secureStorage;

  ApiClient({Dio? dio, required this.secureStorage}) {
    this.dio = dio ??
        Dio(BaseOptions(
          baseUrl: AppConstants.businessBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            // Send Host WITHOUT port so Herd/Valet's IP-address site routing works
            // through `adb reverse` (see AppConstants local-dev config).
            'Host': AppConstants.devHost,
          },
        ));

    if (dio == null) {
      this.dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.read(key: AppConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await secureStorage.delete(key: AppConstants.accessTokenKey);
            await secureStorage.delete(key: AppConstants.userKey);
          }
          return handler.next(error);
        },
      ));

      this.dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await dio.patch(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await dio.delete(path, data: data);
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage: storage);
});
