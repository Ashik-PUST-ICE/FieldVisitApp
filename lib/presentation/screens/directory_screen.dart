import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/presentation/providers/directory_provider.dart';

const _green = Color(0xFF136B3E);

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryState();
}

class _DirectoryState extends ConsumerState<DirectoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          tr(ref, 'userDirectory'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: _green,
            child: TabBar(
              controller: _tabs,
              indicatorColor: const Color(0xFFFFB300),
              indicatorWeight: 3.5,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: [
                Tab(
                    icon: const Icon(Icons.person_outline_rounded, size: 18),
                    text: tr(ref, 'users')),
                Tab(
                    icon: const Icon(Icons.business_outlined, size: 18),
                    text: tr(ref, 'companies')),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _DirectoryList(users: true),
          _DirectoryList(users: false),
        ],
      ),
    );
  }
}

class _DirectoryList extends ConsumerWidget {
  final bool users;
  const _DirectoryList({required this.users});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = users ? usersProvider : companiesProvider;
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: RefreshIndicator(
        color: _green,
        onRefresh: notifier.fetch,
        child: state.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _green)),
          error: (e, _) => Center(
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
                    child: const Icon(Icons.error_outline_rounded,
                        color: Colors.red, size: 40),
                  ),
                  const SizedBox(height: 14),
                  Text(_message(e),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF374151))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: notifier.fetch,
                    child: Text(tr(ref, 'retry')),
                  ),
                ],
              ),
            ),
          ),
          data: (items) => items.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 160),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              users
                                  ? Icons.people_outline_rounded
                                  : Icons.business_outlined,
                              color: _green,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            users ? tr(ref, 'noUsersFound') : tr(ref, 'noCompaniesFound'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr(ref, 'tapBelowToAdd'),
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final id = (item['id'] as num).toInt();
                    return _DirectoryCard(
                      item: item,
                      isUser: users,
                      onEdit: () => _form(context, ref, users, item),
                      onToggle: users
                          ? () async {
                              try {
                                await notifier.toggle(id);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(_message(e))));
                                }
                              }
                            }
                          : null,
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            title: Text(tr(ref, 'confirmDelete'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            content: Text(tr(ref, 'removeFromDirectory')
                                .replaceAll('{name}', (users ? (item['full_name'] ?? item['first_name'] ?? '') : (item['name'] ?? '')).toString())),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(tr(ref, 'cancel'),
                                    style: const TextStyle(
                                        color: Color(0xFF6B7280))),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(tr(ref, 'delete')),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          try {
                            await notifier.remove(id);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_message(e))));
                            }
                          }
                        }
                      },
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'directory_add',
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () => _form(context, ref, users, null),
        icon: const Icon(Icons.person_add_outlined),
        label: Text(
            users ? tr(ref, 'addUser') : tr(ref, 'addCompany'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isUser;
  final VoidCallback onEdit;
  final VoidCallback? onToggle;
  final VoidCallback onDelete;

  const _DirectoryCard({
    required this.item,
    required this.isUser,
    required this.onEdit,
    this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = isUser
        ? (item['full_name'] ??
                '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}')
            .toString()
            .trim()
        : (item['name'] ?? '').toString();
    final subtitle = isUser
        ? (item['email'] ?? '').toString()
        : (item['slug'] ?? '').toString();
    final status = (item['status'] ?? '').toString().toLowerCase();
    final isActive = status == 'active' || status == '1' || status == 'true';

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
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUser
                          ? const Color(0xFFC8E6C9)
                          : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isUser ? Icons.person_rounded : Icons.business_rounded,
                      color: isUser ? _green : const Color(0xFF0284C7),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? trOf(context, 'unnamed') : name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                              fontSize: 12.5, color: Color(0xFF6B7280)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive
                              ? trOf(context, 'active')
                              : (status.isEmpty
                                  ? trOf(context, 'notAvailable')
                                  : status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive ? _green : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onToggle != null)
                      IconButton(
                        icon: Icon(
                          isActive
                              ? Icons.toggle_on_rounded
                              : Icons.toggle_off_rounded,
                          size: 22,
                          color: isActive ? _green : const Color(0xFF9CA3AF),
                        ),
                        tooltip: trOf(context, 'toggleStatus'),
                        onPressed: onToggle,
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: _green),
                      tooltip: trOf(context, 'edit'),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Color(0xFFEF4444)),
                      tooltip: trOf(context, 'delete'),
                      onPressed: onDelete,
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

Future<void> _form(
  BuildContext context,
  WidgetRef ref,
  bool users,
  Map<String, dynamic>? item,
) async {
  final first = TextEditingController(
      text: item?['first_name']?.toString() ?? item?['name']?.toString());
  final last = TextEditingController(text: item?['last_name']?.toString());
  final email = TextEditingController(text: item?['email']?.toString());
  final slug = TextEditingController(text: item?['slug']?.toString());
  final password = TextEditingController();

  await CellfinFormScreen.push(
    context: context,
    title: item == null
        ? (users
            ? tr(ref, 'addNewUser')
            : tr(ref, 'addCompany'))
        : (users ? tr(ref, 'editUserProfile') : tr(ref, 'editCompany')),
    officerName: tr(ref, 'directoryManagement'),
    officerInfo:
        users ? tr(ref, 'userAccountConfig') : tr(ref, 'companyProfileSetup'),
    cards: users
        ? [
            CellfinCardItem(
                title: tr(ref, 'salesRep'), icon: Icons.badge_outlined),
            CellfinCardItem(
                title: tr(ref, 'manager'),
                icon: Icons.manage_accounts_outlined),
            CellfinCardItem(
                title: tr(ref, 'supervisor'),
                icon: Icons.supervisor_account_outlined),
            CellfinCardItem(
                title: tr(ref, 'admin'),
                icon: Icons.admin_panel_settings_outlined),
          ]
        : [
            CellfinCardItem(
                title: tr(ref, 'distributor'),
                icon: Icons.local_shipping_outlined),
            CellfinCardItem(
                title: tr(ref, 'retailer'), icon: Icons.store_outlined),
            CellfinCardItem(
                title: tr(ref, 'wholesaler'), icon: Icons.warehouse_outlined),
            CellfinCardItem(
                title: tr(ref, 'partner'), icon: Icons.handshake_outlined),
          ],
    submitText: item == null
        ? (users ? tr(ref, 'createUser') : tr(ref, 'addCompany'))
        : tr(ref, 'saveChangesLower'),
    fields: [
      CellfinInputField(
        controller: first,
        hint: users
            ? '${tr(ref, 'firstNameStar')} *'
            : '${tr(ref, 'companyName')} *',
        prefixIcon: Icon(
          users ? Icons.person_outline_rounded : Icons.business_outlined,
          color: const Color(0xFF6B7280),
        ),
        validator: (v) => v == null || v.trim().isEmpty
            ? tr(ref, 'thisFieldRequired')
            : null,
      ),
      if (users) ...[
        CellfinInputField(
          controller: last,
          hint: tr(ref, 'lastNameLower'),
          prefixIcon: const Icon(Icons.person_outline_rounded,
              color: Color(0xFF6B7280)),
        ),
        CellfinInputField(
          controller: email,
          hint: '${tr(ref, 'emailAddress')} *',
          keyboardType: TextInputType.emailAddress,
          prefixIcon:
              const Icon(Icons.email_outlined, color: Color(0xFF6B7280)),
          validator: (v) => v == null || v.trim().isEmpty
              ? tr(ref, 'emailRequired')
              : null,
        ),
        if (item == null)
          CellfinInputField(
            controller: password,
            hint: '${tr(ref, 'passwordStar')} *',
            obscureText: true,
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: Color(0xFF6B7280)),
            validator: (v) => v == null || v.trim().isEmpty
                ? tr(ref, 'passwordRequired')
                : null,
          ),
      ] else
        CellfinInputField(
          controller: slug,
          hint: tr(ref, 'companySlug'),
          prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF6B7280)),
        ),
    ],
    onSubmit: () async {
      final data = users
          ? <String, dynamic>{
              'first_name': first.text.trim(),
              'last_name': last.text.trim(),
              'email': email.text.trim(),
              if (item == null) 'password': password.text,
              if (item == null) 'password_confirmation': password.text,
            }
          : <String, dynamic>{
              'name': first.text.trim(),
              'slug': slug.text.trim(),
            };
      try {
        await ref
            .read((users ? usersProvider : companiesProvider).notifier)
            .save(data, (item?['id'] as num?)?.toInt());
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(item == null
                      ? tr(ref, 'recordCreated')
                      : tr(ref, 'recordUpdated')),
              backgroundColor: _green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_message(e))));
        }
      }
    },
  );

  first.dispose();
  last.dispose();
  email.dispose();
  slug.dispose();
  password.dispose();
}

String _message(Object e) => e is DioException && e.response?.data is Map
    ? ((e.response!.data as Map)['message'] ??
            (e.response!.data as Map)['errors'] ??
            e.message)
        .toString()
    : e.toString();
