import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/providers/notifications_provider.dart';

const Color _green = Color(0xFF136B3E);
const Color _accent = Color(0xFFFFB300);

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Alerts',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread alert${unreadCount > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: Color(0xFFD1FAE5)),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: _accent),
              onPressed: () async {
                await ref.read(notificationsProvider.notifier).markAllRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('All notifications marked as read'),
                        backgroundColor: _green),
                  );
                }
              },
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark All Read',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref
                .read(notificationsProvider.notifier)
                .fetch(unreadOnly: _unreadOnly),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('All Alerts', false),
                const SizedBox(width: 8),
                _buildFilterChip('Unread Only', true),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // List
          Expanded(
            child: RefreshIndicator(
              color: _green,
              onRefresh: () => ref
                  .read(notificationsProvider.notifier)
                  .fetch(unreadOnly: _unreadOnly),
              child: state.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: _green)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_error(e), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white),
                          onPressed: () => ref
                              .read(notificationsProvider.notifier)
                              .fetch(unreadOnly: _unreadOnly),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (items) {
                  final filtered = items.where((n) {
                    if (_unreadOnly) return n['read_at'] == null;
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
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: _green.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.notifications_off_outlined,
                                    size: 54,
                                    color: _green),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _unreadOnly
                                    ? 'No Unread Notifications'
                                    : 'No Notifications Found',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'You are all caught up with your visits, beats, and system alerts.',
                                style: TextStyle(
                                    color: Color(0xFF6B7280), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = filtered[i];
                      final isRead = n['read_at'] != null;
                      final title =
                          n['title'] ?? n['type'] ?? 'System Notification';
                      final message = n['message'] ?? '';
                      final createdAt = n['created_at']?.toString() ?? '';
                      final id = (n['id'] as num?)?.toInt() ?? 0;

                      return Container(
                        decoration: BoxDecoration(
                          color:
                              isRead ? Colors.white : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isRead
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF86EFAC),
                            width: isRead ? 1 : 1.2,
                          ),
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
                            onTap: isRead
                                ? null
                                : () async {
                                    if (id > 0) {
                                      await ref
                                          .read(notificationsProvider.notifier)
                                          .markRead(id);
                                    }
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isRead
                                          ? const Color(0xFFF1F5F9)
                                          : _green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isRead
                                          ? Icons.notifications_none_rounded
                                          : Icons.notifications_active_rounded,
                                      color: isRead
                                          ? const Color(0xFF64748B)
                                          : _green,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title.toString(),
                                                style: TextStyle(
                                                  fontWeight: isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.w800,
                                                  fontSize: 14,
                                                  color:
                                                      const Color(0xFF1E293B),
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: _green,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (message.toString().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            message.toString(),
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF475569)),
                                          ),
                                        ],
                                        if (createdAt.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            createdAt,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF94A3B8)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool unread) {
    final isSelected = _unreadOnly == unread;
    return InkWell(
      onTap: () {
        setState(() => _unreadOnly = unread);
        ref.read(notificationsProvider.notifier).fetch(unreadOnly: unread);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _green : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

String _error(Object e) => e is DioException && e.response?.data is Map
    ? ((e.response!.data as Map)['message'] ?? e.message).toString()
    : e.toString();
