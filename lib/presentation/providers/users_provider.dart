import 'package:field_visit_app/core/utils/api_error.dart';
import 'package:field_visit_app/data/auth_api.dart';
import 'package:field_visit_app/data/models/role_permission_models.dart';
import 'package:field_visit_app/data/models/user_models.dart';
import 'package:field_visit_app/presentation/providers/auth_api_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the User management screen (auth-service `/settings/users`).
///
/// The role catalogue is kept here too so the create/edit sheet can offer
/// role chips; it is loaded once in the background and merged in from the
/// roles index (which, unlike `/roles/list`, carries the `name` field the
/// backend validates against `exists:roles,name`).
class UsersState {
  final List<UserItem> users;
  final List<RoleItem> roles;
  final bool loading;
  final bool loadingRoles;
  final bool saving;
  final String search;
  final String? error;

  const UsersState({
    this.users = const [],
    this.roles = const [],
    this.loading = true,
    this.loadingRoles = false,
    this.saving = false,
    this.search = '',
    this.error,
  });

  UsersState copyWith({
    List<UserItem>? users,
    List<RoleItem>? roles,
    bool? loading,
    bool? loadingRoles,
    bool? saving,
    String? search,
    String? error,
    bool clearError = false,
  }) {
    return UsersState(
      users: users ?? this.users,
      roles: roles ?? this.roles,
      loading: loading ?? this.loading,
      loadingRoles: loadingRoles ?? this.loadingRoles,
      saving: saving ?? this.saving,
      search: search ?? this.search,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UsersNotifier extends StateNotifier<UsersState> {
  final AuthApi api;

  UsersNotifier(this.api) : super(const UsersState()) {
    load();
    _loadRoles();
  }

  Future<void> load({String? search}) async {
    final query = (search ?? state.search).trim();
    state = state.copyWith(loading: true, search: query, clearError: true);
    try {
      final response = await api.users(query: {
        'per_page': 100,
        if (query.isNotEmpty) 'search': query,
      });
      state = state.copyWith(
        users: parseUsers(response.data),
        loading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: friendlyApiError(e, fallback: 'Could not load users'),
      );
    }
  }

  /// Role catalogue for the assign-roles chips. Failures here are not
  /// fatal — the sheet simply renders without chips.
  Future<void> _loadRoles() async {
    state = state.copyWith(loadingRoles: true);
    try {
      final response = await api.roles(query: {'per_page': 200});
      state = state.copyWith(
        roles: parseRoles(response.data),
        loadingRoles: false,
      );
    } catch (_) {
      state = state.copyWith(loadingRoles: false);
    }
  }

  /// Full detail for one user (show endpoint hydrates `roles`).
  Future<UserItem?> fetchUser(int id) async {
    try {
      final response = await api.user(id);
      return parseUser(response.data);
    } catch (e) {
      state = state.copyWith(error: friendlyApiError(e));
      return null;
    }
  }

  /// Returns null on success or a human-readable message on failure, so the
  /// sheet can show it inline without popping.
  Future<String?> createUser(Map<String, dynamic> data) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await api.createUser(data);
      state = state.copyWith(saving: false);
      await load();
      return null;
    } catch (e) {
      state = state.copyWith(saving: false);
      return friendlyApiError(e);
    }
  }

  Future<String?> updateUser(int id, Map<String, dynamic> data) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await api.updateUser(id, data);
      state = state.copyWith(saving: false);
      await load();
      return null;
    } catch (e) {
      state = state.copyWith(saving: false);
      return friendlyApiError(e);
    }
  }

  Future<void> toggleStatus(int id) async {
    try {
      await api.toggleUser(id);
      await load();
    } catch (e) {
      state = state.copyWith(error: friendlyApiError(e));
    }
  }
}

final usersProvider =
    StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  return UsersNotifier(ref.watch(authApiProvider));
});
