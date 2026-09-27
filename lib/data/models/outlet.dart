import 'package:freezed_annotation/freezed_annotation.dart';

part 'outlet.freezed.dart';
part 'outlet.g.dart';

@freezed
class Outlet with _$Outlet {
  const factory Outlet({
    required int id,
    required String name,
    String? code,
    @JsonKey(name: 'qr_token') String? qrToken,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    @JsonKey(name: 'owner_name') String? ownerName,
    dynamic category,
    String? status,
    @JsonKey(name: 'geofence_radius') int? geofenceRadius,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _Outlet;

  factory Outlet.fromJson(Map<String, dynamic> json) => _$OutletFromJson(json);
}
