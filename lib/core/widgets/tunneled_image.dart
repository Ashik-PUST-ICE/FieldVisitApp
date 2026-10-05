import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:field_visit_app/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// An [ImageProvider] that fetches through the `adb reverse` tunnel and sends
/// the `Host` header the local Herd/Valet server expects.
///
/// Why this exists: the device reaches the laptop over `adb reverse tcp:8080
/// tcp:80`, so it must connect to `127.0.0.1:8080`. A plain [NetworkImage]
/// then sends `Host: 127.0.0.1:8080`, and Herd/Valet - which routes by Host -
/// answers **404**. Stripping the port (`Host: 127.0.0.1`) resolves the site
/// from the URI path instead and returns 200. Only an explicit header can do
/// that, and [NetworkImage] exposes no hook for custom headers.
///
/// The API layer already solves this by overriding `Host` in [ApiClient]'s
/// `BaseOptions`; this provider does the same for images so both stay
/// consistent.
///
/// TODO(prod): drop this and use plain `NetworkImage` once media is served
/// from a real public domain.
class TunneledNetworkImage extends ImageProvider<TunneledNetworkImage> {
  final String url;

  const TunneledNetworkImage(this.url);

  @override
  Future<TunneledNetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<TunneledNetworkImage>(this);

  @override
  ImageStreamCompleter loadImage(
    TunneledNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1,
      debugLabel: key.url,
      informationCollector: () sync* {
        yield ErrorDescription(
            'Could not load image over the ADB tunnel: $url');
        yield ErrorDescription(_lastError.value ?? 'no further details');
      },
    );
  }

  /// Kept so the error collector can explain *why* a load failed; Flutter's
  /// default reporting swallows the Dio message.
  static final ValueNotifier<String?> _lastError = ValueNotifier<String?>(null);

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    try {
      final dio = Dio(
        BaseOptions(
          responseType: ResponseType.bytes,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: <String, dynamic>{
            'Host': AppConstants.devHost,
            'Accept': 'image/*',
          },
          // Turn any non-2xx into a thrown error so the widget falls back to
          // initials instead of rendering a broken image.
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      final response = await dio.get<List<int>>(url);
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw StateError('Empty image response (${response.statusCode})');
      }

      final bytes = data is Uint8List ? data : Uint8List.fromList(data);
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      _lastError.value = null;
      return decode(buffer);
    } catch (e) {
      _lastError.value = e.toString();
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TunneledNetworkImage && other.url == url);

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'TunneledNetworkImage("$url")';
}
