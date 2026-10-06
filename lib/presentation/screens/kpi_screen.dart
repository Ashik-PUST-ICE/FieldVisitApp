import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/presentation/providers/kpi_provider.dart';

class KpiScreen extends ConsumerWidget {
  const KpiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiAsync = ref.watch(kpiSummaryProvider);
    final period = ref.watch(kpiPeriodProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'kpi'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: tr(ref, 'configureGoal'),
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              final kpi = kpiAsync.value;
              _openTargetConfigModal(context, ref, kpi);
            },
          ),
          IconButton(
            tooltip: tr(ref, 'refresh'),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(kpiSummaryProvider),
          ),
        ],
      ),
      body: kpiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text('${tr(ref, 'kpiLoadError')}: $err',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(kpiSummaryProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(tr(ref, 'retry')),
                ),
              ],
            ),
          ),
        ),
        data: (kpi) {
          final fmt = NumberFormat.currency(symbol: '৳ ', decimalDigits: 0);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(kpiSummaryProvider),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // Period Toggle Chips (Today / This Week / This Month)
                _buildPeriodToggle(context, ref, period, isDark),
                const SizedBox(height: 16),

                // Hero Performance Card
                _buildHeroPerformanceBanner(context, kpi, isDark),
                const SizedBox(height: 20),

                // Core Targets Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr(ref, 'coreFieldTargets'),
                      style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _openTargetConfigModal(context, ref, kpi),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: Text(tr(ref, 'editGoal'),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Visit Target Card
                _buildProgressKpiCard(
                  context,
                  title: tr(ref, 'visitTarget'),
                  subtitle: tr(ref, 'storeCoveragePeriod')
                      .replaceAll(
                          '{period}', kpi.periodType.toUpperCase()),
                  currentValue: '${kpi.completedVisits}',
                  targetValue:
                      '${kpi.visitTarget} ${tr(ref, 'visitsSuffix')}',
                  percent: kpi.visitPercentage,
                  icon: Icons.storefront_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                  bottomNote: kpi.completedVisits >= kpi.visitTarget
                      ? tr(ref, 'targetMet')
                      : tr(ref, 'moreVisitsNeeded').replaceAll(
                          '{n}',
                          '${kpi.visitTarget - kpi.completedVisits}'),
                ),
                const SizedBox(height: 12),

                // Sales Revenue Target Card
                _buildProgressKpiCard(
                  context,
                  title: tr(ref, 'salesOrderTarget'),
                  subtitle: tr(ref, 'grossOrderVolume'),
                  currentValue: fmt.format(kpi.ordersAmount),
                  targetValue: fmt.format(kpi.salesTarget),
                  percent: kpi.salesPercentage,
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  bottomNote: tr(ref, 'totalOrdersPeriod')
                      .replaceAll('{n}', '${kpi.ordersCount}'),
                ),
                const SizedBox(height: 12),

                // Outlet Coverage Card
                _buildProgressKpiCard(
                  context,
                  title: tr(ref, 'outletCoverageRatio'),
                  subtitle: tr(ref, 'assignedBeatCoverage'),
                  currentValue: '${kpi.coveragePercentage.toStringAsFixed(1)}%',
                  targetValue:
                      '${kpi.coverageTarget.toStringAsFixed(0)}% ${tr(ref, 'targetPercent')}',
                  percent: (kpi.coveragePercentage /
                          (kpi.coverageTarget > 0 ? kpi.coverageTarget : 1) *
                          100)
                      .clamp(0, 150),
                  icon: Icons.pin_drop_rounded,
                  color: const Color(0xFF0EA5E9),
                  isDark: isDark,
                  bottomNote: tr(ref, 'assignedOutletsVisited')
                      .replaceAll(
                          '{visited}', '${kpi.uniqueOutletsVisited}')
                      .replaceAll(
                          '{total}', '${kpi.totalAssignedOutlets}'),
                ),
                const SizedBox(height: 12),

                // Strike Rate Card
                _buildProgressKpiCard(
                  context,
                  title: tr(ref, 'orderStrikeRate'),
                  subtitle: tr(ref, 'visitsConverted'),
                  currentValue: '${kpi.strikeRate.toStringAsFixed(1)}%',
                  targetValue:
                      '${kpi.strikeRateTarget.toStringAsFixed(0)}% ${tr(ref, 'targetPercent')}',
                  percent: (kpi.strikeRate /
                          (kpi.strikeRateTarget > 0
                              ? kpi.strikeRateTarget
                              : 1) *
                          100)
                      .clamp(0, 150),
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                  bottomNote: tr(ref, 'verifiedOrdersNote'),
                ),
                const SizedBox(height: 24),

                // Call Productivity & Insights
                Text(
                  tr(ref, 'callProductivity'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: tr(ref, 'avgOrderValue'),
                        value: fmt.format(kpi.avgOrderValue),
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF6366F1),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: tr(ref, 'totalBookedOrders'),
                        value: '${kpi.ordersCount}',
                        icon: Icons.shopping_basket_rounded,
                        color: const Color(0xFFEC4899),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Leaderboard Section
                Text(
                  tr(ref, 'officerLeaderboard'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  tr(ref, 'rankingsBasedOn')
                      .replaceAll('{period}', kpi.periodType),
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(height: 12),

                if (kpi.leaderboard.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(tr(ref, 'noRankingData')),
                    ),
                  )
                else
                  ...kpi.leaderboard.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final item = entry.value;
                    return _buildLeaderboardTile(context, rank, item, isDark);
                  }),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodToggle(
      BuildContext context, WidgetRef ref, KpiPeriod selected, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildPeriodTab(ref, tr(ref, 'periodToday'), KpiPeriod.today,
              selected == KpiPeriod.today, isDark),
          _buildPeriodTab(ref, tr(ref, 'periodThisWeek'), KpiPeriod.thisWeek,
              selected == KpiPeriod.thisWeek, isDark),
          _buildPeriodTab(ref, tr(ref, 'periodThisMonth'), KpiPeriod.thisMonth,
              selected == KpiPeriod.thisMonth, isDark),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(WidgetRef ref, String title, KpiPeriod period,
      bool isSelected, bool isDark) {
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(kpiPeriodProvider.notifier).state = period,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primary : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.primary)
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPerformanceBanner(
      BuildContext context, KpiData kpi, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F766E),
            AppColors.primary,
            const Color(0xFF14B8A6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        color: Colors.amberAccent, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'PERFORMANCE SCORECARD',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  kpi.startDate.isNotEmpty
                      ? kpi.startDate
                      : DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Overall Standing',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            kpi.performanceGrade,
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (kpi.visitPercentage / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trOf(context, 'visitsCompleted')
                    .replaceAll('{done}', '${kpi.completedVisits}')
                    .replaceAll('{total}', '${kpi.visitTarget}'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                trOf(context, 'percentAchieved').replaceAll(
                    '{n}', kpi.visitPercentage.toStringAsFixed(0)),
                style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressKpiCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String currentValue,
    required String targetValue,
    required double percent,
    required IconData icon,
    required Color color,
    required bool isDark,
    required String bottomNote,
  }) {
    final cappedPercent = (percent / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trOf(context, 'achieved'),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white54 : Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(currentValue,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(trOf(context, 'goalTarget'),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white54 : Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(targetValue,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: cappedPercent,
              minHeight: 7,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bottomNote,
            style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white54 : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(
      BuildContext context, int rank, Map<String, dynamic> item, bool isDark) {
    final userId = item['user_id'] ?? 'N/A';
    final totalVisits = item['total_visits'] ?? 0;

    final Color badgeColor;
    final String medal;
    if (rank == 1) {
      badgeColor = const Color(0xFFF59E0B);
      medal = '🥇';
    } else if (rank == 2) {
      badgeColor = const Color(0xFF94A3B8);
      medal = '🥈';
    } else if (rank == 3) {
      badgeColor = const Color(0xFFB45309);
      medal = '🥉';
    } else {
      badgeColor = isDark ? Colors.white24 : Colors.grey.shade400;
      medal = '#$rank';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              medal,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trOf(context, 'fieldOfficerNo')
                    .replaceAll('{n}', '$userId'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(trOf(context, 'activeFieldExecutive'),
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white54
                            : Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$totalVisits ${trOf(context, 'visitsSuffix')}',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _openTargetConfigModal(
      BuildContext context, WidgetRef ref, KpiData? kpi) {
    final titleCtrl = TextEditingController(
        text: kpi?.targetTitle ?? tr(ref, 'fieldPerformanceGoal'));
    final visitCtrl = TextEditingController(text: '${kpi?.visitTarget ?? 15}');
    final salesCtrl =
        TextEditingController(text: '${kpi?.salesTarget.toInt() ?? 50000}');
    final coverageCtrl =
        TextEditingController(text: '${kpi?.coverageTarget.toInt() ?? 85}');
    final currentPeriod = ref.read(kpiPeriodProvider);

    CellfinFormScreen.push(
      context: context,
      title: tr(ref, 'configureKpiTarget'),
      officerName: tr(ref, 'fieldOfficerTarget'),
      officerInfo: tr(ref, 'targetPerformanceMatrix'),
      cards: [
        CellfinCardItem(
            title: tr(ref, 'dailyGoal'), icon: Icons.today_rounded),
        CellfinCardItem(
            title: tr(ref, 'weeklyBeat'), icon: Icons.view_week_rounded),
        CellfinCardItem(
            title: tr(ref, 'monthlyPlan'),
            icon: Icons.calendar_month_rounded),
        CellfinCardItem(
            title: tr(ref, 'highGrowth'), icon: Icons.trending_up_rounded),
      ],
      submitText: tr(ref, 'saveTargetToServer'),
      onSubmit: () async {
        final title = titleCtrl.text.trim().isEmpty
            ? tr(ref, 'performanceTarget')
            : titleCtrl.text.trim();
        final visitTarget = int.tryParse(visitCtrl.text.trim()) ?? 15;
        final salesTarget = double.tryParse(salesCtrl.text.trim()) ?? 50000.0;
        final coverageTarget =
            double.tryParse(coverageCtrl.text.trim()) ?? 85.0;

        final periodType = currentPeriod == KpiPeriod.today
            ? 'daily'
            : (currentPeriod == KpiPeriod.thisWeek ? 'weekly' : 'monthly');

        await ref.read(kpiTargetManagerProvider).saveTarget(
              targetId: kpi?.targetId,
              title: title,
              periodType: periodType,
              visitTarget: visitTarget,
              salesTarget: salesTarget,
              coverageTarget: coverageTarget,
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(ref, 'targetSavedSynced')),
              backgroundColor: const Color(0xFF136B3E),
            ),
          );
        }
      },
      fields: [
        CellfinInputField(
          controller: titleCtrl,
          hint: tr(ref, 'targetPlanNameHint'),
          prefixIcon:
              const Icon(Icons.badge_outlined, color: Color(0xFF6B7280)),
        ),
        CellfinInputField(
          controller: visitCtrl,
          hint: tr(ref, 'visitTargetHint'),
          keyboardType: TextInputType.number,
          prefixIcon:
              const Icon(Icons.storefront_outlined, color: Color(0xFF6B7280)),
        ),
        CellfinInputField(
          controller: salesCtrl,
          hint: tr(ref, 'salesRevenueTargetHint'),
          keyboardType: TextInputType.number,
          suffixText: '৳',
          prefixIcon: const Icon(Icons.monetization_on_outlined,
              color: Color(0xFF6B7280)),
        ),
        CellfinInputField(
          controller: coverageCtrl,
          hint: tr(ref, 'coverageTargetHint'),
          keyboardType: TextInputType.number,
          suffixText: '%',
          prefixIcon:
              const Icon(Icons.pin_drop_outlined, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}
