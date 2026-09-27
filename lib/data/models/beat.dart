import 'package:freezed_annotation/freezed_annotation.dart';

part 'beat.freezed.dart';
part 'beat.g.dart';

@freezed
class Beat with _$Beat {
  const factory Beat({
    required int id,
    required String name,
    String? description,
    String? assignedDate,
    String? status,
    int? userId,
    String? createdAt,
    String? updatedAt,
  }) = _Beat;

  factory Beat.fromJson(Map<String, dynamic> json) => _$BeatFromJson(json);
}
