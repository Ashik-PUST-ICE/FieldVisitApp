import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/business_api.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

enum KpiPeriod { today, thisWeek, thisMonth }

extension KpiPeriodExt on KpiPeriod {
  String get value {
    switch (this) {
      case KpiPeriod.today:
        return 'today';
      case KpiPeriod.thisWeek:
        return 'this_week';
      case KpiPeriod.thisMonth:
        return 'this_month';
    }
  }

  String get label {
    switch (this) {
      case KpiPeriod.today:
        return 'Today';
      case KpiPeriod.thisWeek:
        return 'This Week';
      case KpiPeriod.thisMonth:
        return 'This Month';
    }
  }
}

final kpiPeriodProvider = StateProvider<KpiPeriod>((ref) => KpiPeriod.today);

class KpiData {
  final String period;
  final String periodType;
  final String startDate;
  final String endDate;

  // Target
  final int? targetId;
  final String targetTitle;
  final int visitTarget;
  final double salesTarget;
  final double coverageTarget;
  final double strikeRateTarget;

  // Actual
  final int totalVisits;
  final int completedVisits;
  final int verifiedVisits;
  final int ordersCount;
  final double ordersAmount;
  final int totalAssignedOutlets;
  final int uniqueOutletsVisited;
  final double coveragePercentage;
  final double strikeRate;
  final double avgOrderValue;

  // Achievement
  final double visitPercentage;
  final double salesPercentage;
  final double coverageAchievement;
  final double overallScore;
  final String performanceGrade;

  // Leaderboard
  final List<Map<String, dynamic>> leaderboard;

  const KpiData({
    required this.period,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    this.targetId,
    required this.targetTitle,
    required this.visitTarget,
    required this.salesTarget,
    required this.coverageTarget,
    required this.strikeRateTarget,
    required this.totalVisits,
    required this.completedVisits,
    required this.verifiedVisits,
    required this.ordersCount,
    required this.ordersAmount,
    required this.totalAssignedOutlets,
    required this.uniqueOutletsVisited,
    required this.coveragePercentage,
    required this.strikeRate,
    required this.avgOrderValue,
    required this.visitPercentage,
    required this.salesPercentage,
    required this.coverageAchievement,
    required this.overallScore,
    required this.performanceGrade,
    required this.leaderboard,
  });

  factory KpiData.fromJson(Map<String, dynamic> json) {
    final target = Map<String, dynamic>.from(json['target'] as Map? ?? {});
    final actual = Map<String, dynamic>.from(json['actual'] as Map? ?? {});
    final achievement =
        Map<String, dynamic>.from(json['achievement'] as Map? ?? {});
    final rawLeaders = json['leaderboard'] as List? ?? [];

    return KpiData(
      period: json['period']?.toString() ?? 'today',
      periodType: json['period_type']?.toString() ?? 'daily',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      targetId: (target['id'] as num?)?.toInt(),
      targetTitle: target['title']?.toString() ?? 'Performance Target',
      visitTarget: (target['visit_target'] as num?)?.toInt() ?? 15,
      salesTarget: (target['sales_target'] as num?)?.toDouble() ?? 50000.0,
      coverageTarget: (target['coverage_target'] as num?)?.toDouble() ?? 85.0,
      strikeRateTarget:
          (target['strike_rate_target'] as num?)?.toDouble() ?? 65.0,
      totalVisits: (actual['total_visits'] as num?)?.toInt() ?? 0,
      completedVisits: (actual['completed_visits'] as num?)?.toInt() ?? 0,
      verifiedVisits: (actual['verified_visits'] as num?)?.toInt() ?? 0,
      ordersCount: (actual['orders_count'] as num?)?.toInt() ?? 0,
      ordersAmount: (actual['orders_amount'] as num?)?.toDouble() ?? 0.0,
      totalAssignedOutlets:
          (actual['total_assigned_outlets'] as num?)?.toInt() ?? 0,
      uniqueOutletsVisited:
          (actual['unique_outlets_visited'] as num?)?.toInt() ?? 0,
      coveragePercentage:
          (actual['coverage_percentage'] as num?)?.toDouble() ?? 0.0,
      strikeRate: (actual['strike_rate'] as num?)?.toDouble() ?? 0.0,
      avgOrderValue: (actual['avg_order_value'] as num?)?.toDouble() ?? 0.0,
      visitPercentage:
          (achievement['visit_percentage'] as num?)?.toDouble() ?? 0.0,
      salesPercentage:
          (achievement['sales_percentage'] as num?)?.toDouble() ?? 0.0,
      coverageAchievement:
          (achievement['coverage_percentage'] as num?)?.toDouble() ?? 0.0,
      overallScore: (achievement['overall_score'] as num?)?.toDouble() ?? 0.0,
      performanceGrade:
          achievement['performance_grade']?.toString() ?? 'Active',
      leaderboard:
          rawLeaders.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }
}

final kpiSummaryProvider = FutureProvider.autoDispose<KpiData>((ref) async {
  final api = ref.watch(businessApiProvider);
  final period = ref.watch(kpiPeriodProvider);

  final response = await api.kpiSummary(query: {'period': period.value});
  final payload = Map<String, dynamic>.from(response.data as Map);
  final data = Map<String, dynamic>.from(payload['data'] as Map? ?? {});

  return KpiData.fromJson(data);
});

class KpiTargetManager {
  final BusinessApi api;
  final Ref ref;

  KpiTargetManager(this.api, this.ref);

  Future<void> saveTarget({
    int? targetId,
    required String title,
    required String periodType,
    required int visitTarget,
    required double salesTarget,
    required double coverageTarget,
  }) async {
    final body = {
      'title': title,
      'period_type': periodType,
      'visit_target': visitTarget,
      'order_amount_target': salesTarget,
      'coverage_target_percentage': coverageTarget,
      'status': 'active',
    };

    if (targetId != null && targetId > 0) {
      await api.updateKpiTarget(targetId, body);
    } else {
      await api.createKpiTarget(body);
    }

    ref.invalidate(kpiSummaryProvider);
  }
}

final kpiTargetManagerProvider = Provider<KpiTargetManager>((ref) {
  return KpiTargetManager(ref.watch(businessApiProvider), ref);
});
