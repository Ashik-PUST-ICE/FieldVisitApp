import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    @JsonKey(name: 'auth_id') required int id,
    @JsonKey(name: 'full_name') required String fullName,
    required String email,
    String? image,
    @JsonKey(name: 'unique_id') required String uniqueId,
    required int status,
    @JsonKey(name: 'last_login_at') String? lastLoginAt,
    List<String>? roles,
    List<String>? permissions,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
