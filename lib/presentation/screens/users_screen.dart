import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/data/models/user_models.dart';
import 'package:field_visit_app/presentation/providers/users_provider.dart';

/// User directory backed by auth-service `/settings/users`.
///
/// Supports search (server-side, debounced), create, edit (including role
/// assignment) and status toggling. There is no delete on the backend
/// (`UserController` has no `destroy`), so the UI doesn't offer it.
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {}); // refresh the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(usersProvider.notifier).load(search: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersProvider);
    final notifier = ref.read(usersProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(usersProvider, (previous, next) {
      final error = next.error;
      if (!mounted) return;
      if (error != null && error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'users'))),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'users_add',
        onPressed: () => _openSheet(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(tr(ref, 'newUser')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: tr(ref, 'searchUsers'),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                isDense: true,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(state, notifier, isDark)),
        ],
      ),
    );
  }

  Widget _buildBody(
    UsersState state,
    UsersNotifier notifier,
    bool isDark,
  ) {
    if (state.loading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.users.isEmpty) {
      final searching = state.search.isNotEmpty;
      return _UsersEmptyState(
        icon: searching
            ? Icons.person_search_outlined
            : Icons.people_outline_rounded,
        title: searching
            ? tr(ref, 'noUserMatches').replaceAll('{name}', state.search)
            : tr(ref, 'noUsersYet'),
        message:
            searching ? tr(ref, 'tryAnotherSearch') : tr(ref, 'createFirstUser'),
      );
    }
    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: state.users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final user = state.users[i];
          return _UserTile(
            user: user,
            isDark: isDark,
            onTap: () => _openSheet(user: user),
            onToggle: () => notifier.toggleStatus(user.id),
          );
        },
      ),
    );
  }

  Future<void> _openSheet({UserItem? user}) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserSheetForm(user: user),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user == null ? tr(ref, 'userCreated') : tr(ref, 'userUpdated'),
          ),
        ),
      );
    }
  }
}

/// Create / edit bottom sheet.
///
/// Self-contained so the sheet watches [usersProvider] itself (the pushing
/// screen's `ref` must not be used after the sheet closes). When [user] is
/// given, the show endpoint is fetched to hydrate role assignments - the
/// index payload doesn't include `roles`.
class _UserSheetForm extends ConsumerStatefulWidget {
  final UserItem? user;
  const _UserSheetForm({this.user});

  @override
  ConsumerState<_UserSheetForm> createState() => _UserSheetFormState();
}

class _UserSheetFormState extends ConsumerState<_UserSheetForm> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _mobile;
  late final TextEditingController _password;
  late final TextEditingController _confirm;

  late bool _status;
  late final Set<String> _selectedRoles;
  bool _hydratedRoles = false;
  String _localError = '';

  bool get isCreate => widget.user == null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _firstName = TextEditingController(text: user?.firstName);
    _lastName = TextEditingController(text: user?.lastName);
    _email = TextEditingController(text: user?.email);
    _mobile = TextEditingController(text: user?.mobile ?? '');
    _password = TextEditingController();
    _confirm = TextEditingController();
    _status = user?.isActive ?? true;
    _selectedRoles = Set<String>.from(user?.roles ?? const <String>[]);
    _hydratedRoles = isCreate;
    if (!isCreate) _hydrateRoles();
  }

  Future<void> _hydrateRoles() async {
    final detail =
        await ref.read(usersProvider.notifier).fetchUser(widget.user!.id);
    if (!mounted) return;
    if (detail != null) {
      setState(() {
        _selectedRoles
          ..clear()
          ..addAll(detail.roles);
      });
    }
    setState(() => _hydratedRoles = true);
  }

  @override
  void dispose() {
    // Deferred disposal past the sheet's exit animation so the still-
    // animating TextField never reads a disposed controller (the crash
    // source fixed earlier in the roles sheet).
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      _firstName.dispose();
      _lastName.dispose();
      _email.dispose();
      _mobile.dispose();
      _password.dispose();
      _confirm.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isCreate
                        ? trOf(context, 'newUser')
                        : trOf(context, 'editUser'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _field(
              controller: _firstName,
              label: trOf(context, 'firstNameStar'),
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _lastName,
              label: trOf(context, 'lastNameLower'),
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _email,
              label: trOf(context, 'emailAddress'),
              icon: Icons.mail_outline_rounded,
              keyboard: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _mobile,
              label: trOf(context, 'mobileNumber'),
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _password,
              label: isCreate
                  ? trOf(context, 'passwordStar')
                  : trOf(context, 'newPasswordOptional'),
              icon: Icons.lock_outline_rounded,
              obscure: true,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _confirm,
              label: trOf(context, 'confirmPassword'),
              icon: Icons.lock_reset_outlined,
              obscure: true,
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(trOf(context, 'status')),
              subtitle: Text(
                _status ? trOf(context, 'active') : trOf(context, 'inactive'),
              ),
              value: _status,
              onChanged:
                  state.saving ? null : (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 6),
            Text(
              trOf(context, 'assignRoles'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (!_hydratedRoles || (state.roles.isEmpty && state.loadingRoles))
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else if (state.roles.isEmpty)
              Text(
                trOf(context, 'noRolesAvailable'),
                style: const TextStyle(fontSize: 12.5, color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final role in state.roles)
                    FilterChip(
                      label: Text(role.name),
                      selected: _selectedRoles.contains(role.name),
                      onSelected: state.saving
                          ? null
                          : (selected) => setState(() {
                                selected
                                    ? _selectedRoles.add(role.name)
                                    : _selectedRoles.remove(role.name);
                              }),
                    ),
                ],
              ),
            if (_localError.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _localError,
                style:
                    const TextStyle(color: AppColors.error, fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: state.saving ? null : _submit,
                icon: state.saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isCreate ? Icons.check_rounded : Icons.save_rounded,
                        size: 18,
                      ),
                label: Text(
                  isCreate
                      ? trOf(context, 'createUser')
                      : trOf(context, 'save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      setState(() => _localError = error);
      return;
    }
    setState(() => _localError = '');
    final notifier = ref.read(usersProvider.notifier);
    final data = <String, dynamic>{
      'first_name': _firstName.text.trim(),
      'last_name':
          _lastName.text.trim().isEmpty ? null : _lastName.text.trim(),
      'email': _email.text.trim(),
      'mobile': _mobile.text.trim().isEmpty ? null : _mobile.text.trim(),
      'status': _status ? 1 : 0,
      'roles': _selectedRoles.toList(),
    };
    final password = _password.text;
    if (password.isNotEmpty) {
      data['password'] = password;
      data['password_confirmation'] = _confirm.text;
    }
    final result = isCreate
        ? await notifier.createUser(data)
        : await notifier.updateUser(widget.user!.id, data);
    if (result != null) {
      if (mounted) setState(() => _localError = result);
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  /// Client-side mirror of `UserRequest` rules (auth-service).
  String? _validate() {
    if (_firstName.text.trim().isEmpty) {
      return trOf(context, 'firstNameRequired');
    }
    final email = _email.text.trim();
    if (email.isEmpty) return trOf(context, 'emailRequired');
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return trOf(context, 'enterValidEmail');
    }
    final password = _password.text;
    if (isCreate && password.isEmpty) {
      return trOf(context, 'passwordRequired');
    }
    if (password.isNotEmpty && password.length < 8) {
      return trOf(context, 'password8chars');
    }
    if (password.isNotEmpty && password != _confirm.text) {
      return trOf(context, 'passwordMismatch');
    }
    return null;
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        isDense: true,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserItem user;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _UserTile({
    required this.user,
    required this.isDark,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = user.isActive ? AppColors.success : AppColors.error;
    return Card(
      elevation: 0,
      color: isDark ? Colors.white10 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: statusColor.withOpacity(0.12),
          child: Text(
            user.initials,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          user.fullName.isEmpty ? user.email : user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              [
                if (user.email.isNotEmpty) user.email,
                if (user.mobile != null) user.mobile!,
              ].join(' - '),
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (user.roles.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final role in user.roles.take(3)) _RolePill(label: role),
                  if (user.roles.length > 3)
                    _RolePill(label: '+${user.roles.length - 3}'),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          onSelected: (value) {
            if (value == 'edit') onTap();
            if (value == 'toggle') onToggle();
          },
          itemBuilder: (menuContext) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(trOf(menuContext, 'editUser')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    user.isActive
                        ? Icons.person_off_outlined
                        : Icons.how_to_reg_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(trOf(menuContext, 'toggleStatus')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  const _RolePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _UsersEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _UsersEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
