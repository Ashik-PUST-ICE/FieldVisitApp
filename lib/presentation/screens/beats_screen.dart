import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/models/beat.dart';
import 'package:field_visit_app/presentation/providers/beats_provider.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';

class BeatsScreen extends ConsumerWidget {
  const BeatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beats = ref.watch(beatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Beats')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(beatsProvider.notifier).refresh(),
        child: beats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(message: _errorMessage(error), onRetry: () => ref.read(beatsProvider.notifier).refresh()),
          data: (items) => items.isEmpty
              ? ListView(children: const [SizedBox(height: 240), Center(child: Text('No beats found'))])
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, index) => _BeatTile(beat: items[index]),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showBeatForm(context, ref), child: const Icon(Icons.add)),
    );
  }
}

class _BeatTile extends ConsumerWidget {
  final Beat beat;
  const _BeatTile({required this.beat});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.route)),
          title: Text(beat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${beat.code ?? 'No code'}\n${beat.date ?? 'No date'}'),
          isThreeLine: true,
          onTap: () => _showBeatForm(context, ref, beat: beat),
          trailing: PopupMenuButton<String>(
            onSelected: (action) async {
              if (action == 'edit') {
                if (context.mounted) await _showBeatForm(context, ref, beat: beat);
              } else if (action == 'outlets') {
                await _showBeatOutlets(context, ref, beat);
              } else {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete beat?'),
                    content: Text('Delete ${beat.name}?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (ok == true) {
                  try {
                    await ref.read(beatsProvider.notifier).remove(beat.id);
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
                  }
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'outlets', child: Text('Beat outlets')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      );
}

Future<void> _showBeatOutlets(BuildContext context, WidgetRef ref, Beat beat) async {
  try {
    final items = await ref.read(beatsProvider.notifier).outlets(beat.id);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${beat.name} outlets'),
        content: SizedBox(
          width: 420,
          child: items.isEmpty
              ? const Text('No outlets assigned')
              : ListView(
                  shrinkWrap: true,
                  children: items.map((item) => ListTile(
                    title: Text('Outlet #${item['outlet_id']}'),
                    subtitle: Text('Sequence: ${item['sequence'] ?? '-'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () async {
                        await ref.read(beatsProvider.notifier).removeOutlet(beat.id, (item['id'] as num).toInt());
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  )).toList(),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(onPressed: () { Navigator.pop(context); _addBeatOutlet(context, ref, beat); }, child: const Text('Add outlet')),
        ],
      ),
    );
  } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(e)))); }
}

Future<void> _addBeatOutlet(BuildContext context, WidgetRef ref, Beat beat) async {
  final outlets = ref.read(outletsProvider).valueOrNull ?? const [];
  if (outlets.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create an outlet first'))); return; }
  int outletId = outlets.first.id; final sequence = TextEditingController(text: '1');
  await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setState) => AlertDialog(title: const Text('Add outlet to beat'), content: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField<int>(value: outletId, items: outlets.map((o) => DropdownMenuItem(value: o.id, child: Text(o.name))).toList(), onChanged: (v) => setState(() => outletId = v ?? outletId)), TextField(controller: sequence, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sequence'))]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () async { try { await ref.read(beatsProvider.notifier).addOutlet(beat.id, outletId, int.tryParse(sequence.text) ?? 1); if (dialogContext.mounted) Navigator.pop(dialogContext); } catch (e) { if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_errorMessage(e)))); } }, child: const Text('Add'))]))); sequence.dispose();
}

Future<void> _showBeatForm(BuildContext context, WidgetRef ref, {Beat? beat}) async {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: beat?.name);
  final code = TextEditingController(text: beat?.code);
  final date = TextEditingController(text: beat?.date);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(beat == null ? 'Add beat' : 'Edit beat'),
      content: Form(
        key: formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null),
          TextFormField(controller: code, decoration: const InputDecoration(labelText: 'Code')),
          TextFormField(controller: date, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
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
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            } catch (e) {
              if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
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
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(message, textAlign: TextAlign.center)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ]));
}
