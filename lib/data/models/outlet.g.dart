// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outlet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OutletImpl _$$OutletImplFromJson(Map<String, dynamic> json) => _$OutletImpl(
      id: _outletInt(json['id']),
      name: _outletRequiredString(json['name']),
      code: _outletString(json['code']),
      qrToken: _outletString(json['qr_token']),
      address: _outletString(json['address']),
      division: _outletString(json['division']),
      district: _outletString(json['district']),
      upazila: _outletString(json['upazila']),
      union: _outletString(json['union']),
      ward: _outletString(json['ward']),
      village: _outletString(json['village']),
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
      'division': instance.division,
      'district': instance.district,
      'upazila': instance.upazila,
      'union': instance.union,
      'ward': instance.ward,
      'village': instance.village,
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
