import 'package:freezed_annotation/freezed_annotation.dart';

part 'visit.freezed.dart';
part 'visit.g.dart';

@freezed
class Visit with _$Visit {
  const factory Visit({
    required int id,
    required int outletId,
    required int userId,
    String? status,
    String? checkInTime,
    String? checkOutTime,
    double? latitude,
    double? longitude,
    String? notes,
    String? syncStatus,
    String? createdAt,
    String? updatedAt,
  }) = _Visit;

  factory Visit.fromJson(Map<String, dynamic> json) => _$VisitFromJson(json);
}
