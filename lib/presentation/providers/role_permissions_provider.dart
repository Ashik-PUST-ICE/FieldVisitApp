import 'package:field_visit_app/data/auth_api.dart';
import 'package:field_visit_app/data/models/role_permission_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/providers/auth_api_provider.dart';

/// Immutable state for the Role & Permissions screen.
class RolePermissionsState {
  final List<RoleItem> roles;
  final List<PermissionItem> permissions;
  final int? selectedRoleId;
  final Set<int> selectedPermissionIds;
  final bool loading;
  final bool loadingAssignments;
  final bool saving;
  final String? error;

  const RolePermissionsState({
    this.roles = const [],
    this.permissions = const [],
    this.selectedRoleId,
    this.selectedPermissionIds = const {},
    this.loading = true,
    this.loadingAssignments = false,
    this.saving = false,
    this.error,
  });

  RoleItem? get selectedRole {
    if (selectedRoleId == null) return null;
    for (final role in roles) {
      if (role.id == selectedRoleId) return role;
    }
    return null;
  }

  int get selectedCount => selectedPermissionIds.length;

  RolePermissionsState copyWith({
    List<RoleItem>? roles,
    List<PermissionItem>? permissions,
    int? selectedRoleId,
    Set<int>? selectedPermissionIds,
    bool? loading,
    bool? loadingAssignments,
    bool? saving,
    String? error,
    bool clearError = false,
  }) {
    return RolePermissionsState(
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      selectedRoleId: selectedRoleId ?? this.selectedRoleId,
      selectedPermissionIds:
          selectedPermissionIds ?? this.selectedPermissionIds,
      loading: loading ?? this.loading,
      loadingAssignments: loadingAssignments ?? this.loadingAssignments,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RolePermissionsNotifier extends StateNotifier<RolePermissionsState> {
  final AuthApi api;

  /// Server-side selection, used to tell "dirty" edits apart from saved ones.
  final Set<int> _baseline = <int>{};

  RolePermissionsNotifier(this.api) : super(const RolePermissionsState()) {
    load();
  }

  bool get hasUnsavedChanges =>
      !_setEquals(_baseline, state.selectedPermissionIds);

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final responses = await Future.wait([
        api.roles(query: {'per_page': 200}),
        api.permissionList(),
      ]);
      state = state.copyWith(
        roles: parseRoles(responses[0].data),
        permissions: parsePermissionTree(unwrapList(responses[1].data)),
        loading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Selects a role and hydrates the checklist with its current permissions.
  Future<void> selectRole(int roleId) async {
    state = state.copyWith(
      selectedRoleId: roleId,
      loadingAssignments: true,
      selectedPermissionIds: const {},
      clearError: true,
    );
    try {
      final response = await api.roleWithPermissions(roleId);
      final payload = response.data;
      final roleJson = payload is Map && payload['data'] is Map
          ? Map<String, dynamic>.from(payload['data'] as Map)
          : <String, dynamic>{};
      final assigned = parseAssignedPermissionIds(roleJson['permissions']);
      _baseline
        ..clear()
        ..addAll(assigned);
      state = state.copyWith(
        selectedPermissionIds: assigned,
        loadingAssignments: false,
      );
    } catch (e) {
      state = state.copyWith(loadingAssignments: false, error: e.toString());
    }
  }

  void togglePermission(int permissionId, bool value) {
    final next = Set<int>.from(state.selectedPermissionIds);
    value ? next.add(permissionId) : next.remove(permissionId);
    state = state.copyWith(selectedPermissionIds: next, clearError: true);
  }

  void toggleMany(Iterable<int> ids, bool value) {
    final next = Set<int>.from(state.selectedPermissionIds);
    value ? next.addAll(ids) : next.removeAll(ids);
    state = state.copyWith(selectedPermissionIds: next, clearError: true);
  }

  Future<bool> save() async {
    final roleId = state.selectedRoleId;
    if (roleId == null) return false;
    state = state.copyWith(saving: true, clearError: true);
    try {
      final ids = state.selectedPermissionIds.toList()..sort();
      await api.assignRolePermissions(roleId, ids);
      _baseline
        ..clear()
        ..addAll(ids);
      state = state.copyWith(saving: false);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }

  /// Creates a custom role, refreshes the list and selects the new role.
  Future<int?> createRole({
    required String name,
    String guardName = 'api',
    bool isActive = true,
  }) async {
    try {
      final response = await api.createRole({
        'name': name,
        'guard_name': guardName,
        'status': isActive ? 1 : 0,
      });
      await load();
      final payload = response.data;
      final created = payload is Map && payload['data'] is Map
          ? Map<String, dynamic>.from(payload['data'] as Map)
          : <String, dynamic>{};
      final newId = asInt(created['id']);
      if (newId != null) await selectRole(newId);
      return newId;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> deleteRole(int id) async {
    try {
      await api.deleteRole(id);
      if (state.selectedRoleId == id) _baseline.clear();
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> toggleRoleStatus(int id) async {
    try {
      await api.toggleRole(id);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

bool _setEquals(Set<int> a, Set<int> b) =>
    a.length == b.length && a.containsAll(b);

final rolePermissionsProvider =
    StateNotifierProvider<RolePermissionsNotifier, RolePermissionsState>(
  (ref) => RolePermissionsNotifier(ref.watch(authApiProvider)),
);
