// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: (json['auth_id'] as num).toInt(),
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      image: json['image'] as String?,
      uniqueId: json['unique_id'] as String,
      status: (json['status'] as num).toInt(),
      lastLoginAt: json['last_login_at'] as String?,
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'auth_id': instance.id,
      'full_name': instance.fullName,
      'email': instance.email,
      'image': instance.image,
      'unique_id': instance.uniqueId,
      'status': instance.status,
      'last_login_at': instance.lastLoginAt,
      'roles': instance.roles,
      'permissions': instance.permissions,
    };
