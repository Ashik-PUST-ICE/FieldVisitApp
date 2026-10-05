import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/presentation/providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsProvider);
    final filter = ref.watch(reportsFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Reports',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          if (filter.from != null || filter.to != null)
            TextButton.icon(
              onPressed: () => ref.read(reportsFilterProvider.notifier).state =
                  const ReportsFilter(),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(reportsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _DateRangeBar(filter: filter, isDark: isDark),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(reportsProvider),
              child: state.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bar_chart_rounded,
                            size: 48, color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      const Text('Unable to load reports',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(e.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ]),
                  ),
                ),
                data: (data) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _ReportSection(
                      title: 'Visit Report',
                      icon: Icons.directions_walk_rounded,
                      color: AppColors.primary,
                      values: data['visits'] as Map<String, dynamic>,
                      isDark: isDark,
                    ),
                    _ReportSection(
                      title: 'Order Report',
                      icon: Icons.shopping_bag_rounded,
                      color: AppColors.blue,
                      values: data['orders'] as Map<String, dynamic>,
                      isDark: isDark,
                    ),
                    _OfficersSection(
                      values: data['officers'] as Map<String, dynamic>,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date Range Bar ──────────────────────────────────────────────────────────

class _DateRangeBar extends ConsumerWidget {
  final ReportsFilter filter;
  final bool isDark;
  const _DateRangeBar({required this.filter, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
            bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range_rounded,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                _DatePickerButton(
                  label: filter.from != null ? _fmt(filter.from!) : 'From date',
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: filter.from ??
                          DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: AppColors.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      ref.read(reportsFilterProvider.notifier).state = ref
                          .read(reportsFilterProvider)
                          .copyWith(from: picked);
                    }
                  },
                  isDark: isDark,
                  hasValue: filter.from != null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('→',
                      style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.grey)),
                ),
                _DatePickerButton(
                  label: filter.to != null ? _fmt(filter.to!) : 'To date',
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: filter.to ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: AppColors.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      ref.read(reportsFilterProvider.notifier).state =
                          ref.read(reportsFilterProvider).copyWith(to: picked);
                    }
                  },
                  isDark: isDark,
                  hasValue: filter.to != null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _QuickRangeMenu(isDark: isDark),
        ],
      ),
    );
  }

  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} ${_month(dt.month)} ${dt.year}';

  static String _month(int m) => [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool hasValue;
  const _DatePickerButton(
      {required this.label,
      required this.onTap,
      required this.isDark,
      required this.hasValue});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.primary.withOpacity(0.12)
              : (isDark ? AppColors.darkCard : AppColors.background),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withOpacity(0.4)
                : (isDark ? AppColors.darkBorder : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
            color: hasValue
                ? AppColors.primary
                : (isDark ? Colors.white60 : Colors.grey),
          ),
        ),
      ),
    );
  }
}

class _QuickRangeMenu extends ConsumerWidget {
  final bool isDark;
  const _QuickRangeMenu({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<int>(
      tooltip: 'Quick ranges',
      icon: Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        _item(0, 'Today'),
        _item(7, 'Last 7 days'),
        _item(30, 'Last 30 days'),
        _item(90, 'Last 3 months'),
      ],
      onSelected: (days) {
        final to = DateTime.now();
        final from = to.subtract(Duration(days: days));
        ref.read(reportsFilterProvider.notifier).state =
            ReportsFilter(from: from, to: to);
      },
    );
  }

  PopupMenuItem<int> _item(int days, String label) => PopupMenuItem(
      value: days, child: Text(label, style: const TextStyle(fontSize: 13)));
}

// ─── Report Section Card ─────────────────────────────────────────────────────

class _ReportSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> values;
  final bool isDark;
  const _ReportSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.values,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
          ),
          // Stat grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: entries.isEmpty
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('No data',
                            style: TextStyle(color: Colors.grey))))
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: entries
                        .map((e) => _StatChip(
                              label: e.key.replaceAll('_', ' '),
                              value: '${e.value}',
                              color: color,
                              isDark: isDark,
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _StatChip(
      {required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.1) : color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ]),
    );
  }
}

// ─── Officers Section ─────────────────────────────────────────────────────────

class _OfficersSection extends StatelessWidget {
  final Map<String, dynamic> values;
  final bool isDark;
  const _OfficersSection({required this.values, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rows = values['rows'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.purple.withOpacity(0.12),
                  AppColors.purple.withOpacity(0.04)
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_alt_rounded,
                    color: AppColors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Officer Performance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
          ),
          if (rows is! List || (rows as List).isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                  child: Text('No officer data available',
                      style: TextStyle(color: Colors.grey))),
            )
          else
            ...(rows as List).asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value as Map;
              final visits = row['total_visits'] ?? 0;
              final orders = row['total_orders'] ?? 0;
              return Container(
                margin: EdgeInsets.fromLTRB(16, i == 0 ? 16 : 0, 16, 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.purple.withOpacity(0.15),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                          color: AppColors.purple, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row['user_name']?.toString() ??
                                'Officer #${row['user_id']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          if (row['user_id'] != null)
                            Text('ID: ${row['user_id']}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                        ]),
                  ),
                  Row(children: [
                    _MiniStat(
                        label: 'Visits',
                        value: '$visits',
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    _MiniStat(
                        label: 'Orders',
                        value: '$orders',
                        color: AppColors.blue),
                  ]),
                ]),
              );
            }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800, color: color, fontSize: 15)),
        Text(label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
      ]),
    );
  }
}
