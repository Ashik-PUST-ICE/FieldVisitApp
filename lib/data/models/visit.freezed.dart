// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'visit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Visit _$VisitFromJson(Map<String, dynamic> json) {
  return _Visit.fromJson(json);
}

/// @nodoc
mixin _$Visit {
  int get id => throw _privateConstructorUsedError;
  int get outletId => throw _privateConstructorUsedError;
  int get userId => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  String? get checkInTime => throw _privateConstructorUsedError;
  String? get checkOutTime => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get syncStatus => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  String? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Visit to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Visit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VisitCopyWith<Visit> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VisitCopyWith<$Res> {
  factory $VisitCopyWith(Visit value, $Res Function(Visit) then) =
      _$VisitCopyWithImpl<$Res, Visit>;
  @useResult
  $Res call(
      {int id,
      int outletId,
      int userId,
      String? status,
      String? checkInTime,
      String? checkOutTime,
      double? latitude,
      double? longitude,
      String? notes,
      String? syncStatus,
      String? createdAt,
      String? updatedAt});
}

/// @nodoc
class _$VisitCopyWithImpl<$Res, $Val extends Visit>
    implements $VisitCopyWith<$Res> {
  _$VisitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Visit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? outletId = null,
    Object? userId = null,
    Object? status = freezed,
    Object? checkInTime = freezed,
    Object? checkOutTime = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? notes = freezed,
    Object? syncStatus = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      outletId: null == outletId
          ? _value.outletId
          : outletId // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      checkInTime: freezed == checkInTime
          ? _value.checkInTime
          : checkInTime // ignore: cast_nullable_to_non_nullable
              as String?,
      checkOutTime: freezed == checkOutTime
          ? _value.checkOutTime
          : checkOutTime // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      syncStatus: freezed == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VisitImplCopyWith<$Res> implements $VisitCopyWith<$Res> {
  factory _$$VisitImplCopyWith(
          _$VisitImpl value, $Res Function(_$VisitImpl) then) =
      __$$VisitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int outletId,
      int userId,
      String? status,
      String? checkInTime,
      String? checkOutTime,
      double? latitude,
      double? longitude,
      String? notes,
      String? syncStatus,
      String? createdAt,
      String? updatedAt});
}

/// @nodoc
class __$$VisitImplCopyWithImpl<$Res>
    extends _$VisitCopyWithImpl<$Res, _$VisitImpl>
    implements _$$VisitImplCopyWith<$Res> {
  __$$VisitImplCopyWithImpl(
      _$VisitImpl _value, $Res Function(_$VisitImpl) _then)
      : super(_value, _then);

  /// Create a copy of Visit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? outletId = null,
    Object? userId = null,
    Object? status = freezed,
    Object? checkInTime = freezed,
    Object? checkOutTime = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? notes = freezed,
    Object? syncStatus = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$VisitImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      outletId: null == outletId
          ? _value.outletId
          : outletId // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      checkInTime: freezed == checkInTime
          ? _value.checkInTime
          : checkInTime // ignore: cast_nullable_to_non_nullable
              as String?,
      checkOutTime: freezed == checkOutTime
          ? _value.checkOutTime
          : checkOutTime // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      syncStatus: freezed == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VisitImpl implements _Visit {
  const _$VisitImpl(
      {required this.id,
      required this.outletId,
      required this.userId,
      this.status,
      this.checkInTime,
      this.checkOutTime,
      this.latitude,
      this.longitude,
      this.notes,
      this.syncStatus,
      this.createdAt,
      this.updatedAt});

  factory _$VisitImpl.fromJson(Map<String, dynamic> json) =>
      _$$VisitImplFromJson(json);

  @override
  final int id;
  @override
  final int outletId;
  @override
  final int userId;
  @override
  final String? status;
  @override
  final String? checkInTime;
  @override
  final String? checkOutTime;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  final String? notes;
  @override
  final String? syncStatus;
  @override
  final String? createdAt;
  @override
  final String? updatedAt;

  @override
  String toString() {
    return 'Visit(id: $id, outletId: $outletId, userId: $userId, status: $status, checkInTime: $checkInTime, checkOutTime: $checkOutTime, latitude: $latitude, longitude: $longitude, notes: $notes, syncStatus: $syncStatus, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VisitImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.outletId, outletId) ||
                other.outletId == outletId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.checkInTime, checkInTime) ||
                other.checkInTime == checkInTime) &&
            (identical(other.checkOutTime, checkOutTime) ||
                other.checkOutTime == checkOutTime) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      outletId,
      userId,
      status,
      checkInTime,
      checkOutTime,
      latitude,
      longitude,
      notes,
      syncStatus,
      createdAt,
      updatedAt);

  /// Create a copy of Visit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VisitImplCopyWith<_$VisitImpl> get copyWith =>
      __$$VisitImplCopyWithImpl<_$VisitImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VisitImplToJson(
      this,
    );
  }
}

abstract class _Visit implements Visit {
  const factory _Visit(
      {required final int id,
      required final int outletId,
      required final int userId,
      final String? status,
      final String? checkInTime,
      final String? checkOutTime,
      final double? latitude,
      final double? longitude,
      final String? notes,
      final String? syncStatus,
      final String? createdAt,
      final String? updatedAt}) = _$VisitImpl;

  factory _Visit.fromJson(Map<String, dynamic> json) = _$VisitImpl.fromJson;

  @override
  int get id;
  @override
  int get outletId;
  @override
  int get userId;
  @override
  String? get status;
  @override
  String? get checkInTime;
  @override
  String? get checkOutTime;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  String? get notes;
  @override
  String? get syncStatus;
  @override
  String? get createdAt;
  @override
  String? get updatedAt;

  /// Create a copy of Visit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VisitImplCopyWith<_$VisitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
