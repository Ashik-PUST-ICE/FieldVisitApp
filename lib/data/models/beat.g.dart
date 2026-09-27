// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BeatImpl _$$BeatImplFromJson(Map<String, dynamic> json) => _$BeatImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      assignedDate: json['assignedDate'] as String?,
      status: json['status'] as String?,
      userId: (json['userId'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$$BeatImplToJson(_$BeatImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'assignedDate': instance.assignedDate,
      'status': instance.status,
      'userId': instance.userId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
