import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/providers/orders_provider.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
        child: orders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(message: _errorMessage(error), onRetry: () => ref.read(ordersProvider.notifier).refresh()),
          data: (items) => items.isEmpty
              ? ListView(children: const [SizedBox(height: 240), Center(child: Text('No orders found'))])
              : ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (_, i) => _OrderTile(order: items[i])),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showOrderForm(context, ref), child: const Icon(Icons.add_shopping_cart)),
    );
  }
}

class _OrderTile extends ConsumerWidget {
  final Map<String, dynamic> order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = (order['id'] as num?)?.toInt() ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
        title: Text('Order #$id', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Outlet: ${order['outlet_id'] ?? '-'}\nStatus: ${order['status'] ?? 'pending'}  Total: ${order['total_amount'] ?? 0}'),
        isThreeLine: true,
        onTap: () => _showItems(context, ref, id),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'status') {
              await _updateStatus(context, ref, id);
            } else if (action == 'delete') {
              try { await ref.read(ordersProvider.notifier).remove(id); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(e)))); }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'status', child: Text('Update status')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

Future<void> _showOrderForm(BuildContext context, WidgetRef ref) async {
  final outlets = ref.read(outletsProvider).valueOrNull ?? const [];
  if (outlets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create an outlet first')));
    return;
  }
  int selectedOutlet = outlets.first.id;
  final notes = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(builder: (context, setState) => AlertDialog(
      title: const Text('Create order'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(
          value: selectedOutlet,
          decoration: const InputDecoration(labelText: 'Outlet'),
          items: outlets.map((outlet) => DropdownMenuItem(value: outlet.id, child: Text(outlet.name))).toList(),
          onChanged: (value) => setState(() => selectedOutlet = value ?? selectedOutlet),
        ),
        TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          try {
            await ref.read(ordersProvider.notifier).create({'outlet_id': selectedOutlet, if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim()});
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          } catch (e) { if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_errorMessage(e)))); }
        }, child: const Text('Create')),
      ],
    )),
  );
  notes.dispose();
}

Future<void> _updateStatus(BuildContext context, WidgetRef ref, int id) async {
  String status = 'pending';
  final changed = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setState) => AlertDialog(
    title: const Text('Update status'),
    content: DropdownButtonFormField<String>(value: status, items: const ['pending', 'confirmed', 'delivered', 'cancelled'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => status = v ?? status)),
    actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save'))],
  )));
  if (changed == true) {
    try { await ref.read(ordersProvider.notifier).update(id, {'status': status}); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(e)))); }
  }
}

Future<void> _showItems(BuildContext context, WidgetRef ref, int orderId) async {
  try {
    final items = await ref.read(ordersProvider.notifier).items(orderId);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Order #$orderId items'),
        content: SizedBox(
          width: 420,
          child: items.isEmpty
              ? const Text('No items')
              : ListView(
                  shrinkWrap: true,
                  children: items.map((item) {
                    return ListTile(
                      title: Text('Product #${item['product_id']}'),
                      subtitle: Text('Qty: ${item['quantity']}  Total: ${item['total_price']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref.read(ordersProvider.notifier).deleteItem(orderId, (item['id'] as num).toInt());
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(onPressed: () { Navigator.pop(context); _showAddItem(context, ref, orderId); }, child: const Text('Add item')),
        ],
      ),
    );
  } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(e)))); }
}

Future<void> _showAddItem(BuildContext context, WidgetRef ref, int orderId) async {
  final productId = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final price = TextEditingController(text: '0');
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Add item'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: productId, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Product ID')),
        TextField(controller: quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
        TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit price')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final p = int.tryParse(productId.text);
            final q = int.tryParse(quantity.text) ?? 0;
            final u = int.tryParse(price.text) ?? 0;
            if (p == null || q < 1) return;
            try {
              await ref.read(ordersProvider.notifier).createItem(orderId, {'product_id': p, 'quantity': q, 'unit_price': u, 'total_price': q * u});
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            } catch (e) {
              if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
  productId.dispose(); quantity.dispose(); price.dispose();
}

String _errorMessage(Object error) { if (error is DioException && error.response?.data is Map) { final data = error.response!.data as Map; return (data['message'] ?? data['errors'] ?? error.message).toString(); } return error.toString(); }

class _ErrorView extends StatelessWidget { final String message; final VoidCallback onRetry; const _ErrorView({required this.message, required this.onRetry}); @override Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(message, textAlign: TextAlign.center), const SizedBox(height: 12), ElevatedButton(onPressed: onRetry, child: const Text('Retry'))])); }
