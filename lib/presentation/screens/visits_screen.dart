import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/core/widgets/app_dropdown.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/data/models/visit.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';
import 'package:field_visit_app/presentation/providers/visits_provider.dart';
import 'package:field_visit_app/presentation/screens/orders_screen.dart';
import 'package:field_visit_app/presentation/screens/visit_details_screens.dart';

class VisitsScreen extends ConsumerStatefulWidget {
  const VisitsScreen({super.key});

  @override
  ConsumerState<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends ConsumerState<VisitsScreen>
    with SingleTickerProviderStateMixin {
  String _filter = 'all'; // 'all', 'in_progress', 'completed'
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visitsAsync = ref.watch(visitsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Visits',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Sync Cloud Visits',
            icon: const Icon(Icons.cloud_sync_rounded),
            onPressed: () {
              ref.read(visitsProvider.notifier).refresh();
              ref.invalidate(visitHistoryProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Visits synced with cloud server!'),
                  backgroundColor: Color(0xFF136B3E),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(visitsProvider.notifier).refresh();
              ref.invalidate(visitHistoryProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.grey,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(
                text: 'Active Visits',
                icon: Icon(Icons.assignment_rounded, size: 18)),
            Tab(text: 'History', icon: Icon(Icons.history_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Active Visits ──────────────────────────────────
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('In Progress', 'in_progress', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed', 'completed', isDark),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(visitsProvider.notifier).refresh(),
                  child: visitsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                    error: (error, _) => _ErrorView(
                      error: error,
                      onRetry: () =>
                          ref.read(visitsProvider.notifier).refresh(),
                    ),
                    data: (visits) {
                      final filtered = visits.where((v) {
                        if (_filter == 'all') return true;
                        final st = (v.status ?? '').toLowerCase();
                        if (_filter == 'completed')
                          return st.contains('complete') ||
                              st.contains('verified');
                        if (_filter == 'in_progress')
                          return st.contains('progress') ||
                              st.contains('started');
                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return ListView(children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Column(children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.assignment_outlined,
                                    size: 48, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text('No visits found',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              const Text('Tap "Start Visit" below to begin',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13)),
                            ]),
                          ),
                        ]);
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _VisitTile(visit: filtered[i]),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          // ── Tab 2: Visit History ──────────────────────────────────
          _VisitHistoryTab(isDark: isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'visits_start',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: () => _showStartVisit(context, ref),
        icon: const Icon(Icons.play_arrow_rounded, size: 24),
        label: const Text('Start Visit',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Visit History Tab ───────────────────────────────────────────────────────

class _VisitHistoryTab extends ConsumerWidget {
  final bool isDark;
  const _VisitHistoryTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(visitHistoryProvider);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(visitHistoryProvider),
      child: historyAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.errorLight, shape: BoxShape.circle),
              child: const Icon(Icons.history_toggle_off_rounded,
                  size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            const Text('Could not load history',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Text(e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              onPressed: () => ref.invalidate(visitHistoryProvider),
              child: const Text('Retry'),
            ),
          ]),
        ),
        data: (history) {
          if (history.isEmpty) {
            return ListView(children: [
              const SizedBox(height: 120),
              Center(
                  child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.history_rounded,
                      size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text('No visit history yet',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Completed visits will appear here',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ])),
            ]);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: history.length,
            itemBuilder: (_, i) =>
                _HistoryCard(record: history[i], isDark: isDark, index: i),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final bool isDark;
  final int index;
  const _HistoryCard(
      {required this.record, required this.isDark, required this.index});

  @override
  Widget build(BuildContext context) {
    final status = (record['status'] ?? '').toString().toLowerCase();
    final isComplete =
        status.contains('complete') || status.contains('verified');
    final color = isComplete ? AppColors.primary : AppColors.warning;
    final createdAt = record['created_at']?.toString() ?? '';
    String formattedDate = createdAt;
    try {
      if (createdAt.isNotEmpty) {
        final dt = DateTime.parse(createdAt).toLocal();
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      }
    } catch (_) {}

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line
        Column(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 2),
            ),
            child: Icon(
                isComplete ? Icons.check_rounded : Icons.pending_rounded,
                size: 18,
                color: color),
          ),
          Container(
              width: 2,
              height: 60,
              color: isDark ? AppColors.darkBorder : AppColors.border),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  'Visit #${record['id'] ?? index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isComplete
                        ? 'Completed'
                        : (record['status']?.toString() ?? 'Unknown'),
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              if (record['outlet_id'] != null)
                _InfoRow(
                    icon: Icons.store_rounded,
                    text: 'Outlet #${record['outlet_id']}',
                    isDark: isDark),
              if (formattedDate.isNotEmpty)
                _InfoRow(
                    icon: Icons.access_time_rounded,
                    text: formattedDate,
                    isDark: isDark),
              if (record['remarks'] != null &&
                  record['remarks'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    record['remarks'].toString(),
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                        fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const _InfoRow(
      {required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(children: [
        Icon(icon, size: 13, color: isDark ? Colors.white38 : Colors.grey),
        const SizedBox(width: 5),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600]))),
      ]),
    );
  }
}

class _VisitTile extends ConsumerWidget {
  final Visit visit;
  const _VisitTile({required this.visit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = (visit.status ?? 'pending').toLowerCase();

    Color statusColor;
    Color statusBg;
    String statusLabel;

    if (status.contains('complete') || status.contains('verified')) {
      statusColor = const Color(0xFF10B981);
      statusBg = const Color(0xFFD1FAE5);
      statusLabel = 'Completed';
    } else if (status.contains('progress') || status.contains('started')) {
      statusColor = const Color(0xFFF59E0B);
      statusBg = const Color(0xFFFEF3C7);
      statusLabel = 'In Progress';
    } else {
      statusColor = const Color(0xFF0D9488);
      statusBg = const Color(0xFFCCFBF1);
      statusLabel = 'Scheduled';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.store_mall_directory_rounded,
                      color: statusColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Visit #${visit.id}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? statusColor.withOpacity(0.2)
                                  : statusBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.pin_drop_outlined,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            'Outlet ID: ${visit.outletId}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (visit.latitude != null &&
                          visit.latitude!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'GPS: ${visit.latitude}, ${visit.longitude}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162032) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Row(
              children: [
                // Quick actions (horizontal scroll so the row never overflows/clips)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickActionBtn(
                          context,
                          icon: Icons.my_location_rounded,
                          label: 'Verify GPS',
                          onTap: () => _showVerifyLocation(context, ref, visit),
                        ),
                        _buildQuickActionBtn(
                          context,
                          icon: Icons.camera_alt_rounded,
                          label: 'Photos',
                          onTap: () => _showVisitPhotos(context, ref, visit),
                        ),
                        _buildQuickActionBtn(
                          context,
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Complete',
                          onTap: () => _showCompleteVisit(context, ref, visit),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Styled 3-dot menu button (rounded card, aligned with quick actions)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    // The BUTTON tap target is sized via the IconButton style.
                    // NEVER use a tight/fixed width here: `constraints` is
                    // forwarded straight to the popup MENU route
                    // (material/popup_menu.dart showButtonMenu ->
                    // `constraints: widget.constraints`), so
                    // `BoxConstraints.tightFor(width: 36)` collapsed the whole
                    // menu to 36px, leaving only 12px per item Row and
                    // overflowing by 83-135px (see flutter-run.log).
                    constraints:
                        const BoxConstraints(minWidth: 200, maxWidth: 400),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(34, 34),
                      maximumSize: const Size(34, 34),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    tooltip: 'More actions',
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    onSelected: (action) async {
                      final notifier = ref.read(visitsProvider.notifier);
                      try {
                        if (action == 'verify') {
                          await _showVerifyLocation(context, ref, visit);
                        } else if (action == 'complete') {
                          await _showCompleteVisit(context, ref, visit);
                        } else if (action == 'products') {
                          await _showVisitProducts(context, ref, visit);
                        } else if (action == 'competitors') {
                          await _showVisitCompetitors(context, ref, visit);
                        } else if (action == 'photos') {
                          await _showVisitPhotos(context, ref, visit);
                        } else if (action == 'take_order') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const OrdersScreen()));
                        } else if (action == 'delete') {
                          await notifier.remove(visit.id);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'take_order',
                        child: Row(
                          children: [
                            Icon(Icons.add_shopping_cart_rounded,
                                size: 18, color: Color(0xFF10B981)),
                            SizedBox(width: 8),
                            Text('Book / Take Order'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'products',
                        child: Row(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 18, color: Color(0xFF64748B)),
                            SizedBox(width: 8),
                            Text('Visit Products'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'competitors',
                        child: Row(
                          children: [
                            Icon(Icons.travel_explore_rounded,
                                size: 18, color: Color(0xFF64748B)),
                            SizedBox(width: 8),
                            Text('Competitor Analysis'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Visit',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF136B3E)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF136B3E)),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showVisitPhotos(
    BuildContext context, WidgetRef ref, Visit visit) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => VisitPhotosScreen(visit: visit)),
  );
}

Future<void> _showVisitProducts(
    BuildContext context, WidgetRef ref, Visit visit) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => VisitProductsScreen(visit: visit)),
  );
}

Future<void> _showVisitCompetitors(
    BuildContext context, WidgetRef ref, Visit visit) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => VisitCompetitorsScreen(visit: visit)),
  );
}

Future<void> _showStartVisit(BuildContext context, WidgetRef ref) async {
  final outlets = ref.read(outletsProvider).valueOrNull ?? const [];
  if (outlets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('No valid outlet is available. Create an outlet first.')),
    );
    return;
  }
  int? selectedOutletId;
  final latitude = TextEditingController();
  final longitude = TextEditingController();

  await CellfinFormScreen.push(
    context: context,
    title: 'Start Field Visit',
    officerName: 'FIELD OFFICER INITIATION',
    officerInfo: 'Real-time GPS Check-in',
    cards: const [
      CellfinCardItem(title: 'Routine', icon: Icons.storefront_rounded),
      CellfinCardItem(title: 'Sales Call', icon: Icons.trending_up_rounded),
      CellfinCardItem(title: 'Audit', icon: Icons.fact_check_outlined),
      CellfinCardItem(title: 'Collection', icon: Icons.receipt_long_rounded),
    ],
    submitText: 'Start Visit',
    fields: [
      StatefulBuilder(
        builder: (context, setDropState) => AppDropdownField<int>(
          label: 'Outlet',
          hint: 'Select Outlet *',
          icon: Icons.storefront_rounded,
          value: selectedOutletId,
          options: outlets
              .map((outlet) => AppDropdownOption<int>(
                    value: outlet.id,
                    title: outlet.name,
                    subtitle: 'Outlet #${outlet.id}',
                    leadingIcon: Icons.storefront_rounded,
                  ))
              .toList(),
          onChanged: (value) => setDropState(() => selectedOutletId = value),
        ),
      ),
      CellfinInputField(
        controller: latitude,
        hint: 'GPS Latitude (Optional)',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefixIcon:
            const Icon(Icons.my_location_rounded, color: Color(0xFF6B7280)),
      ),
      CellfinInputField(
        controller: longitude,
        hint: 'GPS Longitude (Optional)',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefixIcon:
            const Icon(Icons.location_on_outlined, color: Color(0xFF6B7280)),
      ),
    ],
    onSubmit: () async {
      if (selectedOutletId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an outlet')),
        );
        return;
      }
      try {
        await ref.read(visitsProvider.notifier).start(
              outletId: selectedOutletId!,
              latitude: latitude.text.trim(),
              longitude: longitude.text.trim(),
            );
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Field visit started successfully!'),
                backgroundColor: AppColors.cellfinGreen),
          );
        }
      } catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_apiErrorMessage(e))));
      }
    },
  );
  latitude.dispose();
  longitude.dispose();
}

Future<void> _showVerifyLocation(
    BuildContext context, WidgetRef ref, Visit visit) async {
  final latitude = TextEditingController(text: visit.latitude);
  final longitude = TextEditingController(text: visit.longitude);

  await CellfinFormScreen.push(
    context: context,
    title: 'Verify GPS Coordinates',
    officerName: 'LOCATION VERIFICATION',
    officerInfo: 'Visit #${visit.id} Geofence Check',
    cards: const [
      CellfinCardItem(title: 'GPS Auto', icon: Icons.my_location_rounded),
      CellfinCardItem(
          title: 'Manual Pin', icon: Icons.edit_location_alt_rounded),
      CellfinCardItem(title: 'Geofence', icon: Icons.fmd_good_outlined),
      CellfinCardItem(title: 'QR Match', icon: Icons.qr_code_2_rounded),
    ],
    submitText: 'Confirm Location',
    fields: [
      CellfinInputField(
        controller: latitude,
        hint: 'GPS Latitude *',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefixIcon:
            const Icon(Icons.my_location_rounded, color: Color(0xFF6B7280)),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Latitude is required' : null,
      ),
      CellfinInputField(
        controller: longitude,
        hint: 'GPS Longitude *',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefixIcon:
            const Icon(Icons.location_on_outlined, color: Color(0xFF6B7280)),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Longitude is required' : null,
      ),
    ],
    onSubmit: () async {
      try {
        await ref.read(visitsProvider.notifier).verifyLocation(
              visit.id,
              latitude: latitude.text.trim(),
              longitude: longitude.text.trim(),
            );
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Location verified successfully!'),
                backgroundColor: AppColors.cellfinGreen),
          );
        }
      } catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_apiErrorMessage(e))));
      }
    },
  );
  latitude.dispose();
  longitude.dispose();
}

Future<void> _showCompleteVisit(
    BuildContext context, WidgetRef ref, Visit visit) async {
  final remarks = TextEditingController();

  await CellfinFormScreen.push(
    context: context,
    title: 'Complete Field Visit',
    officerName: 'VISIT SIGN-OFF',
    officerInfo: 'Visit #${visit.id} Finalization',
    cards: const [
      CellfinCardItem(
          title: 'Completed', icon: Icons.check_circle_outline_rounded),
      CellfinCardItem(
          title: 'Partial', icon: Icons.published_with_changes_rounded),
      CellfinCardItem(title: 'Follow-up', icon: Icons.event_repeat_rounded),
      CellfinCardItem(title: 'Reschedule', icon: Icons.calendar_month_outlined),
    ],
    submitText: 'Complete Visit',
    fields: [
      CellfinInputField(
        controller: remarks,
        hint: 'Note / Visit Observation & Feedback',
        maxLines: 4,
        prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF6B7280)),
      ),
    ],
    onSubmit: () async {
      try {
        await ref
            .read(visitsProvider.notifier)
            .complete(visit.id, remarks: remarks.text);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Visit marked as complete!'),
                backgroundColor: AppColors.cellfinGreen),
          );
        }
      } catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_apiErrorMessage(e))));
      }
    },
  );
  remarks.dispose();
}

String _apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null)
      return data['message'].toString();
  }
  return error.toString();
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text('Error: $error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}
