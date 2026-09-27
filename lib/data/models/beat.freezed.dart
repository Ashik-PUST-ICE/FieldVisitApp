// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'beat.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Beat _$BeatFromJson(Map<String, dynamic> json) {
  return _Beat.fromJson(json);
}

/// @nodoc
mixin _$Beat {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get assignedDate => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  int? get userId => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  String? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Beat to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Beat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BeatCopyWith<Beat> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BeatCopyWith<$Res> {
  factory $BeatCopyWith(Beat value, $Res Function(Beat) then) =
      _$BeatCopyWithImpl<$Res, Beat>;
  @useResult
  $Res call(
      {int id,
      String name,
      String? description,
      String? assignedDate,
      String? status,
      int? userId,
      String? createdAt,
      String? updatedAt});
}

/// @nodoc
class _$BeatCopyWithImpl<$Res, $Val extends Beat>
    implements $BeatCopyWith<$Res> {
  _$BeatCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Beat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? assignedDate = freezed,
    Object? status = freezed,
    Object? userId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedDate: freezed == assignedDate
          ? _value.assignedDate
          : assignedDate // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int?,
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
abstract class _$$BeatImplCopyWith<$Res> implements $BeatCopyWith<$Res> {
  factory _$$BeatImplCopyWith(
          _$BeatImpl value, $Res Function(_$BeatImpl) then) =
      __$$BeatImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String? description,
      String? assignedDate,
      String? status,
      int? userId,
      String? createdAt,
      String? updatedAt});
}

/// @nodoc
class __$$BeatImplCopyWithImpl<$Res>
    extends _$BeatCopyWithImpl<$Res, _$BeatImpl>
    implements _$$BeatImplCopyWith<$Res> {
  __$$BeatImplCopyWithImpl(_$BeatImpl _value, $Res Function(_$BeatImpl) _then)
      : super(_value, _then);

  /// Create a copy of Beat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? assignedDate = freezed,
    Object? status = freezed,
    Object? userId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$BeatImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedDate: freezed == assignedDate
          ? _value.assignedDate
          : assignedDate // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int?,
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
class _$BeatImpl implements _Beat {
  const _$BeatImpl(
      {required this.id,
      required this.name,
      this.description,
      this.assignedDate,
      this.status,
      this.userId,
      this.createdAt,
      this.updatedAt});

  factory _$BeatImpl.fromJson(Map<String, dynamic> json) =>
      _$$BeatImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String? assignedDate;
  @override
  final String? status;
  @override
  final int? userId;
  @override
  final String? createdAt;
  @override
  final String? updatedAt;

  @override
  String toString() {
    return 'Beat(id: $id, name: $name, description: $description, assignedDate: $assignedDate, status: $status, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BeatImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.assignedDate, assignedDate) ||
                other.assignedDate == assignedDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description,
      assignedDate, status, userId, createdAt, updatedAt);

  /// Create a copy of Beat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BeatImplCopyWith<_$BeatImpl> get copyWith =>
      __$$BeatImplCopyWithImpl<_$BeatImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BeatImplToJson(
      this,
    );
  }
}

abstract class _Beat implements Beat {
  const factory _Beat(
      {required final int id,
      required final String name,
      final String? description,
      final String? assignedDate,
      final String? status,
      final int? userId,
      final String? createdAt,
      final String? updatedAt}) = _$BeatImpl;

  factory _Beat.fromJson(Map<String, dynamic> json) = _$BeatImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String? get assignedDate;
  @override
  String? get status;
  @override
  int? get userId;
  @override
  String? get createdAt;
  @override
  String? get updatedAt;

  /// Create a copy of Beat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BeatImplCopyWith<_$BeatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
