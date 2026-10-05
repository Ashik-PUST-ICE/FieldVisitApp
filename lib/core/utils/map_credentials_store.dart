import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:field_visit_app/core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Result of checking a Google Maps key against Google's own endpoint.
class MapKeyCheck {
  final bool valid;
  final String message;
  const MapKeyCheck(this.valid, this.message);
}

/// Stores and validates the Google Maps API key entered in the in-app form.
///
/// The key lives in [FlutterSecureStorage] (encrypted at rest) instead of the
/// Android manifest, because the native Android Maps SDK only reads the key
/// once at process start. Rendering the map through the Maps JavaScript API
/// inside a WebView lets the credential take effect the moment it is saved.
class MapCredentialsStore {
  MapCredentialsStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const String storageKey = 'google_maps_api_key';

  final FlutterSecureStorage _storage;

  Future<String?> read() async {
    final value = await _storage.read(key: storageKey);
    return (value == null || value.trim().isEmpty) ? null : value.trim();
  }

  Future<void> save(String apiKey) =>
      _storage.write(key: storageKey, value: apiKey.trim());

  Future<void> clear() => _storage.delete(key: storageKey);

  /// Asks Google whether the key can actually load the Maps JavaScript API, so
  /// the form can explain a failure instead of rendering a blank map.
  Future<MapKeyCheck> validate(String apiKey) async {
    final key = apiKey.trim();
    if (key.isEmpty) return const MapKeyCheck(false, 'Enter an API key first');

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
          headers: <String, dynamic>{'Host': AppConstants.devHost},
        ),
      );
      final response = await dio.get<dynamic>(
        'https://maps.googleapis.com/maps/api/js',
        queryParameters: {'key': key},
      );

      final body = response.data;
      // The JS API answers HTTP 200 even for a bad key; the verdict lives in
      // the body, so the status code alone proves nothing here.
      final text = body is String ? body : jsonEncode(body);

      if (text.contains('InvalidKeyMapError') ||
          text.contains('REQUEST_DENIED') ||
          text.contains('RefererNotAllowedMapError')) {
        return const MapKeyCheck(
          false,
          'Google rejected this key. Turn on "Maps JavaScript API" for it and '
          'allow the referring app, then retry.',
        );
      }
      if (text.contains('This page can\'t load Google Maps correctly')) {
        return const MapKeyCheck(
          false,
          'Key loaded, but the Maps JavaScript API is not enabled for it.',
        );
      }
      return const MapKeyCheck(true, 'Key accepted by Google');
    } on DioException catch (e) {
      return MapKeyCheck(false, 'Could not reach Google: ${e.message}');
    }
  }
}
