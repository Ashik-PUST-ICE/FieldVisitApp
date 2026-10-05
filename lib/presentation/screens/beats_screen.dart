import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/data/models/beat.dart';
import 'package:field_visit_app/presentation/providers/beats_provider.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';

const _green = Color(0xFF136B3E);
const _golden = Color(0xFFFFB300);

class BeatsScreen extends ConsumerWidget {
  const BeatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beats = ref.watch(beatsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Beat Routes',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.read(beatsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _green,
        onRefresh: () => ref.read(beatsProvider.notifier).refresh(),
        child: beats.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _green)),
          error: (error, _) => _ErrorView(
            message: _errorMessage(error),
            onRetry: () => ref.read(beatsProvider.notifier).refresh(),
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
                            child: const Icon(Icons.route_rounded, color: _green, size: 36),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No beat routes found',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap + below to add your first beat route',
                            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
                  itemBuilder: (_, index) => _BeatCard(beat: items[index]),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'beats_add',
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () => _showBeatForm(context, ref),
        icon: const Icon(Icons.add_road_rounded),
        label: const Text('Add Beat', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _BeatCard extends ConsumerWidget {
  final Beat beat;
  const _BeatCard({required this.beat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showBeatForm(context, ref, beat: beat),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Route Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: const Center(
                    child: Icon(Icons.route_rounded, color: _green, size: 24),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beat.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (beat.code != null)
                            _Badge(label: beat.code!, bg: const Color(0xFFF3F4F6), text: const Color(0xFF4B5563)),
                          if (beat.date != null)
                            _Badge(label: beat.date!, bg: const Color(0xFFFFF8E1), text: const Color(0xFFB45309), icon: Icons.calendar_today_outlined),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.list_alt_rounded, size: 20, color: Color(0xFF0284C7)),
                      tooltip: 'Beat Outlets',
                      onPressed: () => _showBeatOutlets(context, ref, beat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: _green),
                      tooltip: 'Edit Beat',
                      onPressed: () => _showBeatForm(context, ref, beat: beat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                      tooltip: 'Delete Beat',
                      onPressed: () => _confirmDelete(context, ref, beat),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color text;
  final IconData? icon;
  const _Badge({required this.label, required this.bg, required this.text, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: text),
              const SizedBox(width: 4),
            ],
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: text)),
          ],
        ),
      );
}

Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Beat beat) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Delete Beat Route?', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('Remove "${beat.name}" from beat routes? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    try {
      await ref.read(beatsProvider.notifier).remove(beat.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beat route deleted'), backgroundColor: _green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
      }
    }
  }
}

Future<void> _showBeatOutlets(BuildContext context, WidgetRef ref, Beat beat) async {
  try {
    final items = await ref.read(beatsProvider.notifier).outlets(beat.id);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.route_rounded, color: _green, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${beat.name} Outlets',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No outlets assigned to this beat', style: TextStyle(color: Color(0xFF6B7280)))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store_rounded, color: _green, size: 18),
                      ),
                      title: Text('Outlet #${item['outlet_id']}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('Sequence: ${item['sequence'] ?? '-'}',
                          style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        tooltip: 'Remove from beat',
                        onPressed: () async {
                          await ref.read(beatsProvider.notifier).removeOutlet(beat.id, (item['id'] as num).toInt());
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Outlet'),
            onPressed: () {
              Navigator.pop(ctx);
              _addBeatOutlet(context, ref, beat);
            },
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
  }
}

Future<void> _addBeatOutlet(BuildContext context, WidgetRef ref, Beat beat) async {
  final outlets = ref.read(outletsProvider).valueOrNull ?? const [];
  if (outlets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create an outlet first')));
    return;
  }
  int outletId = outlets.first.id;
  final sequence = TextEditingController(text: '1');

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocalState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Add Outlet to Beat', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Outlet Dropdown with Cellfin styling
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC4C4C4)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: outletId,
                  isExpanded: true,
                  hint: const Text('Select Outlet', style: TextStyle(color: Color(0xFF757575))),
                  items: outlets.map((o) => DropdownMenuItem(value: o.id, child: Text(o.name))).toList(),
                  onChanged: (v) => setLocalState(() => outletId = v ?? outletId),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CellfinInputField(
              controller: sequence,
              hint: 'Sequence Order (e.g. 1)',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.format_list_numbered_rounded, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () async {
              try {
                await ref.read(beatsProvider.notifier).addOutlet(beat.id, outletId, int.tryParse(sequence.text) ?? 1);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
              }
            },
            child: const Text('Add Outlet'),
          ),
        ],
      ),
    ),
  );
  sequence.dispose();
}

Future<void> _showBeatForm(BuildContext context, WidgetRef ref, {Beat? beat}) async {
  final name = TextEditingController(text: beat?.name);
  final code = TextEditingController(text: beat?.code);
  final date = TextEditingController(text: beat?.date);

  await CellfinFormScreen.push(
    context: context,
    title: beat == null ? 'Add Beat Route' : 'Edit Beat Route',
    officerName: 'BEAT ROUTE MANAGER',
    officerInfo: 'Field Visit Route Configuration',
    cards: const [
      CellfinCardItem(title: 'Daily Route', icon: Icons.today_rounded),
      CellfinCardItem(title: 'Weekly', icon: Icons.date_range_rounded),
      CellfinCardItem(title: 'Zone A', icon: Icons.location_on_outlined),
      CellfinCardItem(title: 'Zone B', icon: Icons.explore_outlined),
    ],
    submitText: beat == null ? 'Create Beat Route' : 'Save Changes',
    fields: [
      CellfinInputField(
        controller: name,
        hint: 'Beat Route Name *',
        prefixIcon: const Icon(Icons.route_rounded, color: Color(0xFF6B7280)),
        validator: (v) => v == null || v.trim().isEmpty ? 'Beat route name is required' : null,
      ),
      CellfinInputField(
        controller: code,
        hint: 'Beat Code (e.g. BT-001)',
        prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF6B7280)),
      ),
      CellfinInputField(
        controller: date,
        hint: 'Scheduled Date (YYYY-MM-DD)',
        prefixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF6B7280)),
        keyboardType: TextInputType.datetime,
      ),
    ],
    onSubmit: () async {
      final data = <String, dynamic>{
        'name': name.text.trim(),
        if (code.text.trim().isNotEmpty) 'code': code.text.trim(),
        if (date.text.trim().isNotEmpty) 'date': date.text.trim(),
      };
      try {
        if (beat == null) {
          await ref.read(beatsProvider.notifier).create(data);
        } else {
          await ref.read(beatsProvider.notifier).update(beat.id, data);
        }
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(beat == null ? 'Beat route created!' : 'Beat route updated!'),
              backgroundColor: _green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
        }
      }
    },
  );

  name.dispose();
  code.dispose();
  date.dispose();
}

String _errorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (data is Map && data['errors'] is Map) return data['errors'].toString();
  }
  return error.toString();
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
              ),
              const SizedBox(height: 14),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF374151), fontSize: 14)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
}
