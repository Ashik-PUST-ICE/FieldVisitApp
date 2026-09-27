import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_theme.dart';
import 'package:field_visit_app/data/models/outlet.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

class OutletsScreen extends ConsumerWidget {
  const OutletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outletsAsync = ref.watch(outletsProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(outletsProvider.notifier).refresh(),
        child: outletsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(error: error, onRetry: () => ref.read(outletsProvider.notifier).refresh()),
          data: (outlets) => outlets.isEmpty
              ? ListView(children: const [SizedBox(height: 240), Center(child: Text('No outlets found'))])
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: outlets.length,
                  itemBuilder: (_, index) => _OutletTile(outlet: outlets[index]),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOutletForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _OutletTile extends ConsumerWidget {
  final Outlet outlet;
  const _OutletTile({required this.outlet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.store, color: Colors.white),
        ),
        title: Text(outlet.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${outlet.address ?? 'No address'}\n${outlet.status ?? 'Status unknown'}'),
        isThreeLine: true,
        onTap: () => _showOutletForm(context, ref, outlet: outlet),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            final notifier = ref.read(outletsProvider.notifier);
            if (action == 'edit') {
              if (context.mounted) _showOutletForm(context, ref, outlet: outlet);
            } else if (action == 'qr') {
              await notifier.regenerateQr(outlet.id);
            } else if (action == 'deactivate') {
              await notifier.deactivateQr(outlet.id);
            } else if (action == 'verify') {
              await _verifyOutletQr(context, ref);
            } else if (action == 'delete' && context.mounted) {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete outlet?'),
                  content: Text('Delete ${outlet.name}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true) await notifier.remove(outlet.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'qr', child: Text('Regenerate QR')),
            PopupMenuItem(value: 'deactivate', child: Text('Deactivate QR')),
            PopupMenuItem(value: 'verify', child: Text('Verify QR token')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

Future<void> _verifyOutletQr(BuildContext context, WidgetRef ref) async {
  final token = TextEditingController();
  await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
    title: const Text('Verify outlet QR'),
    content: TextField(controller: token, decoration: const InputDecoration(labelText: 'QR token')),
    actions: [
      TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
      FilledButton(onPressed: () async {
        if (token.text.trim().isEmpty) return;
        try {
          final response = await ref.read(businessApiProvider).verifyQr(token.text.trim());
          final payload = Map<String, dynamic>.from(response.data as Map);
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(payload['message']?.toString() ?? 'QR verified successfully')));
          }
        } catch (e) {
          if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }, child: const Text('Verify')),
    ],
  ));
  token.dispose();
}

Future<void> _showOutletForm(BuildContext context, WidgetRef ref, {Outlet? outlet}) async {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: outlet?.name);
  final address = TextEditingController(text: outlet?.address);
  final code = TextEditingController(text: outlet?.code);
  final phone = TextEditingController(text: outlet?.phone);
  final latitude = TextEditingController(text: outlet?.latitude?.toString());
  final longitude = TextEditingController(text: outlet?.longitude?.toString());
  final radius = TextEditingController(text: outlet?.geofenceRadius?.toString());

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(outlet == null ? 'Add outlet' : 'Edit outlet'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null),
            TextFormField(controller: code, decoration: const InputDecoration(labelText: 'Code')),
            TextFormField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
            TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
            TextFormField(controller: latitude, decoration: const InputDecoration(labelText: 'Latitude'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            TextFormField(controller: longitude, decoration: const InputDecoration(labelText: 'Longitude'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            TextFormField(controller: radius, decoration: const InputDecoration(labelText: 'Geofence radius'), keyboardType: TextInputType.number),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final data = <String, dynamic>{
              'name': name.text.trim(),
              if (code.text.trim().isNotEmpty) 'code': code.text.trim(),
              if (address.text.trim().isNotEmpty) 'address': address.text.trim(),
              if (phone.text.trim().isNotEmpty) 'phone': phone.text.trim(),
              if (latitude.text.trim().isNotEmpty) 'latitude': latitude.text.trim(),
              if (longitude.text.trim().isNotEmpty) 'longitude': longitude.text.trim(),
              if (radius.text.trim().isNotEmpty) 'geofence_radius': int.tryParse(radius.text.trim()),
            };
            try {
              if (outlet == null) {
                await ref.read(outletsProvider.notifier).create(data);
              } else {
                await ref.read(outletsProvider.notifier).update(outlet.id, data);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            } catch (e) {
              if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  name.dispose(); address.dispose(); code.dispose(); phone.dispose(); latitude.dispose(); longitude.dispose(); radius.dispose();
  if (saved == true && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Outlet saved')));
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
