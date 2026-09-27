// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VisitImpl _$$VisitImplFromJson(Map<String, dynamic> json) => _$VisitImpl(
      id: (json['id'] as num).toInt(),
      outletId: (json['outletId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      status: json['status'] as String?,
      checkInTime: json['checkInTime'] as String?,
      checkOutTime: json['checkOutTime'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      syncStatus: json['syncStatus'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$$VisitImplToJson(_$VisitImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'outletId': instance.outletId,
      'userId': instance.userId,
      'status': instance.status,
      'checkInTime': instance.checkInTime,
      'checkOutTime': instance.checkOutTime,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'notes': instance.notes,
      'syncStatus': instance.syncStatus,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
