import 'package:freezed_annotation/freezed_annotation.dart';

part 'beat.freezed.dart';
part 'beat.g.dart';

@freezed
class Beat with _$Beat {
  const factory Beat({
    required int id,
    required String name,
    String? code,
    @JsonKey(name: 'assigned_user_id') int? assignedUserId,
    String? date,
    String? status,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _Beat;

  factory Beat.fromJson(Map<String, dynamic> json) => _$BeatFromJson(json);
}
