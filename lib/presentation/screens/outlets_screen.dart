import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/data/models/outlet.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

class OutletsScreen extends ConsumerStatefulWidget {
  const OutletsScreen({super.key});

  @override
  ConsumerState<OutletsScreen> createState() => _OutletsScreenState();
}

class _OutletsScreenState extends ConsumerState<OutletsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outletsAsync = ref.watch(outletsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outlets Directory',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Verify QR Code',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => _verifyOutletQr(context, ref),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(outletsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by store name, code, or address...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.primary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(outletsProvider.notifier).refresh(),
              child: outletsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (error, _) => _ErrorView(
                  error: error,
                  onRetry: () => ref.read(outletsProvider.notifier).refresh(),
                ),
                data: (outlets) {
                  final filtered = outlets.where((o) {
                    if (_searchQuery.isEmpty) return true;
                    final name = o.name.toLowerCase();
                    final code = (o.code ?? '').toLowerCase();
                    final address = (o.address ?? '').toLowerCase();
                    return name.contains(_searchQuery) ||
                        code.contains(_searchQuery) ||
                        address.contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.storefront_outlined,
                                    size: 48, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text('No outlets found',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              const Text(
                                  'Tap "+" below to add a new retail outlet',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (_, index) =>
                        _OutletCard(outlet: filtered[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'outlets_add',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: () => _showOutletForm(context, ref),
        icon: const Icon(Icons.add_business_rounded, size: 22),
        label: const Text('Add Outlet',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _OutletCard extends ConsumerWidget {
  final Outlet outlet;
  const _OutletCard({required this.outlet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              outlet.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (outlet.code != null && outlet.code!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                outlet.code!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              outlet.address ??
                                  'No physical address configured',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (outlet.phone != null && outlet.phone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              outlet.phone!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () =>
                          _showOutletForm(context, ref, outlet: outlet),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 16, color: Color(0xFF136B3E)),
                            SizedBox(width: 4),
                            Text('Edit',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF136B3E))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _showOutletQrDialog(context, ref, outlet),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_2_rounded,
                                size: 16, color: Color(0xFFD97706)),
                            SizedBox(width: 4),
                            Text('QR Code',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFD97706))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, size: 22),
                  onSelected: (action) async {
                    final notifier = ref.read(outletsProvider.notifier);
                    if (action == 'qr_view') {
                      _showOutletQrDialog(context, ref, outlet);
                    } else if (action == 'edit') {
                      if (context.mounted)
                        _showOutletForm(context, ref, outlet: outlet);
                    } else if (action == 'qr') {
                      await notifier.regenerateQr(outlet.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('QR code regenerated')));
                      }
                    } else if (action == 'deactivate') {
                      await notifier.deactivateQr(outlet.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('QR code deactivated')));
                      }
                    } else if (action == 'verify') {
                      await _verifyOutletQr(context, ref);
                    } else if (action == 'delete' && context.mounted) {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: const Text('Delete Outlet?'),
                          content: Text(
                              'Are you sure you want to delete ${outlet.name}? This action cannot be undone.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) await notifier.remove(outlet.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'qr_view', child: Text('View & Download QR')),
                    PopupMenuItem(value: 'edit', child: Text('Edit Info')),
                    PopupMenuItem(
                        value: 'qr', child: Text('Regenerate QR Token')),
                    PopupMenuItem(
                        value: 'deactivate', child: Text('Deactivate QR')),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Outlet',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showOutletQrDialog(
    BuildContext context, WidgetRef ref, Outlet outlet) async {
  final qrToken = outlet.qrToken ?? 'OUTLET-${outlet.id}';
  final qrUrl =
      'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent(qrToken)}';
  final downloadUrl =
      'https://api.qrserver.com/v1/create-qr-code/?size=600x600&format=png&download=1&data=${Uri.encodeComponent(qrToken)}';

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF136B3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.qr_code_2_rounded,
                color: Color(0xFF136B3E), size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(outlet.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                Text('Code: ${outlet.code ?? "#${outlet.id}"}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Image.network(
                qrUrl,
                width: 200,
                height: 200,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        width: 200,
                        height: 200,
                        child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF136B3E))),
                      ),
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded,
                            size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Unable to load QR image',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Token: $qrToken',
                style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF334155)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
        // ── Download QR ──────────────────────────────────────────────
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            final uri = Uri.parse(downloadUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Could not open download link')),
                );
              }
            }
          },
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Download'),
        ),
        // ── Regenerate ───────────────────────────────────────────────
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF136B3E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            await ref.read(outletsProvider.notifier).regenerateQr(outlet.id);
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('QR token regenerated!'),
                    backgroundColor: Color(0xFF136B3E)),
              );
            }
          },
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Regenerate'),
        ),
      ],
    ),
  );
}

Future<void> _verifyOutletQr(BuildContext context, WidgetRef ref) async {
  final token = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Verify Outlet QR Token'),
      content: TextField(
        controller: token,
        decoration: InputDecoration(
          labelText: 'Enter or scan QR token',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            if (token.text.trim().isEmpty) return;
            try {
              final response = await ref
                  .read(businessApiProvider)
                  .verifyQr(token.text.trim());
              final payload = Map<String, dynamic>.from(response.data as Map);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(payload['message']?.toString() ??
                          'QR verified successfully')),
                );
              }
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }
          },
          child: const Text('Verify Token'),
        ),
      ],
    ),
  );
  token.dispose();
}

Future<void> _showOutletForm(BuildContext context, WidgetRef ref,
    {Outlet? outlet}) async {
  final name = TextEditingController(text: outlet?.name);
  final address = TextEditingController(text: outlet?.address);
  final code = TextEditingController(text: outlet?.code);
  final phone = TextEditingController(text: outlet?.phone);
  final latitude = TextEditingController(text: outlet?.latitude?.toString());
  final longitude = TextEditingController(text: outlet?.longitude?.toString());
  final radius =
      TextEditingController(text: outlet?.geofenceRadius?.toString());

  await CellfinFormScreen.push(
    context: context,
    title: outlet == null ? 'Add Retail Outlet' : 'Edit Outlet Details',
    officerName: 'OUTLET REGISTRATION',
    officerInfo: 'Retail Partner Directory Entry',
    cards: const [
      CellfinCardItem(title: 'Retail Store', icon: Icons.store_rounded),
      CellfinCardItem(title: 'Wholesale', icon: Icons.warehouse_rounded),
      CellfinCardItem(title: 'Supermarket', icon: Icons.local_mall_outlined),
      CellfinCardItem(title: 'Dealer Hub', icon: Icons.business_center_rounded),
    ],
    submitText: outlet == null ? 'Create Outlet' : 'Save Changes',
    fields: [
      CellfinInputField(
        controller: name,
        hint: 'Receiver / Outlet Store Name *',
        prefixIcon:
            const Icon(Icons.storefront_rounded, color: Color(0xFF6B7280)),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Outlet name is required' : null,
      ),
      CellfinInputField(
        controller: code,
        hint: 'Outlet Code (Optional e.g. OUT-104)',
        prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF6B7280)),
      ),
      CellfinInputField(
        controller: address,
        hint: 'Full Store / Market Address *',
        prefixIcon:
            const Icon(Icons.location_on_outlined, color: Color(0xFF6B7280)),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Address is required' : null,
      ),
      CellfinInputField(
        controller: phone,
        keyboardType: TextInputType.phone,
        hint: 'Store Contact Phone Number',
        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF6B7280)),
      ),
      Row(
        children: [
          Expanded(
            child: CellfinInputField(
              controller: latitude,
              hint: 'GPS Latitude',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.my_location_rounded,
                  color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CellfinInputField(
              controller: longitude,
              hint: 'GPS Longitude',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
      CellfinInputField(
        controller: radius,
        keyboardType: TextInputType.number,
        hint: 'Geofence Radius (Meters)',
        prefixIcon: const Icon(Icons.radar_rounded, color: Color(0xFF6B7280)),
      ),
    ],
    onSubmit: () async {
      final data = <String, dynamic>{
        'name': name.text.trim(),
        if (code.text.trim().isNotEmpty) 'code': code.text.trim(),
        if (address.text.trim().isNotEmpty) 'address': address.text.trim(),
        if (phone.text.trim().isNotEmpty) 'phone': phone.text.trim(),
        if (latitude.text.trim().isNotEmpty) 'latitude': latitude.text.trim(),
        if (longitude.text.trim().isNotEmpty)
          'longitude': longitude.text.trim(),
        if (radius.text.trim().isNotEmpty)
          'geofence_radius': int.tryParse(radius.text.trim()),
      };
      try {
        if (outlet == null) {
          await ref.read(outletsProvider.notifier).create(data);
        } else {
          await ref.read(outletsProvider.notifier).update(outlet.id, data);
        }
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Outlet saved successfully!'),
                backgroundColor: AppColors.cellfinGreen),
          );
        }
      } catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    },
  );
  name.dispose();
  address.dispose();
  code.dispose();
  phone.dispose();
  latitude.dispose();
  longitude.dispose();
  radius.dispose();
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
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
        ]),
      );
}
