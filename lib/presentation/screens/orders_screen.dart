import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/presentation/providers/orders_provider.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';
import 'package:field_visit_app/core/widgets/app_dropdown.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'fieldOrders'),
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: tr(ref, 'refresh'),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(ordersProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
        child: orders.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (error, _) => _ErrorView(
            message: _errorMessage(error),
            onRetry: () => ref.read(ordersProvider.notifier).refresh(),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 140),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_bag_outlined,
                              size: 48, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(tr(ref, 'noOrdersFound'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text(
                            'Tap "Book Order" below to create your first order',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
              itemCount: items.length,
              itemBuilder: (_, i) => _OrderCard(order: items[i]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'orders_add',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: () => _showOrderForm(context, ref),
        icon: const Icon(Icons.add_shopping_cart_rounded, size: 22),
        label: Text(tr(ref, 'bookOrder'),
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = (order['id'] as num?)?.toInt() ?? 0;
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final total = order['total_amount'] ?? 0;

    Color statusColor;
    Color statusBg;
    String statusLabel;

    if (status.contains('delivered') || status.contains('confirmed')) {
      statusColor = const Color(0xFF10B981);
      statusBg = const Color(0xFFD1FAE5);
      statusLabel = status.toUpperCase();
    } else if (status.contains('cancel')) {
      statusColor = const Color(0xFFEF4444);
      statusBg = const Color(0xFFFEE2E2);
      statusLabel = 'CANCELLED';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusBg = const Color(0xFFFEF3C7);
      statusLabel = 'PENDING';
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Color(0xFF6366F1), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${tr(ref, 'orderHash')}$id',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? statusColor.withOpacity(0.2)
                                  : statusBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Outlet ID: ${order['outlet_id'] ?? '-'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '৳ $total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
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
                InkWell(
                  onTap: () => _showItems(context, ref, id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 16, color: Color(0xFF0D9488)),
                        SizedBox(width: 4),
                        Text(tr(ref, 'orderLineItems'),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0D9488))),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, size: 22),
                  onSelected: (action) async {
                    if (action == 'status') {
                      await _updateStatus(context, ref, id);
                    } else if (action == 'delete') {
                      try {
                        await ref.read(ordersProvider.notifier).remove(id);
                      } catch (e) {
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_errorMessage(e))));
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'status', child: Text(tr(ref, 'updateStatus'))),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text(tr(ref, 'deleteOrder'),
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

Future<void> _showOrderForm(BuildContext context, WidgetRef ref) async {
  final outlets = ref.read(outletsProvider).valueOrNull ?? const [];
  if (outlets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'createOutletFirst'))));
    return;
  }
  int selectedOutlet = outlets.first.id;
  final notes = TextEditingController();

  await CellfinFormModal.show(
    context: context,
    title: tr(ref, 'bookRetailOrder'),
    cards: [
      CellfinCardItem(
          title: tr(ref, 'standard'), icon: Icons.shopping_bag_outlined),
      CellfinCardItem(title: tr(ref, 'priority'), icon: Icons.bolt_rounded),
      CellfinCardItem(title: tr(ref, 'cashCod'), icon: Icons.payments_outlined),
      CellfinCardItem(
          title: tr(ref, 'bulkOrder'), icon: Icons.inventory_2_outlined),
    ],
    submitText: tr(ref, 'submit'),
    fields: [
      StatefulBuilder(
        builder: (context, setDropState) => AppDropdownField<int>(
          label: tr(ref, 'receiverOutletAccount'),
          hint: tr(ref, 'selectOutletLower'),
          value: selectedOutlet,
          options: outlets
              .map((outlet) => AppDropdownOption<int>(
                    value: outlet.id,
                    title: outlet.name,
                    leadingIcon: Icons.storefront_outlined,
                  ))
              .toList(),
          onChanged: (value) =>
              setDropState(() => selectedOutlet = value ?? selectedOutlet),
        ),
      ),
      CellfinInputField(
        controller: notes,
        maxLines: 2,
        hint: tr(ref, 'orderNote'),
        prefixIcon:
            const Icon(Icons.note_alt_outlined, color: Color(0xFF6B7280)),
      ),
    ],
    onSubmit: () async {
      try {
        await ref.read(ordersProvider.notifier).create({
          'outlet_id': selectedOutlet,
          if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
        });
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(tr(ref, 'orderBooked')),
                backgroundColor: AppColors.cellfinGreen),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_errorMessage(e))));
        }
      }
    },
  );
  notes.dispose();
}

Future<void> _updateStatus(BuildContext context, WidgetRef ref, int id) async {
  String status = 'pending';
  final changed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr(ref, 'updateOrderStatus'),
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: AppDropdownField<String>(
          label: tr(ref, 'status'),
          icon: Icons.local_shipping_rounded,
          value: status,
          options: const ['pending', 'confirmed', 'delivered', 'cancelled']
              .map((v) => AppDropdownOption<String>(
                    value: v,
                    title: v.toUpperCase(),
                  ))
              .toList(),
          onChanged: (v) => setState(() => status = v ?? status),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(tr(ref, 'cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(ref, 'saveStatus')),
          ),
        ],
      ),
    ),
  );
  if (changed == true) {
    try {
      await ref.read(ordersProvider.notifier).update(id, {'status': status});
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    }
  }
}

Future<void> _showItems(
    BuildContext context, WidgetRef ref, int orderId) async {
  try {
    final items = await ref.read(ordersProvider.notifier).items(orderId);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
            tr(ref, 'orderLineItemsFor').replaceAll('{id}', '$orderId'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: Text(tr(ref, 'noLineItems'))),
                )
              : ListView(
                  shrinkWrap: true,
                  children: items.map((item) {
                    final itemId = (item['id'] as num).toInt();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.inventory_rounded,
                              color: AppColors.primary),
                        ),
                        title: Text(
                            '${tr(ref, 'productHash')}${item['product_id']}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            'Qty: ${item['quantity']} • Unit: ৳${item['unit_price'] ?? 0} • Total: ৳${item['total_price']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded,
                                  color: AppColors.primary, size: 20),
                              tooltip: tr(ref, 'editItem'),
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditItem(
                                    context, ref, orderId, itemId, item);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.red, size: 20),
                              tooltip: tr(ref, 'removeItem'),
                              onPressed: () async {
                                await ref
                                    .read(ordersProvider.notifier)
                                    .deleteItem(orderId, itemId);
                                if (context.mounted) Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showAddItem(context, ref, orderId);
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(tr(ref, 'addLineItem')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(ref, 'close')),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage(e))));
  }
}

Future<void> _showAddItem(
    BuildContext context, WidgetRef ref, int orderId) async {
  final productId = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final price = TextEditingController(text: '0');

  await CellfinFormModal.show(
    context: context,
    title: tr(ref, 'addOrderLineItem'),
    cards: [
      CellfinCardItem(
          title: tr(ref, 'itemUnits'), icon: Icons.inventory_2_outlined),
      CellfinCardItem(
          title: tr(ref, 'masterBox'), icon: Icons.all_inbox_rounded),
      CellfinCardItem(
          title: tr(ref, 'sampleFree'), icon: Icons.card_giftcard_rounded),
      CellfinCardItem(
          title: tr(ref, 'urgentDispatch'),
          icon: Icons.local_shipping_outlined),
    ],
    submitText: tr(ref, 'submit'),
    fields: [
      CellfinInputField(
        controller: productId,
        keyboardType: TextInputType.number,
        hint: '${tr(ref, 'productId')} *',
        prefixIcon:
            const Icon(Icons.inventory_2_outlined, color: Color(0xFF6B7280)),
        validator: (v) => v == null || v.trim().isEmpty
            ? tr(ref, 'productIdRequired')
            : null,
      ),
      CellfinInputField(
        controller: quantity,
        keyboardType: TextInputType.number,
        hint: '${tr(ref, 'quantityPcs')} *',
        prefixIcon: const Icon(Icons.format_list_numbered_rounded,
            color: Color(0xFF6B7280)),
        validator: (v) => v == null || v.trim().isEmpty
            ? tr(ref, 'quantityRequired')
            : null,
      ),
      CellfinInputField(
        controller: price,
        keyboardType: TextInputType.number,
        hint: tr(ref, 'amountUnitPrice'),
        suffixText: '৳',
        validator: (v) => v == null || v.trim().isEmpty
            ? tr(ref, 'priceRequired')
            : null,
      ),
    ],
    onSubmit: () async {
      final p = int.tryParse(productId.text);
      final q = int.tryParse(quantity.text) ?? 0;
      final u = int.tryParse(price.text) ?? 0;
      if (p == null || q < 1) return;
      try {
        await ref.read(ordersProvider.notifier).createItem(orderId, {
          'product_id': p,
          'quantity': q,
          'unit_price': u,
          'total_price': q * u,
        });
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(tr(ref, 'itemAdded')),
                backgroundColor: AppColors.cellfinGreen),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_errorMessage(e))));
        }
      }
    },
  );
  productId.dispose();
  quantity.dispose();
  price.dispose();
}

Future<void> _showEditItem(BuildContext context, WidgetRef ref, int orderId,
    int itemId, Map<String, dynamic> item) async {
  final quantity = TextEditingController(text: '${item['quantity'] ?? 1}');
  final price = TextEditingController(text: '${item['unit_price'] ?? 0}');

  await CellfinFormModal.show(
    context: context,
    title: tr(ref, 'editLineItem').replaceAll('{id}', '$itemId'),
    cards: [
      CellfinCardItem(title: tr(ref, 'updateQty'), icon: Icons.edit_rounded),
      CellfinCardItem(
          title: tr(ref, 'reprice'), icon: Icons.price_change_rounded),
      CellfinCardItem(
          title: tr(ref, 'correction'), icon: Icons.edit_note_rounded),
      CellfinCardItem(
          title: tr(ref, 'discount'), icon: Icons.discount_outlined),
    ],
    submitText: tr(ref, 'updateItem'),
    fields: [
      CellfinInputField(
        controller: quantity,
        keyboardType: TextInputType.number,
        hint: '${tr(ref, 'updatedQuantity')} *',
        prefixIcon: const Icon(Icons.format_list_numbered_rounded,
            color: Color(0xFF6B7280)),
        validator: (v) => v == null || v.trim().isEmpty
            ? tr(ref, 'quantityRequired')
            : null,
      ),
      CellfinInputField(
        controller: price,
        keyboardType: TextInputType.number,
        hint: tr(ref, 'updatedUnitPrice'),
        suffixText: '৳',
        validator: (v) => v == null || v.trim().isEmpty
            ? tr(ref, 'priceRequired')
            : null,
      ),
    ],
    onSubmit: () async {
      final q = int.tryParse(quantity.text) ?? 0;
      final u = int.tryParse(price.text) ?? 0;
      if (q < 1) return;
      try {
        await ref.read(ordersProvider.notifier).updateItem(orderId, itemId, {
          'quantity': q,
          'unit_price': u,
          'total_price': q * u,
        });
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(tr(ref, 'itemUpdated')),
                backgroundColor: AppColors.cellfinGreen),
          );
        }
      } catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_errorMessage(e))));
      }
    },
  );
  quantity.dispose();
  price.dispose();
}

String _errorMessage(Object error) {
  if (error is DioException && error.response?.data is Map) {
    final data = error.response!.data as Map;
    return (data['message'] ?? data['errors'] ?? error.message).toString();
  }
  return error.toString();
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              child: Text(trOf(context, 'retry')),
            ),
          ],
        ),
      );
}
