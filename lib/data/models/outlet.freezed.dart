// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'outlet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Outlet _$OutletFromJson(Map<String, dynamic> json) {
  return _Outlet.fromJson(json);
}

/// @nodoc
mixin _$Outlet {
  @JsonKey(fromJson: _outletInt)
  int get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _outletRequiredString)
  String get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _outletString)
  String? get code => throw _privateConstructorUsedError;
  @JsonKey(name: 'qr_token', fromJson: _outletString)
  String? get qrToken => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _outletString)
  String? get address =>
      throw _privateConstructorUsedError; // Administrative hierarchy, most general first.
  @JsonKey(fromJson: _outletString)
  String? get division => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _outletString)
  String? get district => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _outletString)
  String? get upazila => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _outletString)
  String? get union =>
      throw _privateConstructorUsedError; // Urban counterpart of union: an outlet sits under one or the other,
// never both (rural chain uses union, town chain uses pourashava).
  @JsonKey(fromJson: _outletString)
  String? get pourashava => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _outletString)
  String? get ward => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _outletString)
  String? get village => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _outletString)
  String? get mohalla =>
      throw _privateConstructorUsedError; // Urban leaf under a pourashava ward (mahalla/para). Rural wards use
// `village` above; town wards use this instead (never both).
  @JsonKey(fromJson: _outletDouble)
  double? get latitude => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _outletDouble)
  double? get longitude => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _outletString)
  String? get phone => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_name', fromJson: _outletString)
  String? get ownerName => throw _privateConstructorUsedError;
  dynamic get category => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _outletString)
  String? get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'geofence_radius', fromJson: _outletInt)
  int? get geofenceRadius => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at', fromJson: _outletString)
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at', fromJson: _outletString)
  String? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Outlet to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Outlet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OutletCopyWith<Outlet> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OutletCopyWith<$Res> {
  factory $OutletCopyWith(Outlet value, $Res Function(Outlet) then) =
      _$OutletCopyWithImpl<$Res, Outlet>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: _outletInt) int id,
      @JsonKey(fromJson: _outletRequiredString) String name,
      @JsonKey(fromJson: _outletString) String? code,
      @JsonKey(name: 'qr_token', fromJson: _outletString) String? qrToken,
      @JsonKey(fromJson: _outletString) String? address,
      @JsonKey(fromJson: _outletString) String? division,
      @JsonKey(fromJson: _outletString) String? district,
      @JsonKey(fromJson: _outletString) String? upazila,
      @JsonKey(fromJson: _outletString) String? union,
      @JsonKey(fromJson: _outletString) String? pourashava,
      @JsonKey(fromJson: _outletString) String? ward,
      @JsonKey(fromJson: _outletString) String? village,
      @JsonKey(fromJson: _outletString) String? mohalla,
      @JsonKey(fromJson: _outletDouble) double? latitude,
      @JsonKey(fromJson: _outletDouble) double? longitude,
      @JsonKey(fromJson: _outletString) String? phone,
      @JsonKey(name: 'owner_name', fromJson: _outletString) String? ownerName,
      dynamic category,
      @JsonKey(fromJson: _outletString) String? status,
      @JsonKey(name: 'geofence_radius', fromJson: _outletInt)
      int? geofenceRadius,
      @JsonKey(name: 'created_at', fromJson: _outletString) String? createdAt,
      @JsonKey(name: 'updated_at', fromJson: _outletString) String? updatedAt});
}

/// @nodoc
class _$OutletCopyWithImpl<$Res, $Val extends Outlet>
    implements $OutletCopyWith<$Res> {
  _$OutletCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Outlet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? code = freezed,
    Object? qrToken = freezed,
    Object? address = freezed,
    Object? division = freezed,
    Object? district = freezed,
    Object? upazila = freezed,
    Object? union = freezed,
    Object? pourashava = freezed,
    Object? ward = freezed,
    Object? village = freezed,
    Object? mohalla = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? phone = freezed,
    Object? ownerName = freezed,
    Object? category = freezed,
    Object? status = freezed,
    Object? geofenceRadius = freezed,
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
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
      qrToken: freezed == qrToken
          ? _value.qrToken
          : qrToken // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      division: freezed == division
          ? _value.division
          : division // ignore: cast_nullable_to_non_nullable
              as String?,
      district: freezed == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String?,
      upazila: freezed == upazila
          ? _value.upazila
          : upazila // ignore: cast_nullable_to_non_nullable
              as String?,
      union: freezed == union
          ? _value.union
          : union // ignore: cast_nullable_to_non_nullable
              as String?,
      pourashava: freezed == pourashava
          ? _value.pourashava
          : pourashava // ignore: cast_nullable_to_non_nullable
              as String?,
      ward: freezed == ward
          ? _value.ward
          : ward // ignore: cast_nullable_to_non_nullable
              as String?,
      village: freezed == village
          ? _value.village
          : village // ignore: cast_nullable_to_non_nullable
              as String?,
      mohalla: freezed == mohalla
          ? _value.mohalla
          : mohalla // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerName: freezed == ownerName
          ? _value.ownerName
          : ownerName // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as dynamic,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      geofenceRadius: freezed == geofenceRadius
          ? _value.geofenceRadius
          : geofenceRadius // ignore: cast_nullable_to_non_nullable
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
abstract class _$$OutletImplCopyWith<$Res> implements $OutletCopyWith<$Res> {
  factory _$$OutletImplCopyWith(
          _$OutletImpl value, $Res Function(_$OutletImpl) then) =
      __$$OutletImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: _outletInt) int id,
      @JsonKey(fromJson: _outletRequiredString) String name,
      @JsonKey(fromJson: _outletString) String? code,
      @JsonKey(name: 'qr_token', fromJson: _outletString) String? qrToken,
      @JsonKey(fromJson: _outletString) String? address,
      @JsonKey(fromJson: _outletString) String? division,
      @JsonKey(fromJson: _outletString) String? district,
      @JsonKey(fromJson: _outletString) String? upazila,
      @JsonKey(fromJson: _outletString) String? union,
      @JsonKey(fromJson: _outletString) String? pourashava,
      @JsonKey(fromJson: _outletString) String? ward,
      @JsonKey(fromJson: _outletString) String? village,
      @JsonKey(fromJson: _outletString) String? mohalla,
      @JsonKey(fromJson: _outletDouble) double? latitude,
      @JsonKey(fromJson: _outletDouble) double? longitude,
      @JsonKey(fromJson: _outletString) String? phone,
      @JsonKey(name: 'owner_name', fromJson: _outletString) String? ownerName,
      dynamic category,
      @JsonKey(fromJson: _outletString) String? status,
      @JsonKey(name: 'geofence_radius', fromJson: _outletInt)
      int? geofenceRadius,
      @JsonKey(name: 'created_at', fromJson: _outletString) String? createdAt,
      @JsonKey(name: 'updated_at', fromJson: _outletString) String? updatedAt});
}

/// @nodoc
class __$$OutletImplCopyWithImpl<$Res>
    extends _$OutletCopyWithImpl<$Res, _$OutletImpl>
    implements _$$OutletImplCopyWith<$Res> {
  __$$OutletImplCopyWithImpl(
      _$OutletImpl _value, $Res Function(_$OutletImpl) _then)
      : super(_value, _then);

  /// Create a copy of Outlet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? code = freezed,
    Object? qrToken = freezed,
    Object? address = freezed,
    Object? division = freezed,
    Object? district = freezed,
    Object? upazila = freezed,
    Object? union = freezed,
    Object? pourashava = freezed,
    Object? ward = freezed,
    Object? village = freezed,
    Object? mohalla = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? phone = freezed,
    Object? ownerName = freezed,
    Object? category = freezed,
    Object? status = freezed,
    Object? geofenceRadius = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$OutletImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
      qrToken: freezed == qrToken
          ? _value.qrToken
          : qrToken // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      division: freezed == division
          ? _value.division
          : division // ignore: cast_nullable_to_non_nullable
              as String?,
      district: freezed == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String?,
      upazila: freezed == upazila
          ? _value.upazila
          : upazila // ignore: cast_nullable_to_non_nullable
              as String?,
      union: freezed == union
          ? _value.union
          : union // ignore: cast_nullable_to_non_nullable
              as String?,
      pourashava: freezed == pourashava
          ? _value.pourashava
          : pourashava // ignore: cast_nullable_to_non_nullable
              as String?,
      ward: freezed == ward
          ? _value.ward
          : ward // ignore: cast_nullable_to_non_nullable
              as String?,
      village: freezed == village
          ? _value.village
          : village // ignore: cast_nullable_to_non_nullable
              as String?,
      mohalla: freezed == mohalla
          ? _value.mohalla
          : mohalla // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerName: freezed == ownerName
          ? _value.ownerName
          : ownerName // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as dynamic,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      geofenceRadius: freezed == geofenceRadius
          ? _value.geofenceRadius
          : geofenceRadius // ignore: cast_nullable_to_non_nullable
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
class _$OutletImpl implements _Outlet {
  const _$OutletImpl(
      {@JsonKey(fromJson: _outletInt) required this.id,
      @JsonKey(fromJson: _outletRequiredString) required this.name,
      @JsonKey(fromJson: _outletString) this.code,
      @JsonKey(name: 'qr_token', fromJson: _outletString) this.qrToken,
      @JsonKey(fromJson: _outletString) this.address,
      @JsonKey(fromJson: _outletString) this.division,
      @JsonKey(fromJson: _outletString) this.district,
      @JsonKey(fromJson: _outletString) this.upazila,
      @JsonKey(fromJson: _outletString) this.union,
      @JsonKey(fromJson: _outletString) this.pourashava,
      @JsonKey(fromJson: _outletString) this.ward,
      @JsonKey(fromJson: _outletString) this.village,
      @JsonKey(fromJson: _outletString) this.mohalla,
      @JsonKey(fromJson: _outletDouble) this.latitude,
      @JsonKey(fromJson: _outletDouble) this.longitude,
      @JsonKey(fromJson: _outletString) this.phone,
      @JsonKey(name: 'owner_name', fromJson: _outletString) this.ownerName,
      this.category,
      @JsonKey(fromJson: _outletString) this.status,
      @JsonKey(name: 'geofence_radius', fromJson: _outletInt)
      this.geofenceRadius,
      @JsonKey(name: 'created_at', fromJson: _outletString) this.createdAt,
      @JsonKey(name: 'updated_at', fromJson: _outletString) this.updatedAt});

  factory _$OutletImpl.fromJson(Map<String, dynamic> json) =>
      _$$OutletImplFromJson(json);

  @override
  @JsonKey(fromJson: _outletInt)
  final int id;
  @override
  @JsonKey(fromJson: _outletRequiredString)
  final String name;
  @override
  @JsonKey(fromJson: _outletString)
  final String? code;
  @override
  @JsonKey(name: 'qr_token', fromJson: _outletString)
  final String? qrToken;
  @override
  @JsonKey(fromJson: _outletString)
  final String? address;
// Administrative hierarchy, most general first.
  @override
  @JsonKey(fromJson: _outletString)
  final String? division;
  @override
  @JsonKey(fromJson: _outletString)
  final String? district;
  @override
  @JsonKey(fromJson: _outletString)
  final String? upazila;
  @override
  @JsonKey(fromJson: _outletString)
  final String? union;
// Urban counterpart of union: an outlet sits under one or the other,
// never both (rural chain uses union, town chain uses pourashava).
  @override
  @JsonKey(fromJson: _outletString)
  final String? pourashava;
  @override
  @JsonKey(fromJson: _outletString)
  final String? ward;
  @override
  @JsonKey(fromJson: _outletString)
  final String? village;
  @override
  @JsonKey(fromJson: _outletString)
  final String? mohalla;
// Urban leaf under a pourashava ward (mahalla/para). Rural wards use
// `village` above; town wards use this instead (never both).
  @override
  @JsonKey(fromJson: _outletDouble)
  final double? latitude;
  @override
  @JsonKey(fromJson: _outletDouble)
  final double? longitude;
  @override
  @JsonKey(fromJson: _outletString)
  final String? phone;
  @override
  @JsonKey(name: 'owner_name', fromJson: _outletString)
  final String? ownerName;
  @override
  final dynamic category;
  @override
  @JsonKey(fromJson: _outletString)
  final String? status;
  @override
  @JsonKey(name: 'geofence_radius', fromJson: _outletInt)
  final int? geofenceRadius;
  @override
  @JsonKey(name: 'created_at', fromJson: _outletString)
  final String? createdAt;
  @override
  @JsonKey(name: 'updated_at', fromJson: _outletString)
  final String? updatedAt;

  @override
  String toString() {
    return 'Outlet(id: $id, name: $name, code: $code, qrToken: $qrToken, address: $address, division: $division, district: $district, upazila: $upazila, union: $union, pourashava: $pourashava, ward: $ward, village: $village, mohalla: $mohalla, latitude: $latitude, longitude: $longitude, phone: $phone, ownerName: $ownerName, category: $category, status: $status, geofenceRadius: $geofenceRadius, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OutletImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.qrToken, qrToken) || other.qrToken == qrToken) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.division, division) ||
                other.division == division) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.upazila, upazila) || other.upazila == upazila) &&
            (identical(other.union, union) || other.union == union) &&
            (identical(other.pourashava, pourashava) ||
                other.pourashava == pourashava) &&
            (identical(other.ward, ward) || other.ward == ward) &&
            (identical(other.village, village) || other.village == village) &&
            (identical(other.mohalla, mohalla) || other.mohalla == mohalla) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.ownerName, ownerName) ||
                other.ownerName == ownerName) &&
            const DeepCollectionEquality().equals(other.category, category) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.geofenceRadius, geofenceRadius) ||
                other.geofenceRadius == geofenceRadius) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        code,
        qrToken,
        address,
        division,
        district,
        upazila,
        union,
        pourashava,
        ward,
        village,
        mohalla,
        latitude,
        longitude,
        phone,
        ownerName,
        const DeepCollectionEquality().hash(category),
        status,
        geofenceRadius,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of Outlet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OutletImplCopyWith<_$OutletImpl> get copyWith =>
      __$$OutletImplCopyWithImpl<_$OutletImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OutletImplToJson(
      this,
    );
  }
}

abstract class _Outlet implements Outlet {
  const factory _Outlet(
      {@JsonKey(fromJson: _outletInt) required final int id,
      @JsonKey(fromJson: _outletRequiredString) required final String name,
      @JsonKey(fromJson: _outletString) final String? code,
      @JsonKey(name: 'qr_token', fromJson: _outletString) final String? qrToken,
      @JsonKey(fromJson: _outletString) final String? address,
      @JsonKey(fromJson: _outletString) final String? division,
      @JsonKey(fromJson: _outletString) final String? district,
      @JsonKey(fromJson: _outletString) final String? upazila,
      @JsonKey(fromJson: _outletString) final String? union,
      @JsonKey(fromJson: _outletString) final String? pourashava,
      @JsonKey(fromJson: _outletString) final String? ward,
      @JsonKey(fromJson: _outletString) final String? village,
      @JsonKey(fromJson: _outletString) final String? mohalla,
      @JsonKey(fromJson: _outletDouble) final double? latitude,
      @JsonKey(fromJson: _outletDouble) final double? longitude,
      @JsonKey(fromJson: _outletString) final String? phone,
      @JsonKey(name: 'owner_name', fromJson: _outletString)
      final String? ownerName,
      final dynamic category,
      @JsonKey(fromJson: _outletString) final String? status,
      @JsonKey(name: 'geofence_radius', fromJson: _outletInt)
      final int? geofenceRadius,
      @JsonKey(name: 'created_at', fromJson: _outletString)
      final String? createdAt,
      @JsonKey(name: 'updated_at', fromJson: _outletString)
      final String? updatedAt}) = _$OutletImpl;

  factory _Outlet.fromJson(Map<String, dynamic> json) = _$OutletImpl.fromJson;

  @override
  @JsonKey(fromJson: _outletInt)
  int get id;
  @override
  @JsonKey(fromJson: _outletRequiredString)
  String get name;
  @override
  @JsonKey(fromJson: _outletString)
  String? get code;
  @override
  @JsonKey(name: 'qr_token', fromJson: _outletString)
  String? get qrToken;
  @override
  @JsonKey(fromJson: _outletString)
  String? get address; // Administrative hierarchy, most general first.
  @override
  @JsonKey(fromJson: _outletString)
  String? get division;
  @override
  @JsonKey(fromJson: _outletString)
  String? get district;
  @override
  @JsonKey(fromJson: _outletString)
  String? get upazila;
  @override
  @JsonKey(fromJson: _outletString)
  String?
      get union; // Urban counterpart of union: an outlet sits under one or the other,
// never both (rural chain uses union, town chain uses pourashava).
  @override
  @JsonKey(fromJson: _outletString)
  String? get pourashava;
  @override
  @JsonKey(fromJson: _outletString)
  String? get ward;
  @override
  @JsonKey(fromJson: _outletString)
  String? get village;
  @override
  @JsonKey(fromJson: _outletString)
  String?
      get mohalla; // Urban leaf under a pourashava ward (mahalla/para). Rural wards use
// `village` above; town wards use this instead (never both).
  @override
  @JsonKey(fromJson: _outletDouble)
  double? get latitude;
  @override
  @JsonKey(fromJson: _outletDouble)
  double? get longitude;
  @override
  @JsonKey(fromJson: _outletString)
  String? get phone;
  @override
  @JsonKey(name: 'owner_name', fromJson: _outletString)
  String? get ownerName;
  @override
  dynamic get category;
  @override
  @JsonKey(fromJson: _outletString)
  String? get status;
  @override
  @JsonKey(name: 'geofence_radius', fromJson: _outletInt)
  int? get geofenceRadius;
  @override
  @JsonKey(name: 'created_at', fromJson: _outletString)
  String? get createdAt;
  @override
  @JsonKey(name: 'updated_at', fromJson: _outletString)
  String? get updatedAt;

  /// Create a copy of Outlet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OutletImplCopyWith<_$OutletImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
