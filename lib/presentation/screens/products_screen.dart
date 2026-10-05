import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/presentation/providers/products_provider.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7), // Soft grey background
      appBar: AppBar(
        backgroundColor: const Color(0xFF136B3E), // Cellfin Signature Forest Green
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Product & Catalog Directory',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Catalog',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              ref.read(productsProvider.notifier).refresh();
              ref.read(categoriesProvider.notifier).refresh();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF136B3E),
            child: TabBar(
              controller: _tabs,
              indicatorColor: const Color(0xFFFFB300), // Golden Yellow Indicator
              indicatorWeight: 3.5,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              tabs: const [
                Tab(
                  icon: Icon(Icons.inventory_2_outlined, size: 20),
                  text: 'Products',
                ),
                Tab(
                  icon: Icon(Icons.category_outlined, size: 20),
                  text: 'Categories',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ─── SEARCH BAR ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search catalog by name or SKU code...',
                hintStyle: const TextStyle(color: Color(0xFF757575), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF136B3E), size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF6B7280)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFC4C4C4), width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFC4C4C4), width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF136B3E), width: 1.5),
                ),
              ),
            ),
          ),

          // ─── TABS VIEW ────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ProductList(searchQuery: _searchQuery),
                _CategoryList(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Product List Tab
class _ProductList extends ConsumerWidget {
  final String searchQuery;
  const _ProductList({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: RefreshIndicator(
        color: const Color(0xFF136B3E),
        onRefresh: () => ref.read(productsProvider.notifier).refresh(),
        child: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF136B3E)),
          ),
          error: (e, _) => _ErrorView(e, () => ref.read(productsProvider.notifier).refresh()),
          data: (items) {
            final filtered = items.where((item) {
              if (searchQuery.isEmpty) return true;
              final name = (item['name']?.toString() ?? '').toLowerCase();
              final code = (item['code']?.toString() ?? '').toLowerCase();
              return name.contains(searchQuery) || code.contains(searchQuery);
            }).toList();

            if (filtered.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF136B3E), size: 32),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No products found',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap + button below to add your first product',
                          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ProductCard(item: filtered[i]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'products_add',
        backgroundColor: const Color(0xFF136B3E),
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () => _showProductOrCategoryForm(context, ref, product: true),
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Category List Tab
class _CategoryList extends ConsumerWidget {
  final String searchQuery;
  const _CategoryList({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: RefreshIndicator(
        color: const Color(0xFF136B3E),
        onRefresh: () => ref.read(categoriesProvider.notifier).refresh(),
        child: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF136B3E)),
          ),
          error: (e, _) => _ErrorView(e, () => ref.read(categoriesProvider.notifier).refresh()),
          data: (items) {
            final filtered = items.where((item) {
              if (searchQuery.isEmpty) return true;
              final name = (item['name']?.toString() ?? '').toLowerCase();
              final code = (item['code']?.toString() ?? '').toLowerCase();
              return name.contains(searchQuery) || code.contains(searchQuery);
            }).toList();

            if (filtered.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.category_outlined, color: Color(0xFF136B3E), size: 32),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No categories found',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap + button below to add your first category',
                          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _CategoryCard(item: filtered[i]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'products_category_add',
        backgroundColor: const Color(0xFF136B3E),
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () => _showProductOrCategoryForm(context, ref, product: false),
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Premium Cellfin Product Card
class _ProductCard extends ConsumerWidget {
  final Map<String, dynamic> item;
  const _ProductCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = item['name']?.toString() ?? 'Unnamed Product';
    final code = item['code']?.toString() ?? 'SKU-${item['id']}';
    final price = item['price'];
    final description = item['description']?.toString() ?? '';
    final id = (item['id'] as num).toInt();

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
          onTap: () => _showProductOrCategoryForm(context, ref, product: true, item: item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: const Center(
                    child: Icon(Icons.inventory_2_rounded, color: Color(0xFF136B3E), size: 24),
                  ),
                ),
                const SizedBox(width: 14),

                // Center Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Code & Price Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // SKU Code Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),

                          // Price Badge with ৳
                          if (price != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1), // Golden Tint
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFFE082)),
                              ),
                              child: Text(
                                '৳ $price',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),

                          // Active Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'In Catalog',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF136B3E),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Right Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF136B3E)),
                      tooltip: 'Edit Product',
                      onPressed: () => _showProductOrCategoryForm(context, ref, product: true, item: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                      tooltip: 'Delete Product',
                      onPressed: () => _confirmDelete(context, () async {
                        await ref.read(productsProvider.notifier).remove(id);
                      }),
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

/// Premium Cellfin Category Card
class _CategoryCard extends ConsumerWidget {
  final Map<String, dynamic> item;
  const _CategoryCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = item['name']?.toString() ?? 'Unnamed Category';
    final code = item['code']?.toString() ?? 'CAT-${item['id']}';
    final description = item['description']?.toString() ?? '';
    final id = (item['id'] as num).toInt();

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
          onTap: () => _showProductOrCategoryForm(context, ref, product: false, item: item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Center(
                    child: Icon(Icons.category_rounded, color: Color(0xFF0284C7), size: 24),
                  ),
                ),
                const SizedBox(width: 14),

                // Center Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Code & Type Row
                      Wrap(
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Category Node',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Right Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF136B3E)),
                      tooltip: 'Edit Category',
                      onPressed: () => _showProductOrCategoryForm(context, ref, product: false, item: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                      tooltip: 'Delete Category',
                      onPressed: () => _confirmDelete(context, () async {
                        await ref.read(categoriesProvider.notifier).remove(id);
                      }),
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

/// Delete Confirmation Dialog
Future<void> _confirmDelete(BuildContext context, Future<void> Function() onConfirm) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      content: const Text('Are you sure you want to remove this item from the catalog? This action cannot be undone.'),
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
      await onConfirm();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully'), backgroundColor: Color(0xFF136B3E)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error(e))),
        );
      }
    }
  }
}

/// NEW FULL-SCREEN CELLFIN FORM FOR ADD/EDIT PRODUCT & CATEGORY
/// Replaces the old basic AlertDialog with the exact 4-card system and clean Cellfin inputs!
Future<void> _showProductOrCategoryForm(
  BuildContext context,
  WidgetRef ref, {
  required bool product,
  Map<String, dynamic>? item,
}) async {
  final name = TextEditingController(text: item?['name']?.toString());
  final code = TextEditingController(text: item?['code']?.toString());
  final price = TextEditingController(text: item?['price']?.toString());
  final description = TextEditingController(text: item?['description']?.toString());

  // 4 Top Cards per user's reference photograph
  final cards = product
      ? const [
          CellfinCardItem(title: 'Standard', icon: Icons.inventory_2_outlined),
          CellfinCardItem(title: 'Best Seller', icon: Icons.star_outline_rounded),
          CellfinCardItem(title: 'New SKU', icon: Icons.fiber_new_rounded),
          CellfinCardItem(title: 'Bulk Carton', icon: Icons.all_inbox_rounded),
        ]
      : const [
          CellfinCardItem(title: 'FMCG Goods', icon: Icons.category_outlined),
          CellfinCardItem(title: 'Beverages', icon: Icons.local_drink_outlined),
          CellfinCardItem(title: 'Snacks & Food', icon: Icons.fastfood_outlined),
          CellfinCardItem(title: 'Personal Care', icon: Icons.spa_outlined),
        ];

  await CellfinFormScreen.push(
    context: context,
    title: item == null
        ? (product ? 'Add New Product' : 'Add New Category')
        : (product ? 'Edit Product SKU' : 'Edit Category'),
    cards: cards,
    officerName: 'MD. ASHIKUR RAHMAN',
    officerInfo: '01748 031 295 (Sales Catalog Officer)',
    submitText: item == null
        ? (product ? 'Submit Product' : 'Submit Category')
        : 'Save Changes',
    fields: [
      // Name Field
      CellfinInputField(
        controller: name,
        hint: product ? 'Product Title / Name *' : 'Category Title / Name *',
        prefixIcon: Icon(
          product ? Icons.inventory_2_outlined : Icons.category_outlined,
          color: const Color(0xFF6B7280),
        ),
        validator: (v) => v == null || v.trim().isEmpty
            ? (product ? 'Product name is required' : 'Category name is required')
            : null,
      ),

      // Code / SKU Field
      CellfinInputField(
        controller: code,
        hint: product ? 'SKU / Item Code (e.g. PRD-102)' : 'Category Code (e.g. CAT-01)',
        prefixIcon: const Icon(Icons.qr_code_rounded, color: Color(0xFF6B7280)),
      ),

      // Price Field (For Product) with '৳' Suffix!
      if (product)
        CellfinInputField(
          controller: price,
          keyboardType: TextInputType.number,
          hint: 'Retail Unit Price',
          prefixIcon: const Icon(Icons.sell_outlined, color: Color(0xFF6B7280)),
          suffixText: '৳',
          validator: (v) {
            if (v != null && v.trim().isNotEmpty && int.tryParse(v.trim()) == null) {
              return 'Enter a valid number';
            }
            return null;
          },
        ),

      // Description / Note Field
      CellfinInputField(
        controller: description,
        maxLines: 3,
        hint: product ? 'Product Details & Pack Size' : 'Category Description & Scope',
        prefixIcon: const Icon(Icons.note_alt_outlined, color: Color(0xFF6B7280)),
      ),
    ],
    onSubmit: () async {
      final data = <String, dynamic>{
        'name': name.text.trim(),
        if (code.text.trim().isNotEmpty) 'code': code.text.trim(),
        if (product && price.text.trim().isNotEmpty) 'price': int.tryParse(price.text.trim()),
        if (description.text.trim().isNotEmpty) 'description': description.text.trim(),
      };

      try {
        final id = (item?['id'] as num?)?.toInt();
        if (product) {
          if (id == null) {
            await ref.read(productsProvider.notifier).create(data);
          } else {
            await ref.read(productsProvider.notifier).update(id, data);
          }
        } else {
          if (id == null) {
            await ref.read(categoriesProvider.notifier).create(data);
          } else {
            await ref.read(categoriesProvider.notifier).update(id, data);
          }
        }

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(product ? 'Product saved successfully!' : 'Category saved successfully!'),
              backgroundColor: const Color(0xFF136B3E),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
        }
      }
    },
  );

  name.dispose();
  code.dispose();
  price.dispose();
  description.dispose();
}

String _error(Object e) => e is DioException && e.response?.data is Map
    ? ((e.response!.data as Map)['message'] ?? (e.response!.data as Map)['errors'] ?? e.message).toString()
    : e.toString();

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback retry;
  const _ErrorView(this.error, this.retry);

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
              Text(
                _error(error),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF374151), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF136B3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: retry,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
}
