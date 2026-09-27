// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outlet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OutletImpl _$$OutletImplFromJson(Map<String, dynamic> json) => _$OutletImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      qrToken: json['qrToken'] as String?,
      qrStatus: json['qrStatus'] as String?,
      status: json['status'] as String?,
      geofenceRadius: (json['geofenceRadius'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$$OutletImplToJson(_$OutletImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'phone': instance.phone,
      'email': instance.email,
      'qrToken': instance.qrToken,
      'qrStatus': instance.qrStatus,
      'status': instance.status,
      'geofenceRadius': instance.geofenceRadius,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
