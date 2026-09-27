import 'package:freezed_annotation/freezed_annotation.dart';

part 'outlet.freezed.dart';
part 'outlet.g.dart';

@freezed
class Outlet with _$Outlet {
  const factory Outlet({
    required int id,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? phone,
    String? email,
    String? qrToken,
    String? qrStatus,
    String? status,
    int? geofenceRadius,
    String? createdAt,
    String? updatedAt,
  }) = _Outlet;

  factory Outlet.fromJson(Map<String, dynamic> json) => _$OutletFromJson(json);
}
