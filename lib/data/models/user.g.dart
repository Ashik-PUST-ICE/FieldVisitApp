// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      image: json['image'] as String?,
      uniqueId: json['uniqueId'] as String,
      status: (json['status'] as num).toInt(),
      lastLoginAt: json['lastLoginAt'] as String?,
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
      'image': instance.image,
      'uniqueId': instance.uniqueId,
      'status': instance.status,
      'lastLoginAt': instance.lastLoginAt,
      'roles': instance.roles,
      'permissions': instance.permissions,
    };
