import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/data/models/visit.dart';
import 'package:field_visit_app/presentation/providers/products_provider.dart';
import 'package:field_visit_app/presentation/providers/reference_data_provider.dart';
import 'package:field_visit_app/presentation/providers/visits_provider.dart';

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
      _photosFuture = ref.read(visitsProvider.notifier).getPhotos(widget.visit.id);
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (!mounted || file == null) return;

    final bytes = await file.readAsBytes();
    final captionCtrl = TextEditingController();

    if (!mounted) return;
    await CellfinFormScreen.push(
      context: context,
      title: 'Add Photo Caption',
      officerName: 'VISIT #${widget.visit.id} EVIDENCE',
      officerInfo: 'Photo Documentation Upload',
      cards: const [
        CellfinCardItem(title: 'Store Front', icon: Icons.storefront_rounded),
        CellfinCardItem(title: 'Shelf Display', icon: Icons.grid_view_rounded),
        CellfinCardItem(title: 'Stock Check', icon: Icons.inventory_2_outlined),
        CellfinCardItem(title: 'Promotion', icon: Icons.campaign_outlined),
      ],
      submitText: 'Upload Photo',
      fields: [
        CellfinInputField(
          controller: captionCtrl,
          hint: 'Caption (e.g., Shelf display, store front banner)',
          prefixIcon: const Icon(Icons.short_text_rounded, color: Color(0xFF6B7280)),
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
              const SnackBar(content: Text('Photo uploaded successfully!'), backgroundColor: _green),
            );
            _loadPhotos();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
            Text('Visit #${widget.visit.id} Photos',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white)),
            Text('Outlet #${widget.visit.outletId}',
                style: const TextStyle(fontSize: 12, color: Color(0xFFD1FAE5))),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadPhotos,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _photosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text('Failed to load photos: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
                    onPressed: _loadPhotos,
                    child: const Text('Retry'),
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
                      decoration: BoxDecoration(color: _green.withOpacity(0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.photo_library_outlined, size: 54, color: _green),
                    ),
                    const SizedBox(height: 16),
                    const Text('No Photos Uploaded Yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('Capture or select shelf displays, storefronts, and promotion proofs.',
                        textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _pickAndUploadPhoto,
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Upload First Photo', style: TextStyle(fontWeight: FontWeight.w700)),
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
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.image_rounded, color: _green, size: 28),
                    ),
                    title: Text(caption, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (path.isNotEmpty)
                          Text(path.split('/').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        if (createdAt.isNotEmpty)
                          Text(createdAt, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
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
        label: const Text('Take / Upload', style: TextStyle(fontWeight: FontWeight.w700)),
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
  ConsumerState<VisitCompetitorsScreen> createState() => _VisitCompetitorsScreenState();
}

class _VisitCompetitorsScreenState extends ConsumerState<VisitCompetitorsScreen> {
  late Future<List<Map<String, dynamic>>> _competitorsFuture;

  @override
  void initState() {
    super.initState();
    _loadCompetitors();
  }

  void _loadCompetitors() {
    setState(() {
      _competitorsFuture = ref.read(visitsProvider.notifier).getCompetitors(widget.visit.id);
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
        const SnackBar(content: Text('No competitors configured in Reference Data. Please add competitors first.')),
      );
      return;
    }

    int? selectedCompetitorId = allCompetitors.first['id'] as int?;
    final notesCtrl = TextEditingController();

    await CellfinFormScreen.push(
      context: context,
      title: 'Log Competitor Activity',
      officerName: 'VISIT #${widget.visit.id} AUDIT',
      officerInfo: 'Market Intelligence Record',
      cards: const [
        CellfinCardItem(title: 'Pricing', icon: Icons.price_change_outlined),
        CellfinCardItem(title: 'Promo', icon: Icons.campaign_outlined),
        CellfinCardItem(title: 'Placement', icon: Icons.view_sidebar_outlined),
        CellfinCardItem(title: 'Stock', icon: Icons.inventory_outlined),
      ],
      submitText: 'Save Competitor',
      fields: [
        StatefulBuilder(
          builder: (context, setDropState) => CellfinDropdownField<int>(
            value: selectedCompetitorId,
            hint: 'Select Competitor *',
            items: allCompetitors
                .map((c) => DropdownMenuItem<int>(
                      value: c['id'] as int,
                      child: Text(c['name']?.toString() ?? 'Competitor #${c['id']}'),
                    ))
                .toList(),
            onChanged: (v) => setDropState(() => selectedCompetitorId = v),
          ),
        ),
        CellfinInputField(
          controller: notesCtrl,
          hint: 'Market observations, offer details, shelf presence...',
          maxLines: 3,
          prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF6B7280)),
        ),
      ],
      onSubmit: () async {
        if (selectedCompetitorId == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a competitor')));
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
              const SnackBar(content: Text('Competitor activity logged!'), backgroundColor: _green),
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
      },
    );
    notesCtrl.dispose();
  }

  Future<void> _deleteCompetitor(int visitCompetitorId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Competitor', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to remove "$name" from this visit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(visitsProvider.notifier).removeCompetitor(widget.visit.id, visitCompetitorId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Competitor removed successfully'), backgroundColor: _green),
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
            Text('Visit #${widget.visit.id} Competitors',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white)),
            Text('Outlet #${widget.visit.outletId}',
                style: const TextStyle(fontSize: 12, color: Color(0xFFD1FAE5))),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadCompetitors,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _competitorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text('Failed to load competitors: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
                    onPressed: _loadCompetitors,
                    child: const Text('Retry'),
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
                      decoration: BoxDecoration(color: _green.withOpacity(0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.store_mall_directory_outlined, size: 54, color: _green),
                    ),
                    const SizedBox(height: 16),
                    const Text('No Competitor Activity Logged',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('Log competitor products, promotional schemes, and pricing observed at this outlet.',
                        textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _addCompetitor,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Competitor', style: TextStyle(fontWeight: FontWeight.w700)),
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
                  compName = found['name']?.toString() ?? 'Competitor #$competitorId';
                }
                if (compName.isEmpty) compName = 'Competitor #$competitorId';

                final notes = item['notes']?.toString() ?? '';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Color(0xFFD97706), size: 24),
                    ),
                    title: Text(compName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: notes.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(notes, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                          )
                        : const Text('No observations noted',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF9CA3AF))),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                      tooltip: 'Remove',
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
        label: const Text('Add Competitor', style: TextStyle(fontWeight: FontWeight.w700)),
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
  ConsumerState<VisitProductsScreen> createState() => _VisitProductsScreenState();
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
      _productsFuture = ref.read(visitsProvider.notifier).getProducts(widget.visit.id);
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
        const SnackBar(content: Text('No products available. Please add products in Product catalog first.')),
      );
      return;
    }

    int? selectedProductId = productsList.first['id'] as int?;
    final qtyCtrl = TextEditingController(text: '1');
    bool availability = true;
    final notesCtrl = TextEditingController();

    await CellfinFormScreen.push(
      context: context,
      title: 'Log Product Check',
      officerName: 'VISIT #${widget.visit.id} INVENTORY',
      officerInfo: 'Shelf Stock & Order Logging',
      cards: const [
        CellfinCardItem(title: 'Stock Audit', icon: Icons.inventory_2_outlined),
        CellfinCardItem(title: 'Order Log', icon: Icons.shopping_cart_outlined),
        CellfinCardItem(title: 'Sample', icon: Icons.volunteer_activism_outlined),
        CellfinCardItem(title: 'Return', icon: Icons.assignment_return_outlined),
      ],
      submitText: 'Save Product',
      fields: [
        StatefulBuilder(
          builder: (context, setDropState) => CellfinDropdownField<int>(
            value: selectedProductId,
            hint: 'Select Product *',
            items: productsList
                .map((p) => DropdownMenuItem<int>(
                      value: p['id'] as int,
                      child: Text(
                        '${p['name'] ?? 'Product #${p['id']}'}${p['price'] != null ? ' (৳${p['price']})' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) => setDropState(() => selectedProductId = v),
          ),
        ),
        CellfinInputField(
          controller: qtyCtrl,
          hint: 'Quantity (Optional, e.g. 10)',
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.format_list_numbered_rounded, color: Color(0xFF6B7280)),
        ),
        StatefulBuilder(
          builder: (context, setDropState) => CellfinDropdownField<bool>(
            value: availability,
            hint: 'Availability Status',
            items: const [
              DropdownMenuItem(value: true, child: Text('In Stock / Available')),
              DropdownMenuItem(value: false, child: Text('Out of Stock / Unavailable')),
            ],
            onChanged: (v) => setDropState(() => availability = v ?? true),
          ),
        ),
        CellfinInputField(
          controller: notesCtrl,
          hint: 'Notes (e.g. Expiring soon, low shelf space)',
          maxLines: 2,
          prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF6B7280)),
        ),
      ],
      onSubmit: () async {
        if (selectedProductId == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a product')));
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
              const SnackBar(content: Text('Product audit saved!'), backgroundColor: _green),
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
        title: const Text('Remove Product Log', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to remove "$name" from this visit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(visitsProvider.notifier).removeProduct(widget.visit.id, visitProductId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product entry removed'), backgroundColor: _green),
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
            Text('Visit #${widget.visit.id} Products',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white)),
            Text('Outlet #${widget.visit.outletId}',
                style: const TextStyle(fontSize: 12, color: Color(0xFFD1FAE5))),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text('Failed to load products: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
                    onPressed: _loadProducts,
                    child: const Text('Retry'),
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
                      decoration: BoxDecoration(color: _green.withOpacity(0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.inventory_2_outlined, size: 54, color: _green),
                    ),
                    const SizedBox(height: 16),
                    const Text('No Products Checked Yet',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('Record product stock availability, quantity, and orders during this visit.',
                        textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _addProduct,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Log Product', style: TextStyle(fontWeight: FontWeight.w700)),
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
                  productName = found['name']?.toString() ?? 'Product #$productId';
                }
                if (productName.isEmpty) productName = 'Product #$productId';

                final quantity = item['quantity'];
                final availability = item['availability'];
                final notes = item['notes']?.toString() ?? '';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.inventory_2_rounded, color: _green, size: 24),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(productName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                        if (availability != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: availability == true
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              availability == true ? 'In Stock' : 'Out of Stock',
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
                          Text('Quantity: $quantity',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                        if (notes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(notes, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                      tooltip: 'Remove',
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
        label: const Text('Log Product', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
