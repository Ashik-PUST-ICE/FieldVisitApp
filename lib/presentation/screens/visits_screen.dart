import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:field_visit_app/core/theme/app_theme.dart';
import 'package:field_visit_app/data/models/visit.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';
import 'package:field_visit_app/presentation/providers/visits_provider.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

class VisitsScreen extends ConsumerWidget {
  const VisitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(visitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Visits')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(visitsProvider.notifier).refresh(),
        child: visitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(error: error, onRetry: () => ref.read(visitsProvider.notifier).refresh()),
          data: (visits) => visits.isEmpty
              ? ListView(children: const [SizedBox(height: 240), Center(child: Text('No visits found'))])
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visits.length,
                  itemBuilder: (_, index) => _VisitTile(visit: visits[index]),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStartVisit(context, ref),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start visit'),
      ),
    );
  }
}

class _VisitTile extends ConsumerWidget {
  final Visit visit;
  const _VisitTile({required this.visit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.assignment, color: Colors.white),
        ),
        title: Text('Visit #${visit.id}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Outlet ID: ${visit.outletId}\nStatus: ${visit.status ?? 'unknown'}'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
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
              } else if (action == 'delete') {
                await notifier.remove(visit.id);
              }
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'verify', child: Text('Verify location')),
            const PopupMenuItem(value: 'complete', child: Text('Complete visit')),
            const PopupMenuItem(value: 'products', child: Text('Visit products')),
            const PopupMenuItem(value: 'competitors', child: Text('Visit competitors')),
            const PopupMenuItem(value: 'photos', child: Text('Visit photos')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

Future<void> _showVisitPhotos(BuildContext context, WidgetRef ref, Visit visit) async {
  try {
    final response = await ref.read(businessApiProvider).visitPhotos(visit.id);
    final payload = Map<String, dynamic>.from(response.data as Map);
    final raw = payload['data'];
    final items = (raw is List ? raw : const <dynamic>[]).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (!context.mounted) return;
    await showDialog<void>(context: context, builder: (_) => AlertDialog(
      title: Text('Visit #${visit.id} photos'),
      content: SizedBox(width: 420, child: items.isEmpty ? const Text('No photos uploaded') : ListView(shrinkWrap: true, children: items.map((item) => ListTile(leading: const Icon(Icons.photo), title: Text('${item['caption'] ?? 'Visit photo'}'), subtitle: Text('${item['created_at'] ?? ''}'))).toList())),
      actions: [TextButton(onPressed: () { Navigator.pop(context); _uploadVisitPhoto(context, ref, visit); }, child: const Text('Upload photo')), TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_apiErrorMessage(e)))); }
}

Future<void> _uploadVisitPhoto(BuildContext context, WidgetRef ref, Visit visit) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
  if (!context.mounted) return;
  if (file == null) return;
  final caption = TextEditingController();
  await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
    title: const Text('Upload visit photo'),
    content: TextField(controller: caption, decoration: const InputDecoration(labelText: 'Caption')),
    actions: [
      TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
      FilledButton(onPressed: () async {
        try {
          await ref.read(businessApiProvider).uploadVisitPhotoBytes(visit.id, await file.readAsBytes(), file.name, caption: caption.text);
          if (dialogContext.mounted) Navigator.pop(dialogContext);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo uploaded')));
        } catch (e) { if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_apiErrorMessage(e)))); }
      }, child: const Text('Upload')),
    ],
  ));
  caption.dispose();
}

Future<void> _showVisitProducts(BuildContext context, WidgetRef ref, Visit visit) async {
  try {
    final response = await ref.read(businessApiProvider).visitProducts(visit.id);
    final payload = Map<String, dynamic>.from(response.data as Map);
    final raw = payload['data'];
    final items = (raw is List ? raw : const <dynamic>[]).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (!context.mounted) return;
    await showDialog<void>(context: context, builder: (_) => AlertDialog(
      title: Text('Visit #${visit.id} products'),
      content: SizedBox(width: 420, child: items.isEmpty ? const Text('No products added') : ListView(shrinkWrap: true, children: items.map((item) => ListTile(title: Text('Product #${item['product_id']}'), subtitle: Text('Quantity: ${item['quantity'] ?? 0}'))).toList())),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_apiErrorMessage(e)))); }
}

Future<void> _showVisitCompetitors(BuildContext context, WidgetRef ref, Visit visit) async {
  try {
    final response = await ref.read(businessApiProvider).visitCompetitors(visit.id);
    final payload = Map<String, dynamic>.from(response.data as Map);
    final raw = payload['data'];
    final items = (raw is List ? raw : const <dynamic>[]).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (!context.mounted) return;
    await showDialog<void>(context: context, builder: (_) => AlertDialog(
      title: Text('Visit #${visit.id} competitors'),
      content: SizedBox(width: 420, child: items.isEmpty ? const Text('No competitors added') : ListView(shrinkWrap: true, children: items.map((item) => ListTile(title: Text('Competitor #${item['competitor_id']}'), subtitle: Text('${item['notes'] ?? ''}'))).toList())),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_apiErrorMessage(e)))); }
}

Future<void> _showStartVisit(BuildContext context, WidgetRef ref) async {
  final outlets = ref.read(outletsProvider).valueOrNull ?? const [];
  if (outlets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid outlet is available. Create an outlet first.')));
    return;
  }
  int? selectedOutletId;
  final latitude = TextEditingController();
  final longitude = TextEditingController();
  await showDialog(
    context: context,
    builder: (dialogContext) => _VisitInputDialog(
      title: 'Start visit',
      fields: [
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(labelText: 'Outlet'),
          items: outlets.map((outlet) => DropdownMenuItem<int>(value: outlet.id, child: Text('${outlet.name} (#${outlet.id})'))).toList(),
          onChanged: (value) => selectedOutletId = value,
          validator: (value) => value == null ? 'Select an outlet' : null,
        ),
        _field(latitude, 'Latitude'),
        _field(longitude, 'Longitude'),
      ],
      onSubmit: () async {
        await ref.read(visitsProvider.notifier).start(
              outletId: selectedOutletId!,
              latitude: latitude.text.trim(),
              longitude: longitude.text.trim(),
            );
        if (dialogContext.mounted) Navigator.pop(dialogContext);
      },
    ),
  );
  latitude.dispose(); longitude.dispose();
}

Future<void> _showVerifyLocation(BuildContext context, WidgetRef ref, Visit visit) async {
  final latitude = TextEditingController(text: visit.latitude);
  final longitude = TextEditingController(text: visit.longitude);
  await showDialog(
    context: context,
    builder: (dialogContext) => _VisitInputDialog(
      title: 'Verify location',
      fields: [_field(latitude, 'Latitude'), _field(longitude, 'Longitude')],
      onSubmit: () async {
        await ref.read(visitsProvider.notifier).verifyLocation(visit.id, latitude: latitude.text.trim(), longitude: longitude.text.trim());
        if (dialogContext.mounted) Navigator.pop(dialogContext);
      },
    ),
  );
  latitude.dispose(); longitude.dispose();
}

Future<void> _showCompleteVisit(BuildContext context, WidgetRef ref, Visit visit) async {
  final remarks = TextEditingController();
  await showDialog(
    context: context,
    builder: (dialogContext) => _VisitInputDialog(
      title: 'Complete visit',
      fields: [_field(remarks, 'Remarks', required: false, maxLines: 3)],
      onSubmit: () async {
        await ref.read(visitsProvider.notifier).complete(visit.id, remarks: remarks.text);
        if (dialogContext.mounted) Navigator.pop(dialogContext);
      },
    ),
  );
  remarks.dispose();
}

Widget _field(TextEditingController controller, String label, {bool number = false, bool required = true, int maxLines = 1}) => TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: required ? (value) => value == null || value.trim().isEmpty ? '$label is required' : null : null,
    );

class _VisitInputDialog extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final Future<void> Function() onSubmit;
  const _VisitInputDialog({required this.title, required this.fields, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<FormState>();
    return AlertDialog(
      title: Text(title),
      content: Form(key: key, child: SingleChildScrollView(child: Column(children: fields))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (key.currentState!.validate()) {
              try {
                await onSubmit();
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_apiErrorMessage(e))));
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

String _apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
  }
  return error.toString();
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}
