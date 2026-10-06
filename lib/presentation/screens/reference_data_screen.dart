import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/presentation/providers/reference_data_provider.dart';

const _green = Color(0xFF136B3E);

class ReferenceDataScreen extends ConsumerStatefulWidget {
  const ReferenceDataScreen({super.key});

  @override
  ConsumerState<ReferenceDataScreen> createState() => _ReferenceDataState();
}

class _ReferenceDataState extends ConsumerState<ReferenceDataScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          tr(ref, 'referenceData'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: _green,
            child: TabBar(
              controller: _tabs,
              indicatorColor: const Color(0xFFFFB300),
              indicatorWeight: 3.5,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: [
                Tab(
                    icon: const Icon(Icons.straighten_outlined, size: 18),
                    text: tr(ref, 'units')),
                Tab(
                    icon: const Icon(Icons.warning_amber_outlined, size: 18),
                    text: tr(ref, 'competitors')),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ReferenceList(units: true),
          _ReferenceList(units: false),
        ],
      ),
    );
  }
}

class _ReferenceList extends ConsumerWidget {
  final bool units;
  const _ReferenceList({required this.units});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = units ? unitsProvider : competitorsProvider;
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: RefreshIndicator(
        color: _green,
        onRefresh: notifier.fetch,
        child: state.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _green)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.error_outline_rounded,
                        color: Colors.red, size: 40),
                  ),
                  const SizedBox(height: 14),
                  Text(_message(e), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: notifier.fetch,
                    child: Text(tr(ref, 'retry')),
                  ),
                ],
              ),
            ),
          ),
          data: (items) => items.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 160),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              units
                                  ? Icons.straighten_outlined
                                  : Icons.warning_amber_outlined,
                              color: _green,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            units
                                ? tr(ref, 'noUnitsAdded')
                                : tr(ref, 'noCompetitorsAdded'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr(ref, 'tapBelowToAddRecord'),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final id = (item['id'] as num).toInt();
                    return _RefCard(
                      item: item,
                      isUnit: units,
                      onEdit: () => _edit(context, ref, units, item),
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            title: Text(
                                units
                                    ? tr(ref, 'deleteUnitTitle')
                                    : tr(ref, 'deleteCompetitorTitle'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            content: Text(
                                tr(ref, 'removeQuestion')
                                    .replaceAll('{name}',
                                        (item['name'] ?? '').toString())),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(trOf(context, 'cancel'),
                                    style: const TextStyle(
                                        color: Color(0xFF6B7280))),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(tr(ref, 'delete')),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          try {
                            await notifier.remove(id);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_message(e))));
                            }
                          }
                        }
                      },
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'reference_add',
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () => _edit(context, ref, units, null),
        icon: const Icon(Icons.add_rounded),
        label: Text(
            units ? tr(ref, 'addUnit') : tr(ref, 'addCompetitor'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _RefCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isUnit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _RefCard(
      {required this.item,
      required this.isUnit,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? '';
    final code = item['code']?.toString() ?? '';
    final desc = item['description']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isUnit
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUnit
                          ? const Color(0xFFC8E6C9)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isUnit
                          ? Icons.straighten_rounded
                          : Icons.warning_amber_rounded,
                      color: isUnit ? _green : const Color(0xFFD97706),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (code.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(code,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4B5563))),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isUnit
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isUnit ? 'Measurement Unit' : 'Competitor',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color:
                                    isUnit ? _green : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(desc,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: _green),
                      tooltip: trOf(context, 'edit'),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Color(0xFFEF4444)),
                      tooltip: trOf(context, 'delete'),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _edit(BuildContext context, WidgetRef ref, bool units,
    Map<String, dynamic>? item) async {
  final name = TextEditingController(text: item?['name']?.toString());
  final code = TextEditingController(text: item?['code']?.toString());
  final description =
      TextEditingController(text: item?['description']?.toString());

  await CellfinFormScreen.push(
    context: context,
    title: item == null
        ? (units
            ? tr(ref, 'addMeasurementUnit')
            : tr(ref, 'addCompetitor'))
        : (units ? tr(ref, 'editUnit') : tr(ref, 'editCompetitor')),
    officerName: tr(ref, 'referenceDataManager'),
    officerInfo:
        units ? tr(ref, 'unitConfig') : tr(ref, 'competitorProfile'),
    cards: units
        ? [
            CellfinCardItem(
                title: tr(ref, 'weight'), icon: Icons.monitor_weight_outlined),
            CellfinCardItem(
                title: tr(ref, 'volume'), icon: Icons.water_drop_outlined),
            CellfinCardItem(
                title: tr(ref, 'count'),
                icon: Icons.format_list_numbered_rounded),
            CellfinCardItem(
                title: tr(ref, 'length'), icon: Icons.straighten_rounded),
          ]
        : [
            CellfinCardItem(
                title: tr(ref, 'local'), icon: Icons.store_outlined),
            CellfinCardItem(
                title: tr(ref, 'national'), icon: Icons.flag_outlined),
            CellfinCardItem(
                title: tr(ref, 'import'), icon: Icons.flight_land_rounded),
            CellfinCardItem(
                title: tr(ref, 'premium'), icon: Icons.star_outline_rounded),
          ],
    submitText:
        item == null ? tr(ref, 'addRecord') : tr(ref, 'saveChangesLower'),
    fields: [
      CellfinInputField(
        controller: name,
        hint: units
            ? '${tr(ref, 'unitNameHint')} *'
            : '${tr(ref, 'competitorNameHint')} *',
        prefixIcon: Icon(
          units ? Icons.straighten_rounded : Icons.warning_amber_outlined,
          color: const Color(0xFF6B7280),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? tr(ref, 'nameIsRequired') : null,
      ),
      CellfinInputField(
        controller: code,
        hint:
            units ? tr(ref, 'unitCodeHint') : tr(ref, 'competitorCode'),
        prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF6B7280)),
      ),
      if (!units)
        CellfinInputField(
          controller: description,
          hint: tr(ref, 'descriptionNotes'),
          maxLines: 3,
          prefixIcon:
              const Icon(Icons.note_alt_outlined, color: Color(0xFF6B7280)),
        ),
    ],
    onSubmit: () async {
      final provider = units ? unitsProvider : competitorsProvider;
      try {
        await ref.read(provider.notifier).save(
          {
            'name': name.text.trim(),
            if (code.text.trim().isNotEmpty) 'code': code.text.trim(),
            if (!units && description.text.trim().isNotEmpty)
              'description': description.text.trim(),
          },
          (item?['id'] as num?)?.toInt(),
        );
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(item == null
                  ? tr(ref, 'recordAdded')
                  : tr(ref, 'recordUpdated')),
              backgroundColor: _green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_message(e))));
        }
      }
    },
  );

  name.dispose();
  code.dispose();
  description.dispose();
}

String _message(Object e) => e is DioException && e.response?.data is Map
    ? ((e.response!.data as Map)['message'] ?? e.message).toString()
    : e.toString();
