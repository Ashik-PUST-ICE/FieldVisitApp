// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BeatImpl _$$BeatImplFromJson(Map<String, dynamic> json) => _$BeatImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      code: json['code'] as String?,
      assignedUserId: (json['assigned_user_id'] as num?)?.toInt(),
      date: json['date'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$$BeatImplToJson(_$BeatImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'assigned_user_id': instance.assignedUserId,
      'date': instance.date,
      'status': instance.status,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
