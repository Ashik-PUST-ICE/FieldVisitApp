import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/data/models/visit.dart';
import 'package:field_visit_app/presentation/providers/products_provider.dart';
import 'package:field_visit_app/presentation/providers/reference_data_provider.dart';
import 'package:field_visit_app/presentation/providers/visits_provider.dart';
import 'package:field_visit_app/core/widgets/app_dropdown.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';

const Color _green = Color(0xFF136B3E);

// ==========================================
// 1. VISIT PHOTOS SCREEN
// ==========================================
class VisitPhotosScreen extends ConsumerStatefulWidget {
  final Visit visit;
  const VisitPhotosScreen({super.key, required this.visit});

  @override
  ConsumerState<VisitPhotosScreen> createState() => _VisitPhotosScreenState();
}

class _VisitPhotosScreenState extends ConsumerState<VisitPhotosScreen> {
  late Future<List<Map<String, dynamic>>> _photosFuture;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  void _loadPhotos() {
    setState(() {
      _photosFuture =
          ref.read(visitsProvider.notifier).getPhotos(widget.visit.id);
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (!mounted || file == null) return;

    final bytes = await file.readAsBytes();
    final captionCtrl = TextEditingController();

    if (!mounted) return;
    await CellfinFormScreen.push(
      context: context,
      title: trOf(context, 'addPhotoCaption'),
      officerName: trOf(context, 'visitEvidence')
          .replaceAll('{id}', '${widget.visit.id}'),
      officerInfo: trOf(context, 'photoDocUpload'),
      cards: [
        CellfinCardItem(
            title: trOf(context, 'storeFront'), icon: Icons.storefront_rounded),
        CellfinCardItem(
            title: trOf(context, 'shelfDisplay'), icon: Icons.grid_view_rounded),
        CellfinCardItem(
            title: trOf(context, 'stockCheck'),
            icon: Icons.inventory_2_outlined),
        CellfinCardItem(
            title: trOf(context, 'promotion'), icon: Icons.campaign_outlined),
      ],
      submitText: trOf(context, 'uploadPhoto'),
      fields: [
        CellfinInputField(
          controller: captionCtrl,
          hint: trOf(context, 'photoCaptionHint'),
          prefixIcon:
              const Icon(Icons.short_text_rounded, color: Color(0xFF6B7280)),
        ),
      ],
      onSubmit: () async {
        try {
          await ref.read(visitsProvider.notifier).uploadPhoto(
                widget.visit.id,
                bytes,
                file.name,
                caption: captionCtrl.text.trim(),
              );
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(trOf(context, 'photoUploaded')),
                  backgroundColor: _green),
            );
            _loadPhotos();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(e.toString()), backgroundColor: Colors.red),
            );
          }
        }
      },
    );
    captionCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                trOf(context, 'visitIdPhotos')
                    .replaceAll('{id}', '${widget.visit.id}'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.white)),
            Text(
                trOf(context, 'outletNumber')
                    .replaceAll('{id}', '${widget.visit.outletId}'),
                style: const TextStyle(fontSize: 12, color: Color(0xFFD1FAE5))),
          ],
        ),
        actions: [
          IconButton(
            tooltip: trOf(context, 'refresh'),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadPhotos,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _photosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _green));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                      trOf(context, 'failedToLoadPhotos')
                          .replaceAll('{error}', '${snapshot.error}'),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _green, foregroundColor: Colors.white),
                    onPressed: _loadPhotos,
                    child: Text(trOf(context, 'retry')),
                  ),
                ],
              ),
            );
          }

          final photos = snapshot.data ?? [];
          if (photos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: _green.withOpacity(0.08),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.photo_library_outlined,
                          size: 54, color: _green),
                    ),
                    const SizedBox(height: 16),
                    Text(trOf(context, 'noPhotosYet'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(trOf(context, 'captureHint'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 13)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _pickAndUploadPhoto,
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text(trOf(context, 'uploadFirstPhoto'),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: _green,
            onRefresh: () async => _loadPhotos(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final photo = photos[index];
                final caption = photo['caption']?.toString() ?? 'Visit Photo';
                final createdAt = photo['created_at']?.toString() ?? '';
                final path = photo['path']?.toString() ?? '';

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
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.image_rounded,
                          color: _green, size: 28),
                    ),
                    title: Text(caption,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (path.isNotEmpty)
                          Text(path.split('/').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF6B7280))),
                        if (createdAt.isNotEmpty)
                          Text(createdAt,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'visit_details_photo',
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: _pickAndUploadPhoto,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: Text(trOf(context, 'takeOrUpload'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ==========================================
// 2. VISIT COMPETITORS SCREEN
// ==========================================
class VisitCompetitorsScreen extends ConsumerStatefulWidget {
  final Visit visit;
  const VisitCompetitorsScreen({super.key, required this.visit});

  @override
  ConsumerState<VisitCompetitorsScreen> createState() =>
      _VisitCompetitorsScreenState();
}

class _VisitCompetitorsScreenState
    extends ConsumerState<VisitCompetitorsScreen> {
  late Future<List<Map<String, dynamic>>> _competitorsFuture;

  @override
  void initState() {
    super.initState();
    _loadCompetitors();
  }

  void _loadCompetitors() {
    setState(() {
      _competitorsFuture =
          ref.read(visitsProvider.notifier).getCompetitors(widget.visit.id);
    });
  }

  Future<void> _addCompetitor() async {
    final competitorsList = ref.read(competitorsProvider).valueOrNull ?? [];
    if (competitorsList.isEmpty) {
      // Try to fetch reference competitors if empty
      await ref.read(competitorsProvider.notifier).fetch();
    }
    final allCompetitors = ref.read(competitorsProvider).valueOrNull ?? [];
    if (!mounted) return;

    if (allCompetitors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No competitors configured in Reference Data. Please add competitors first.')),
      );
      return;
    }

    int? selectedCompetitorId = allCompetitors.first['id'] as int?;
    final notesCtrl = TextEditingController();

    await CellfinFormScreen.push(
      context: context,
      title: trOf(context, 'logCompetitorActivity'),
      officerName: trOf(context, 'visitIdAudit')
          .replaceAll('{id}', '${widget.visit.id}'),
      officerInfo: trOf(context, 'marketIntelligence'),
      cards: [
        CellfinCardItem(
            title: trOf(context, 'pricing'), icon: Icons.price_change_outlined),
        CellfinCardItem(
            title: trOf(context, 'promo'), icon: Icons.campaign_outlined),
        CellfinCardItem(
            title: trOf(context, 'placement'), icon: Icons.view_sidebar_outlined),
        CellfinCardItem(
            title: trOf(context, 'stock'), icon: Icons.inventory_outlined),
      ],
      submitText: trOf(context, 'saveCompetitor'),
      fields: [
        StatefulBuilder(
          builder: (context, setDropState) => AppDropdownField<int>(
            label: trOf(context, 'selectCompetitor'),
            hint: trOf(context, 'chooseCompetitor'),
            value: selectedCompetitorId,
            options: allCompetitors
                .map((c) => AppDropdownOption<int>(
                      value: c['id'] as int,
                      title: c['name']?.toString() ??
                          trOf(context, 'competitorHash')
                              .replaceAll('{id}', '${c['id']}'),
                      leadingIcon: Icons.store_outlined,
                    ))
                .toList(),
            onChanged: (v) => setDropState(() => selectedCompetitorId = v),
          ),
        ),
        CellfinInputField(
          controller: notesCtrl,
          hint: trOf(context, 'competitorObservationsHint'),
          maxLines: 3,
          prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF6B7280)),
        ),
      ],
      onSubmit: () async {
        if (selectedCompetitorId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(trOf(context, 'pleaseSelectCompetitor'))));
          return;
        }
        try {
          await ref.read(visitsProvider.notifier).addCompetitor(
                widget.visit.id,
                competitorId: selectedCompetitorId!,
                notes: notesCtrl.text.trim(),
              );
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(trOf(context, 'competitorLogged')),
                  backgroundColor: _green),
            );
            _loadCompetitors();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(e.toString()), backgroundColor: Colors.red),
            );
          }
        }
      },
    );
    notesCtrl.dispose();
  }

  Future<void> _deleteCompetitor(int visitCompetitorId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(trOf(ctx, 'removeCompetitorTitle'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(trOf(ctx, 'removeFromVisit')
            .replaceAll('{name}', name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(trOf(ctx, 'cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(trOf(ctx, 'remove')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref
            .read(visitsProvider.notifier)
            .removeCompetitor(widget.visit.id, visitCompetitorId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(trOf(context, 'competitorRemoved')),
                backgroundColor: _green),
          );
          _loadCompetitors();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCompetitors = ref.watch(competitorsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                trOf(context, 'visitIdCompetitors')
                    .replaceAll('{id}', '${widget.visit.id}'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.white)),
            Text(
                trOf(context, 'outletNumber')
                    .replaceAll('{id}', '${widget.visit.outletId}'),
                style: const TextStyle(fontSize: 12, color: Color(0xFFD1FAE5))),
          ],
        ),
        actions: [
          IconButton(
            tooltip: trOf(context, 'refresh'),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadCompetitors,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _competitorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _green));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                      trOf(context, 'failedToLoadCompetitors')
                          .replaceAll('{error}', '${snapshot.error}'),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _green, foregroundColor: Colors.white),
                    onPressed: _loadCompetitors,
                    child: Text(trOf(context, 'retry')),
                  ),
                ],
              ),
            );
          }

          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: _green.withOpacity(0.08),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.store_mall_directory_outlined,
                          size: 54, color: _green),
                    ),
                    const SizedBox(height: 16),
                    Text(trOf(context, 'noCompetitorActivity'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(trOf(context, 'competitorEmptyHint'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 13)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _addCompetitor,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(trOf(context, 'addCompetitor'),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: _green,
            onRefresh: () async => _loadCompetitors(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = list[index];
                final id = item['id'] as int? ?? 0;
                final competitorId = item['competitor_id'];
                // Check if competitor object is nested or match from allCompetitors
                String compName = item['competitor']?['name']?.toString() ?? '';
                if (compName.isEmpty && competitorId != null) {
                  final found = allCompetitors.firstWhere(
                    (c) => c['id'] == competitorId,
                    orElse: () => {},
                  );
                  compName = found['name']?.toString() ??
                      trOf(context, 'competitorHash')
                          .replaceAll('{id}', '$competitorId');
                }
                if (compName.isEmpty) {
                  compName = trOf(context, 'competitorHash')
                      .replaceAll('{id}', '$competitorId');
                }

                final notes = item['notes']?.toString() ?? '';

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
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Color(0xFFD97706), size: 24),
                    ),
                    title: Text(compName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: notes.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(notes,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF4B5563))),
                          )
                        : Text(trOf(context, 'noObservations'),
                            style: const TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF9CA3AF))),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444), size: 22),
                      tooltip: trOf(context, 'remove'),
                      onPressed: () => _deleteCompetitor(id, compName),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'visit_details_competitor',
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: _addCompetitor,
        icon: const Icon(Icons.add_rounded),
        label: Text(trOf(context, 'addCompetitor'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ==========================================
// 3. VISIT PRODUCTS SCREEN
// ==========================================
class VisitProductsScreen extends ConsumerStatefulWidget {
  final Visit visit;
  const VisitProductsScreen({super.key, required this.visit});

  @override
  ConsumerState<VisitProductsScreen> createState() =>
      _VisitProductsScreenState();
}

class _VisitProductsScreenState extends ConsumerState<VisitProductsScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture =
          ref.read(visitsProvider.notifier).getProducts(widget.visit.id);
    });
  }

  Future<void> _addProduct() async {
    final allProducts = ref.read(productsProvider).valueOrNull ?? [];
    if (allProducts.isEmpty) {
      await ref.read(productsProvider.notifier).fetch();
    }
    final productsList = ref.read(productsProvider).valueOrNull ?? [];
    if (!mounted) return;

    if (productsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No products available. Please add products in Product catalog first.')),
      );
      return;
    }

    int? selectedProductId = productsList.first['id'] as int?;
    final qtyCtrl = TextEditingController(text: '1');
    bool availability = true;
    final notesCtrl = TextEditingController();

    await CellfinFormScreen.push(
      context: context,
      title: trOf(context, 'logProductCheck'),
      officerName: trOf(context, 'visitIdInventory')
          .replaceAll('{id}', '${widget.visit.id}'),
      officerInfo: trOf(context, 'shelfStockOrder'),
      cards: [
        CellfinCardItem(
            title: trOf(context, 'stockAudit'),
            icon: Icons.inventory_2_outlined),
        CellfinCardItem(
            title: trOf(context, 'orderLog'), icon: Icons.shopping_cart_outlined),
        CellfinCardItem(
            title: trOf(context, 'sample'),
            icon: Icons.volunteer_activism_outlined),
        CellfinCardItem(
            title: trOf(context, 'return'),
            icon: Icons.assignment_return_outlined),
      ],
      submitText: trOf(context, 'saveProduct'),
      fields: [
        StatefulBuilder(
          builder: (context, setDropState) => AppDropdownField<int>(
            label: trOf(context, 'selectProduct'),
            hint: trOf(context, 'chooseProduct'),
            value: selectedProductId,
            options: productsList
                .map((p) => AppDropdownOption<int>(
                      value: p['id'] as int,
                      title:
                          '${p['name'] ?? trOf(context, 'productNumber').replaceAll('{id}', '${p['id']}')}${p['price'] != null ? ' (৳${p['price']})' : ''}',
                      subtitle: p['sku']?.toString(),
                      leadingIcon: Icons.inventory_2_outlined,
                    ))
                .toList(),
            onChanged: (v) => setDropState(() => selectedProductId = v),
          ),
        ),
        CellfinInputField(
          controller: qtyCtrl,
          hint: trOf(context, 'quantityOptional'),
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.format_list_numbered_rounded,
              color: Color(0xFF6B7280)),
        ),
        StatefulBuilder(
          builder: (context, setDropState) => AppDropdownField<bool>(
            label: trOf(context, 'availabilityStatus'),
            value: availability,
            searchable: false,
            options: [
              AppDropdownOption<bool>(
                value: true,
                title: trOf(context, 'inStockAvailable'),
                leadingIcon: Icons.check_circle_outline_rounded,
              ),
              AppDropdownOption<bool>(
                value: false,
                title: trOf(context, 'outOfStockUnavailable'),
                leadingIcon: Icons.cancel_outlined,
              ),
            ],
            onChanged: (v) => setDropState(() => availability = v ?? true),
          ),
        ),
        CellfinInputField(
          controller: notesCtrl,
          hint: trOf(context, 'productNotesHint'),
          maxLines: 2,
          prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF6B7280)),
        ),
      ],
      onSubmit: () async {
        if (selectedProductId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(trOf(context, 'pleaseSelectProduct'))));
          return;
        }
        final qty = int.tryParse(qtyCtrl.text.trim());
        try {
          await ref.read(visitsProvider.notifier).addProduct(
                widget.visit.id,
                productId: selectedProductId!,
                quantity: qty,
                availability: availability,
                notes: notesCtrl.text.trim(),
              );
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(trOf(context, 'productAuditSaved')),
                  backgroundColor: _green),
            );
            _loadProducts();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(e.toString()), backgroundColor: Colors.red),
            );
          }
        }
      },
    );
    qtyCtrl.dispose();
    notesCtrl.dispose();
  }

  Future<void> _deleteProduct(int visitProductId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(trOf(ctx, 'removeProductLogTitle'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(trOf(ctx, 'removeFromVisit')
            .replaceAll('{name}', name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(trOf(ctx, 'cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(trOf(ctx, 'remove')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref
            .read(visitsProvider.notifier)
            .removeProduct(widget.visit.id, visitProductId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(trOf(context, 'productEntryRemoved')),
                backgroundColor: _green),
          );
          _loadProducts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                trOf(context, 'visitIdProducts')
                    .replaceAll('{id}', '${widget.visit.id}'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.white)),
            Text(
                trOf(context, 'outletNumber')
                    .replaceAll('{id}', '${widget.visit.outletId}'),
                style: const TextStyle(fontSize: 12, color: Color(0xFFD1FAE5))),
          ],
        ),
        actions: [
          IconButton(
            tooltip: trOf(context, 'refresh'),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _green));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                      trOf(context, 'failedToLoadProducts')
                          .replaceAll('{error}', '${snapshot.error}'),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _green, foregroundColor: Colors.white),
                    onPressed: _loadProducts,
                    child: Text(trOf(context, 'retry')),
                  ),
                ],
              ),
            );
          }

          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: _green.withOpacity(0.08),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.inventory_2_outlined,
                          size: 54, color: _green),
                    ),
                    const SizedBox(height: 16),
                    Text(trOf(context, 'noProductsYet'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(trOf(context, 'productsEmptyHint'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 13)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _addProduct,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(trOf(context, 'logProduct'),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: _green,
            onRefresh: () async => _loadProducts(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = list[index];
                final id = item['id'] as int? ?? 0;
                final productId = item['product_id'];
                String productName = item['product']?['name']?.toString() ?? '';
                if (productName.isEmpty && productId != null) {
                  final found = allProducts.firstWhere(
                    (p) => p['id'] == productId,
                    orElse: () => {},
                  );
                  productName = found['name']?.toString() ??
                      trOf(context, 'productNumber')
                          .replaceAll('{id}', '$productId');
                }
                if (productName.isEmpty) {
                  productName = trOf(context, 'productNumber')
                      .replaceAll('{id}', '$productId');
                }

                final quantity = item['quantity'];
                final availability = item['availability'];
                final notes = item['notes']?.toString() ?? '';

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
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.inventory_2_rounded,
                          color: _green, size: 24),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(productName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                        if (availability != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: availability == true
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              availability == true
                                  ? 'In Stock'
                                  : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: availability == true
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (quantity != null)
                          Text(
                    trOf(context, 'quantityLabel')
                        .replaceAll('{n}', '$quantity'),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151))),
                        if (notes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(notes,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF6B7280))),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444), size: 22),
                      tooltip: trOf(context, 'remove'),
                      onPressed: () => _deleteProduct(id, productName),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'visit_details_product',
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: _addProduct,
        icon: const Icon(Icons.add_rounded),
        label: Text(trOf(context, 'logProduct'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
