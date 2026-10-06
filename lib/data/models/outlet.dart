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

// `id` is a required, non-nullable int, so this returns a non-nullable int.
// It previously returned `int?`, which json_serializable rejects when
// regenerating ("return type `int?` is not compatible with field type `int`").
int _outletInt(Object? value) {
  if (value == null || value.toString().trim().isEmpty) return 0;
  return value is num ? value.toInt() : int.tryParse(value.toString()) ?? 0;
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
    // Administrative hierarchy, most general first.
    @JsonKey(fromJson: _outletString) String? division,
    @JsonKey(fromJson: _outletString) String? district,
    @JsonKey(fromJson: _outletString) String? upazila,
    @JsonKey(fromJson: _outletString) String? union,
    // Urban counterpart of union: an outlet sits under one or the other,
    // never both (rural chain uses union, town chain uses pourashava).
    @JsonKey(fromJson: _outletString) String? pourashava,
    @JsonKey(fromJson: _outletString) String? ward,
    @JsonKey(fromJson: _outletString) String? village,
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

/// Convenience formatting for an [Outlet].
///
/// These live in an extension because a `@freezed` class may only declare
/// getters that delegate to the generated private constructor.
extension OutletLocation on Outlet {
  /// Human-readable administrative location, most general first.
  ///
  /// e.g. "Gulshan Para, Ward 12, Gulshan, Dhaka, Dhaka". Shown on the QR card
  /// so a field officer can read the location straight off the screen instead
  /// of guessing from a map pin.
  String get locationLine {
    final parts = <String?>[
      village,
      ward,
      pourashava,
      upazila,
      union,
      district,
      division,
    ].where((p) => p != null && p.trim().isNotEmpty).toSet().toList();
    return parts.join(', ');
  }

  /// Street address plus the administrative hierarchy on one line.
  String get fullAddress {
    final admin = locationLine;
    final street = address?.trim() ?? '';
    if (street.isEmpty) return admin;
    if (admin.isEmpty) return street;
    return '$street, $admin';
  }
}
