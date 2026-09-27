import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/providers/products_provider.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});
  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Products'), bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Products'), Tab(text: 'Categories')])),
        body: TabBarView(controller: _tabs, children: [_ProductList(), _CategoryList()]),
      );
}

class _ProductList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsProvider);
    return Scaffold(
      body: RefreshIndicator(onRefresh: () => ref.read(productsProvider.notifier).refresh(), child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(e, () => ref.read(productsProvider.notifier).refresh()),
        data: (items) => items.isEmpty ? ListView(children: const [SizedBox(height: 220), Center(child: Text('No products found'))]) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (_, i) => _ProductTile(item: items[i])),
      )),
      floatingActionButton: FloatingActionButton(onPressed: () => _showForm(context, ref, product: true), child: const Icon(Icons.add)),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoriesProvider);
    return Scaffold(
      body: RefreshIndicator(onRefresh: () => ref.read(categoriesProvider.notifier).refresh(), child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(e, () => ref.read(categoriesProvider.notifier).refresh()),
        data: (items) => items.isEmpty ? ListView(children: const [SizedBox(height: 220), Center(child: Text('No categories found'))]) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (_, i) => _CategoryTile(item: items[i])),
      )),
      floatingActionButton: FloatingActionButton(onPressed: () => _showForm(context, ref, product: false), child: const Icon(Icons.add)),
    );
  }
}

class _ProductTile extends ConsumerWidget { final Map<String, dynamic> item; const _ProductTile({required this.item}); @override Widget build(BuildContext context, WidgetRef ref) => _Tile(item: item, icon: Icons.inventory_2, onEdit: () => _showForm(context, ref, product: true, item: item), onDelete: () => ref.read(productsProvider.notifier).remove((item['id'] as num).toInt())); }
class _CategoryTile extends ConsumerWidget { final Map<String, dynamic> item; const _CategoryTile({required this.item}); @override Widget build(BuildContext context, WidgetRef ref) => _Tile(item: item, icon: Icons.category, onEdit: () => _showForm(context, ref, product: false, item: item), onDelete: () => ref.read(categoriesProvider.notifier).remove((item['id'] as num).toInt())); }

class _Tile extends StatelessWidget {
  final Map<String, dynamic> item; final IconData icon; final VoidCallback onEdit; final Future<void> Function() onDelete;
  const _Tile({required this.item, required this.icon, required this.onEdit, required this.onDelete});
  @override Widget build(BuildContext context) => Card(child: ListTile(leading: CircleAvatar(child: Icon(icon)), title: Text('${item['name'] ?? ''}'), subtitle: Text('${item['code'] ?? 'No code'}  •  ${item['status'] ?? ''}'), onTap: onEdit, trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { try { await onDelete(); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e)))); } }))); }
Future<void> _showForm(BuildContext context, WidgetRef ref, {required bool product, Map<String, dynamic>? item}) async {
  final name = TextEditingController(text: item?['name']?.toString());
  final code = TextEditingController(text: item?['code']?.toString());
  final price = TextEditingController(text: item?['price']?.toString());
  final description = TextEditingController(text: item?['description']?.toString());
  await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: Text('${item == null ? 'Add' : 'Edit'} ${product ? 'product' : 'category'}'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')), TextField(controller: code, decoration: const InputDecoration(labelText: 'Code')), if (product) TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')), if (!product) TextField(controller: description, decoration: const InputDecoration(labelText: 'Description'))])), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () async { if (name.text.trim().isEmpty) return; final data = <String, dynamic>{'name': name.text.trim(), if (code.text.trim().isNotEmpty) 'code': code.text.trim(), if (product && price.text.trim().isNotEmpty) 'price': int.tryParse(price.text.trim()), if (!product && description.text.trim().isNotEmpty) 'description': description.text.trim()}; try { final id = (item?['id'] as num?)?.toInt(); if (product) { if (id == null) await ref.read(productsProvider.notifier).create(data); else await ref.read(productsProvider.notifier).update(id, data); } else { if (id == null) await ref.read(categoriesProvider.notifier).create(data); else await ref.read(categoriesProvider.notifier).update(id, data); } if (dialogContext.mounted) Navigator.pop(dialogContext); } catch (e) { if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_error(e)))); } }, child: const Text('Save'))]));
  name.dispose(); code.dispose(); price.dispose(); description.dispose();
}

String _error(Object e) => e is DioException && e.response?.data is Map ? ((e.response!.data as Map)['message'] ?? (e.response!.data as Map)['errors'] ?? e.message).toString() : e.toString();
class _ErrorView extends StatelessWidget { final Object error; final VoidCallback retry; const _ErrorView(this.error, this.retry); @override Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_error(error), textAlign: TextAlign.center), ElevatedButton(onPressed: retry, child: const Text('Retry'))])); }
