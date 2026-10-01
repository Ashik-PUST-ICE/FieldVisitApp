import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/data/models/visit.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';
import 'package:field_visit_app/presentation/providers/visits_provider.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

class VisitsScreen extends ConsumerStatefulWidget {
  const VisitsScreen({super.key});

  @override
  ConsumerState<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends ConsumerState<VisitsScreen> {
  String _filter = 'all'; // 'all', 'in_progress', 'completed'

  @override
  Widget build(BuildContext context) {
    final visitsAsync = ref.watch(visitsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Visits', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(visitsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: Row(
              children: [
                _buildFilterChip('All Visits', 'all', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', 'in_progress', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed', isDark),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(visitsProvider.notifier).refresh(),
              child: visitsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (error, _) => _ErrorView(
                  error: error,
                  onRetry: () => ref.read(visitsProvider.notifier).refresh(),
                ),
                data: (visits) {
                  final filtered = visits.where((v) {
                    if (_filter == 'all') return true;
                    final st = (v.status ?? '').toLowerCase();
                    if (_filter == 'completed') {
                      return st.contains('complete') || st.contains('verified');
                    }
                    if (_filter == 'in_progress') {
                      return st.contains('progress') || st.contains('started');
                    }
                    return true;
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
                                child: const Icon(Icons.assignment_outlined, size: 48, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text('No visits found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              const Text('Tap "Start Visit" button below to create one', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (_, index) => _VisitTile(visit: filtered[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: () => _showStartVisit(context, ref),
        icon: const Icon(Icons.play_arrow_rounded, size: 24),
        label: const Text('Start Visit', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3)),
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
            color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
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
                  child: Icon(Icons.store_mall_directory_rounded, color: statusColor, size: 24),
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
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? statusColor.withOpacity(0.2) : statusBg,
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
                          Icon(Icons.pin_drop_outlined, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            'Outlet ID: ${visit.outletId}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (visit.latitude != null && visit.latitude!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'GPS: ${visit.latitude}, ${visit.longitude}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
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
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'products', child: Text('Visit Products')),
                    PopupMenuItem(value: 'competitors', child: Text('Competitor Analysis')),
                    PopupMenuItem(value: 'delete', child: Text('Delete Visit', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF0D9488)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
            ),
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
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Visit #${visit.id} Photos'),
        content: SizedBox(
          width: 420,
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No photos uploaded yet')),
                )
              : ListView(
                  shrinkWrap: true,
                  children: items
                      .map((item) => ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.photo_rounded, color: AppColors.primary),
                            ),
                            title: Text('${item['caption'] ?? 'Visit photo'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${item['created_at'] ?? ''}'),
                          ))
                      .toList(),
                ),
        ),
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _uploadVisitPhoto(context, ref, visit);
            },
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: const Text('Take/Upload Photo'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_apiErrorMessage(e))));
    }
  }
}

Future<void> _uploadVisitPhoto(BuildContext context, WidgetRef ref, Visit visit) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
  if (!context.mounted) return;
  if (file == null) return;
  final caption = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Upload Visit Photo'),
      content: TextField(
        controller: caption,
        decoration: InputDecoration(
          labelText: 'Caption (e.g., Shelf display, store front)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            try {
              await ref.read(businessApiProvider).uploadVisitPhotoBytes(
                    visit.id,
                    await file.readAsBytes(),
                    file.name,
                    caption: caption.text,
                  );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo uploaded successfully!')));
              }
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_apiErrorMessage(e))));
              }
            }
          },
          child: const Text('Upload Photo'),
        ),
      ],
    ),
  );
  caption.dispose();
}

Future<void> _showVisitProducts(BuildContext context, WidgetRef ref, Visit visit) async {
  try {
    final response = await ref.read(businessApiProvider).visitProducts(visit.id);
    final payload = Map<String, dynamic>.from(response.data as Map);
    final raw = payload['data'];
    final items = (raw is List ? raw : const <dynamic>[]).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Visit #${visit.id} Products'),
        content: SizedBox(
          width: 420,
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No products checked during this visit')),
                )
              : ListView(
                  shrinkWrap: true,
                  children: items
                      .map((item) => ListTile(
                            title: Text('Product #${item['product_id']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Quantity: ${item['quantity'] ?? 0}'),
                          ))
                      .toList(),
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_apiErrorMessage(e))));
  }
}

Future<void> _showVisitCompetitors(BuildContext context, WidgetRef ref, Visit visit) async {
  try {
    final response = await ref.read(businessApiProvider).visitCompetitors(visit.id);
    final payload = Map<String, dynamic>.from(response.data as Map);
    final raw = payload['data'];
    final items = (raw is List ? raw : const <dynamic>[]).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Visit #${visit.id} Competitors'),
        content: SizedBox(
          width: 420,
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No competitor data recorded')),
                )
              : ListView(
                  shrinkWrap: true,
                  children: items
                      .map((item) => ListTile(
                            title: Text('Competitor #${item['competitor_id']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${item['notes'] ?? 'No notes'}'),
                          ))
                      .toList(),
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_apiErrorMessage(e))));
  }
}

Future<void> _showStartVisit(BuildContext context, WidgetRef ref) async {
  final outlets = ref.read(outletsProvider).valueOrNull ?? const [];
  if (outlets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No valid outlet is available. Create an outlet first.')),
    );
    return;
  }
  int? selectedOutletId;
  final latitude = TextEditingController();
  final longitude = TextEditingController();
  await showDialog(
    context: context,
    builder: (dialogContext) => _VisitInputDialog(
      title: 'Start New Visit',
      fields: [
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'Select Outlet',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: outlets
              .map((outlet) => DropdownMenuItem<int>(
                    value: outlet.id,
                    child: Text('${outlet.name} (#${outlet.id})'),
                  ))
              .toList(),
          onChanged: (value) => selectedOutletId = value,
          validator: (value) => value == null ? 'Select an outlet' : null,
        ),
        const SizedBox(height: 12),
        _field(latitude, 'Latitude (optional GPS)'),
        const SizedBox(height: 12),
        _field(longitude, 'Longitude (optional GPS)'),
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
  latitude.dispose();
  longitude.dispose();
}

Future<void> _showVerifyLocation(BuildContext context, WidgetRef ref, Visit visit) async {
  final latitude = TextEditingController(text: visit.latitude);
  final longitude = TextEditingController(text: visit.longitude);
  await showDialog(
    context: context,
    builder: (dialogContext) => _VisitInputDialog(
      title: 'Verify GPS Location',
      fields: [
        _field(latitude, 'Latitude', required: true),
        const SizedBox(height: 12),
        _field(longitude, 'Longitude', required: true),
      ],
      onSubmit: () async {
        await ref.read(visitsProvider.notifier).verifyLocation(
              visit.id,
              latitude: latitude.text.trim(),
              longitude: longitude.text.trim(),
            );
        if (dialogContext.mounted) Navigator.pop(dialogContext);
      },
    ),
  );
  latitude.dispose();
  longitude.dispose();
}

Future<void> _showCompleteVisit(BuildContext context, WidgetRef ref, Visit visit) async {
  final remarks = TextEditingController();
  await showDialog(
    context: context,
    builder: (dialogContext) => _VisitInputDialog(
      title: 'Complete Visit',
      fields: [
        _field(remarks, 'Visit Remarks / Summary', required: false, maxLines: 3),
      ],
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
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: fields))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            if (key.currentState!.validate()) {
              try {
                await onSubmit();
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_apiErrorMessage(e))));
              }
            }
          },
          child: const Text('Save & Submit'),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text('Error: $error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}
