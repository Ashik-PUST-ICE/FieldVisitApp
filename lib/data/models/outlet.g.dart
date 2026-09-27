// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outlet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OutletImpl _$$OutletImplFromJson(Map<String, dynamic> json) => _$OutletImpl(
      id: _outletInt(json['id']) ?? 0,
      name: _outletRequiredString(json['name']),
      code: _outletString(json['code']),
      qrToken: _outletString(json['qr_token']),
      address: _outletString(json['address']),
      latitude: _outletDouble(json['latitude']),
      longitude: _outletDouble(json['longitude']),
      phone: _outletString(json['phone']),
      ownerName: _outletString(json['owner_name']),
      category: json['category'],
      status: _outletString(json['status']),
      geofenceRadius: _outletInt(json['geofence_radius']),
      createdAt: _outletString(json['created_at']),
      updatedAt: _outletString(json['updated_at']),
    );

Map<String, dynamic> _$$OutletImplToJson(_$OutletImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'qr_token': instance.qrToken,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'phone': instance.phone,
      'owner_name': instance.ownerName,
      'category': instance.category,
      'status': instance.status,
      'geofence_radius': instance.geofenceRadius,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
