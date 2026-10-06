import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/core/theme/app_theme.dart';
import 'package:field_visit_app/data/models/role_permission_models.dart';
import 'package:field_visit_app/presentation/providers/role_permissions_provider.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';

/// Pick a role, then curate the permissions that role is allowed to use.
class RolePermissionsScreen extends ConsumerStatefulWidget {
  const RolePermissionsScreen({super.key});

  @override
  ConsumerState<RolePermissionsScreen> createState() =>
      _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends ConsumerState<RolePermissionsScreen> {
  String _query = '';
  final Set<String> _collapsed = <String>{};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rolePermissionsProvider);
    final notifier = ref.read(rolePermissionsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'rolePermissions')),
        actions: [
          IconButton(
            tooltip: tr(ref, 'manageRoles'),
            icon: const Icon(Icons.admin_panel_settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RoleDirectoryScreen()),
            ),
          ),
        ],
      ),
      body: (state.error != null && state.roles.isEmpty)
          ? _ErrorView(message: state.error!, onRetry: notifier.load)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: _RoleSelector(
                    roles: state.roles,
                    selectedRole: state.selectedRole,
                    loadingAssignments: state.loadingAssignments,
                    onChanged: notifier.selectRole,
                    onCreate: () => _showCreateRoleSheet(context, ref),
                  ),
                ),
                Expanded(child: _buildBody(state, notifier, isDark)),
              ],
            ),
      bottomNavigationBar: state.selectedRoleId == null
          ? null
          : _SaveBar(state: state, onSave: _save),
    );
  }

  Widget _buildBody(
    RolePermissionsState state,
    RolePermissionsNotifier notifier,
    bool isDark,
  ) {
    if (state.selectedRoleId == null) {
      return _EmptyState(
        icon: Icons.shield_outlined,
        title: tr(ref, 'selectRole'),
        message: tr(ref, 'chooseRoleAbove'),
        action: FilledButton.icon(
          onPressed: () => _showCreateRoleSheet(context, ref),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(tr(ref, 'createRole')),
        ),
      );
    }
    if (state.loadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.permissions.isEmpty) {
      return _EmptyState(
        icon: Icons.key_off_rounded,
        title: tr(ref, 'noPermissionsAvailable'),
        message: tr(ref, 'noPermissionsPublished'),
      );
    }

    final groups = _groupPermissions(state.permissions, _query, context);
    if (groups.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: tr(ref, 'noMatch'),
        message: tr(ref, 'noPermissionMatches'),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        _SearchField(
          query: _query,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        for (final group in groups) ...[
          _PermissionGroupCard(
            title: group.title,
            subtitle: group.subtitle,
            collapsed: _collapsed.contains(group.key),
            selectedCount: group.permissions
                .where((p) => state.selectedPermissionIds.contains(p.id))
                .length,
            totalCount: group.permissions.length,
            isDark: isDark,
            onToggleCollapse: () => setState(() {
              if (!_collapsed.remove(group.key)) _collapsed.add(group.key);
            }),
            onToggleAll: (value) => notifier.toggleMany(
              group.permissions.map((p) => p.id),
              value,
            ),
            children: [
              for (final permission in group.permissions)
                _PermissionTile(
                  permission: permission,
                  value: state.selectedPermissionIds.contains(permission.id),
                  onChanged: (v) => notifier.togglePermission(permission.id, v),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _save() async {
    final notifier = ref.read(rolePermissionsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final role = ref.read(rolePermissionsProvider).selectedRole;
    final ok = await notifier.save();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? tr(ref, 'permissionsSavedFor')
                .replaceAll('{name}', role?.name ?? 'role')
            : tr(ref, 'couldNotSavePermissions')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }
}

/// Role picker.
///
/// Replaces the old `DropdownButtonFormField`, which only read the `name` key
/// and therefore rendered "Unnamed role" for every entry, because
/// `GET /settings/roles/list` returns `select('id','title')`.
class _RoleSelector extends StatelessWidget {
  final List<RoleItem> roles;
  final RoleItem? selectedRole;
  final bool loadingAssignments;
  final ValueChanged<int> onChanged;
  final VoidCallback onCreate;

  const _RoleSelector({
    required this.roles,
    required this.selectedRole,
    required this.loadingAssignments,
    required this.onChanged,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ROLE',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textTertiary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onCreate,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                trOf(context, 'newRole'),
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () => _pick(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: selectedRole == null
                    ? (isDark ? AppColors.darkBorder : AppColors.border)
                    : AppColors.primary,
                width: selectedRole == null ? 1 : 1.4,
              ),
            ),
            child: Row(
              children: [
                if (loadingAssignments)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.shield_rounded,
                    size: 20,
                    color: selectedRole == null
                        ? AppColors.textTertiary
                        : AppColors.primary,
                  ),
                const SizedBox(width: 12),
                Expanded(child: _label(context, theme, isDark)),
                Icon(
                  Icons.unfold_more_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(BuildContext context, ThemeData theme, bool isDark) {
    if (selectedRole == null) {
      return Text(
        trOf(context, 'selectRole'),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          selectedRole!.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        _RoleMetaRow(role: selectedRole!),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _RolePickerSheet(roles: roles, selectedId: selectedRole?.id),
    );
    if (picked != null) onChanged(picked);
  }
}

/// Guard + status + assigned-count chips.
class _RoleMetaRow extends StatelessWidget {
  final RoleItem role;
  const _RoleMetaRow({required this.role});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _MiniChip(
          icon: Icons.shield_outlined,
          label: role.guardName,
          color: AppColors.info,
        ),
        _MiniChip(
          icon: role.isActive
              ? Icons.check_circle_rounded
              : Icons.pause_circle_rounded,
          label: role.isActive
              ? trOf(context, 'active')
              : trOf(context, 'inactive'),
          color: role.isActive ? AppColors.success : AppColors.textTertiary,
        ),
        if (role.permissionCount > 0)
          _MiniChip(
            icon: Icons.key_rounded,
            label: trOf(context, 'assignedCount')
                .replaceAll('{n}', '${role.permissionCount}'),
            color: AppColors.primary,
          ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

/// Searchable role list opened by the picker field.
class _RolePickerSheet extends StatefulWidget {
  final List<RoleItem> roles;
  final int? selectedId;

  const _RolePickerSheet({required this.roles, required this.selectedId});

  @override
  State<_RolePickerSheet> createState() => _RolePickerSheetState();
}

class _RolePickerSheetState extends State<_RolePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final query = _query.trim().toLowerCase();
    final filtered = widget.roles
        .where((r) =>
            query.isEmpty ||
            r.name.toLowerCase().contains(query) ||
            r.guardName.toLowerCase().contains(query))
        .toList();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _SearchField(
                query: _query,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        widget.roles.isEmpty
                            ? trOf(context, 'noRolesYet')
                            : trOf(context, 'noRoleMatches')
                                .replaceAll('{name}', _query),
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _RolePickerTile(
                        role: filtered[i],
                        isSelected: filtered[i].id == widget.selectedId,
                        isDark: isDark,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePickerTile extends StatelessWidget {
  final RoleItem role;
  final bool isSelected;
  final bool isDark;

  const _RolePickerTile({
    required this.role,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected
            ? AppColors.primary.withOpacity(0.08)
            : (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: () => Navigator.of(context).pop(role.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color:
                      isSelected ? AppColors.primary : AppColors.textTertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        role.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      _RoleMetaRow(role: role),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Collapsible card for one `category > group` bucket.
class _PermissionGroupCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool collapsed;
  final int selectedCount;
  final int totalCount;
  final bool isDark;
  final VoidCallback onToggleCollapse;
  final ValueChanged<bool> onToggleAll;
  final List<Widget> children;

  const _PermissionGroupCard({
    required this.title,
    required this.subtitle,
    required this.collapsed,
    required this.selectedCount,
    required this.totalCount,
    required this.isDark,
    required this.onToggleCollapse,
    required this.onToggleAll,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSelected = selectedCount == totalCount && totalCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border:
            Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggleCollapse,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$subtitle  •  $selectedCount/$totalCount',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: allSelected
                        ? trOf(context, 'clearGroup')
                        : trOf(context, 'selectAllInGroup'),
                    child: Checkbox(
                      value: allSelected,
                      onChanged: (v) => onToggleAll(v ?? false),
                    ),
                  ),
                  Icon(
                    collapsed
                        ? Icons.expand_more_rounded
                        : Icons.expand_less_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: collapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.divider,
                ),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One permission row: readable title, raw `name` as secondary text.
class _PermissionTile extends StatelessWidget {
  final PermissionItem permission;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermissionTile({
    required this.permission,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.primary,
      checkboxShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      title: Text(
        permission.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkText : AppColors.textPrimary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: permission.name.isEmpty || permission.name == permission.title
          ? null
          : Text(
              permission.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.query, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: trOf(context, 'searchPermissions'),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),
    );
  }
}

/// Sticky footer: how many permissions are selected + Save.
class _SaveBar extends StatelessWidget {
  final RolePermissionsState state;
  final VoidCallback onSave;

  const _SaveBar({required this.state, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trOf(context, 'selectedOfCount')
                        .replaceAll('{done}', '${state.selectedCount}')
                        .replaceAll(
                            '{total}', '${state.permissions.length}'),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    state.selectedRole?.name ??
                        trOf(context, 'noRoleSelected'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: state.saving ? null : onSave,
              icon: state.saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(trOf(context, 'save')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textTertiary,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.cloud_off_rounded,
      title: trOf(context, 'couldNotLoadRoles'),
      message: message,
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(trOf(context, 'retry')),
      ),
    );
  }
}

/// Groups permissions by the backend's `category > group` breadcrumb.
class _PermissionGroup {
  final String key;
  final String title;
  final String subtitle;
  final List<PermissionItem> permissions;

  const _PermissionGroup({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.permissions,
  });
}

List<_PermissionGroup> _groupPermissions(
  List<PermissionItem> permissions,
  String query,
  BuildContext context,
) {
  final q = query.trim().toLowerCase();
  final filtered = permissions
      .where((p) =>
          q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.group.toLowerCase().contains(q))
      .toList();

  final buckets = <String, List<PermissionItem>>{};
  for (final permission in filtered) {
    final key = '${permission.category}|${permission.group}';
    buckets.putIfAbsent(key, () => []).add(permission);
  }

  final keys = buckets.keys.toList()..sort();
  return keys.map((key) {
    final parts = key.split('|');
    return _PermissionGroup(
      key: key,
      title: _humanize(parts[0], context),
      subtitle: _humanize(parts[1], context),
      permissions: buckets[key]!,
    );
  }).toList();
}

/// "uncategorized" -> "Uncategorized".
String _humanize(String value, BuildContext context) {
  if (value.trim().isEmpty) return trOf(context, 'general');
  final text = value.replaceAll(RegExp('[-_]'), ' ').trim();
  return text[0].toUpperCase() + text.substring(1);
}

/// Turns a raw Dio/provider error into something readable.
String _readableError(Object? error, BuildContext context) {
  if (error == null) return trOf(context, 'couldNotCreateRole');
  var message = error
      .toString()
      .replaceFirst('DioException [connection error]: ', '')
      .replaceFirst('DioException: ', '')
      .trim();
  if (message.isEmpty || message == 'null') {
    return trOf(context, 'couldNotCreateRole');
  }
  return message;
}

/// Bottom sheet for creating a custom role.
Future<void> _showCreateRoleSheet(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();
  final guardController = TextEditingController(text: 'api');
  var isActive = true;
  String? localError;
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(rolePermissionsProvider.notifier);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trOf(context, 'newRole'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  trOf(context, 'createRoleHint'),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: trOf(context, 'roleName'),
                    hintText: trOf(context, 'roleNamePlaceholder'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: guardController,
                  decoration: InputDecoration(
                    labelText: trOf(context, 'guardName'),
                    hintText: 'api',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    trOf(context, 'active'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  value: isActive,
                  onChanged: (v) => setSheetState(() => isActive = v),
                ),
                if (localError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      localError!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(trOf(sheetContext, 'cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            setSheetState(() =>
                                localError = trOf(context, 'roleNameRequired'));
                            return;
                          }
                          final guard = guardController.text.trim();
                          final id = await notifier.createRole(
                            name: name,
                            guardName: guard.isEmpty ? 'api' : guard,
                            isActive: isActive,
                          );
                          if (!sheetContext.mounted) return;
                          if (id != null) {
                            Navigator.of(sheetContext).pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(trOf(sheetContext, 'roleCreated')
                                    .replaceAll('{name}', name)),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            final message = _readableError(
                                ref.read(rolePermissionsProvider).error,
                                sheetContext);
                            setSheetState(() => localError = message);
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(trOf(sheetContext, 'createRole')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );

  nameController.dispose();
  guardController.dispose();
}

/// Lists roles and offers create / toggle-status / delete.
class RoleDirectoryScreen extends ConsumerWidget {
  const RoleDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rolePermissionsProvider);
    final notifier = ref.read(rolePermissionsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'roles'))),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'role_directory_add',
        onPressed: () => _showCreateRoleSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(tr(ref, 'newRole')),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.roles.isEmpty
              ? _EmptyState(
                  icon: Icons.admin_panel_settings_outlined,
                  title: tr(ref, 'noRolesYet'),
                  message: tr(ref, 'createFirstRole'),
                  action: FilledButton.icon(
                    onPressed: () => _showCreateRoleSheet(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(tr(ref, 'createRole')),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: notifier.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: state.roles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final role = state.roles[i];
                      return _RoleDirectoryTile(
                        role: role,
                        isDark: isDark,
                        onToggle: () => notifier.toggleRoleStatus(role.id),
                        onDelete: () async {
                          final ok = await _confirmDelete(context, role.name);
                          if (ok) await notifier.deleteRole(role.id);
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String roleName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(trOf(dialogContext, 'deleteRoleTitle')),
        content: Text(
          trOf(dialogContext, 'deleteRoleBody')
              .replaceAll('{name}', roleName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(trOf(dialogContext, 'cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(trOf(dialogContext, 'delete')),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _RoleDirectoryTile extends StatelessWidget {
  final RoleItem role;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _RoleDirectoryTile({
    required this.role,
    required this.isDark,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_rounded,
            color: role.isActive ? AppColors.primary : AppColors.textTertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  role.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                _RoleMetaRow(role: role),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: trOf(context, 'roleActions'),
            constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
            onSelected: (action) {
              if (action == 'toggle') onToggle();
              if (action == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'toggle',
                  child: Text(trOf(context, 'toggleStatus'))),
              PopupMenuItem(
                  value: 'delete', child: Text(trOf(context, 'deleteRole'))),
            ],
          ),
        ],
      ),
    );
  }
}
