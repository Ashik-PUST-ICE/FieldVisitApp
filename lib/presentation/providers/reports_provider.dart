import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

/// Holds the date-range filter used by the reports screen.
class ReportsFilter {
  final DateTime? from;
  final DateTime? to;
  const ReportsFilter({this.from, this.to});

  Map<String, dynamic> toQuery() {
    final q = <String, dynamic>{};
    if (from != null) q['from'] = _fmt(from!);
    if (to != null) q['to'] = _fmt(to!);
    return q;
  }

  static String _fmt(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  ReportsFilter copyWith({DateTime? from, DateTime? to, bool clearFrom = false, bool clearTo = false}) => ReportsFilter(
        from: clearFrom ? null : (from ?? this.from),
        to: clearTo ? null : (to ?? this.to),
      );
}

final reportsFilterProvider = StateProvider<ReportsFilter>((ref) => const ReportsFilter());

final reportsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(businessApiProvider);
  final filter = ref.watch(reportsFilterProvider);
  final q = filter.toQuery();
  final results = await Future.wait([
    api.visitReport(query: q.isNotEmpty ? q : null),
    api.orderReport(query: q.isNotEmpty ? q : null),
    api.officerPerformance(query: q.isNotEmpty ? q : null),
  ]);
  Map<String, dynamic> data(dynamic response) {
    final payload = Map<String, dynamic>.from(response.data as Map);
    final value = payload['data'];
    return value is Map ? Map<String, dynamic>.from(value) : {'rows': value};
  }
  return {'visits': data(results[0]), 'orders': data(results[1]), 'officers': data(results[2])};
});
