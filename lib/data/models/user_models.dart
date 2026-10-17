/// Domain models + parsers for the Users settings module (auth-service
/// `/settings/users`).
///
/// Backend shapes (verified against `UserController` / `UserService` /
/// `UserResource`):
/// * `GET  /settings/users`      -> `ApiResponse::success(paginator)` =
///   `{success, message, data: {current_page, data: [UserResource], ...}}`.
///   `roles` is NOT eager-loaded on index, so list rows have no roles.
/// * `GET  /settings/users/{id}` -> `{success, message, data: UserResource}`
///   with `roles` = list of role NAMES (loaded via `$user->load('roles')`).
/// * `POST/PUT /settings/users`  -> accepts `first_name`, `last_name`,
///   `email`, `mobile`, `password` (+`password_confirmation`, required on
///   create, blank-to-keep on update), `status` (0/1) and `roles`
///   (array of role *names*, `exists:roles,name`).
/// * There is NO delete endpoint — `UserController` has no `destroy`
///   method, so the UI deliberately offers create / edit / toggle only.
library;

import 'role_permission_models.dart' show asBool, asInt, unwrapList;

class UserItem {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String uniqueId;
  final String email;
  final String? mobile;
  final bool isActive;
  final String? lastLoginAt;

  /// Role NAMES attached to the user. Only populated by the show endpoint
  /// (or after an edit fetch) — the index payload omits them.
  final List<String> roles;

  const UserItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.uniqueId,
    required this.email,
    this.mobile,
    this.isActive = true,
    this.lastLoginAt,
    this.roles = const [],
  });

  /// Avatar initials: "A" / "AB" from the name parts, falling back to the
  /// email's first letter when both names are empty.
  String get initials {
    final source =
        fullName.trim().isNotEmpty ? fullName : (email.isNotEmpty ? email : '?');
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.isEmpty ? '' : parts.last.substring(0, 1);
    return (parts.first.substring(0, 1) + last).toUpperCase();
  }

  factory UserItem.fromJson(
    Map<String, dynamic> json, {
    List<String>? roles,
  }) {
    final first = (json['first_name'] ?? '').toString().trim();
    final last = (json['last_name'] ?? '').toString().trim();
    final serverFull = (json['full_name'] ?? '').toString().trim();
    final email = (json['email'] ?? '').toString().trim();
    final mobile = (json['mobile'] ?? '').toString().trim();
    final rawLastLogin = (json['last_login_at'] ?? '').toString().trim();
    final rawRoles = json['roles'];

    return UserItem(
      id: asInt(json['id']) ?? -1,
      firstName: first,
      lastName: last,
      fullName: serverFull.isNotEmpty ? serverFull : '$first $last'.trim(),
      uniqueId: (json['unique_id'] ?? '').toString(),
      email: email,
      mobile: mobile.isEmpty ? null : mobile,
      isActive: asBool(json['status']) ?? true,
      lastLoginAt: rawLastLogin.isEmpty ? null : rawLastLogin,
      roles: roles ??
          (rawRoles is List
              ? rawRoles.map((e) => e.toString()).toList()
              : const <String>[]),
    );
  }
}

/// Parses the paginated index payload. [unwrapList] recurses through the
/// `{data: {data: [...]}}` nesting, so the full envelope, a bare paginator
/// and a plain list all work.
List<UserItem> parseUsers(dynamic payload) {
  final users = <UserItem>[];
  for (final node in unwrapList(payload)) {
    if (node is! Map) continue;
    final user = UserItem.fromJson(Map<String, dynamic>.from(node));
    if (user.id >= 0) users.add(user);
  }
  return users;
}

/// Single user from the show endpoint (`data` envelope). Returns null when
/// the payload doesn't hold a user object.
UserItem? parseUser(dynamic payload) {
  final data = payload is Map ? payload['data'] : null;
  if (data is! Map) return null;
  final user = UserItem.fromJson(Map<String, dynamic>.from(data));
  return user.id >= 0 ? user : null;
}
