// Freezed reads JsonKey from factory parameters and applies it to generated fields.
// The analyzer flags that annotation location even though code generation supports it.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'outlet.freezed.dart';
part 'outlet.g.dart';

double? _outletDouble(Object? value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  return value is num ? value.toDouble() : double.tryParse(value.toString());
}

int? _outletInt(Object? value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  return value is num ? value.toInt() : int.tryParse(value.toString());
}

String? _outletString(Object? value) => value?.toString();

String _outletRequiredString(Object? value) => value?.toString() ?? '';

@freezed
class Outlet with _$Outlet {
  const factory Outlet({
    @JsonKey(fromJson: _outletInt) required int id,
    @JsonKey(fromJson: _outletRequiredString) required String name,
    @JsonKey(fromJson: _outletString) String? code,
    @JsonKey(name: 'qr_token', fromJson: _outletString) String? qrToken,
    @JsonKey(fromJson: _outletString) String? address,
    @JsonKey(fromJson: _outletDouble) double? latitude,
    @JsonKey(fromJson: _outletDouble) double? longitude,
    @JsonKey(fromJson: _outletString) String? phone,
    @JsonKey(name: 'owner_name', fromJson: _outletString) String? ownerName,
    dynamic category,
    @JsonKey(fromJson: _outletString) String? status,
    @JsonKey(name: 'geofence_radius', fromJson: _outletInt) int? geofenceRadius,
    @JsonKey(name: 'created_at', fromJson: _outletString) String? createdAt,
    @JsonKey(name: 'updated_at', fromJson: _outletString) String? updatedAt,
  }) = _Outlet;

  factory Outlet.fromJson(Map<String, dynamic> json) => _$OutletFromJson(json);
}
