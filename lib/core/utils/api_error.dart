import 'package:dio/dio.dart';

/// Extracts a human-readable message from a Dio error response.
///
/// Backend convention (`ApiResponse`) wraps failures as
/// `{ success:false, message:'...', errors:{field:[...]} }`.
/// We surface `message` first, then the first field error, so the sheet
/// shows e.g. "The name has already been taken." instead of a raw
/// `DioException [...]` dump.
String friendlyApiError(Object e, {String fallback = 'Something went wrong'}) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = (errors.values.first as List?)?.firstOrNull;
        if (first != null) return first.toString();
      }
      final message = data['message'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    }
  }
  final text = e.toString();
  const prefix = 'DioException [bad response]: ';
  if (text.startsWith(prefix)) return text.substring(prefix.length).trim();
  return fallback;
}
