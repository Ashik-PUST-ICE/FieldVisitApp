/// Domain models + parsers for the Role & Permissions settings module.
///
/// These parsers exist because the auth-service returns three *different*
/// shapes for roles (see `auth-service/.../RoleService.php`):
///
/// * `GET /settings/roles`      -> paginated `RoleResource` with
///   `name`, `guard_name`, `status` ("Active"/"Inactive" label string).
/// * `GET /settings/roles/list` -> `select('id', 'title')` ONLY, so the
///   label lives under `title`, not `name`.
/// * `GET /settings/roles/{id}` -> as index, plus a `permissions` array that
///   holds *titles* by default and *ids* when `?permission_value=id`.
///
/// `GET /settings/permissions/list` returns a nested tree, not a flat list:
/// `[{name: category, groups: [{name: type, permissions: [{id,title,name,group}]}]}]`.
library;

class RoleItem {
  final int id;
  final String name;
  final String guardName;
  final bool isActive;
  final int permissionCount;

  const RoleItem({
    required this.id,
    required this.name,
    required this.guardName,
    required this.isActive,
    this.permissionCount = 0,
  });

  /// Display name, preferring `name` but falling back to the `title` key that
  /// `/roles/list` returns.
  factory RoleItem.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name'] ?? json['title'] ?? '').toString().trim();
    final permissions = json['permissions'];
    return RoleItem(
      id: asInt(json['id']) ?? -1,
      name: rawName.isEmpty ? 'Unnamed role' : rawName,
      guardName: (json['guard_name'] ?? 'api').toString(),
      // `status` is a label ("Active"/"Inactive") from RoleResource, but a
      // 0/1 int when the payload came straight off the model.
      isActive: asBool(json['status']) ?? true,
      permissionCount: permissions is List ? permissions.length : 0,
    );
  }
}

class PermissionItem {
  final int id;
  final String title;
  final String name;
  final String category;
  final String group;

  const PermissionItem({
    required this.id,
    required this.title,
    required this.name,
    required this.category,
    required this.group,
  });

  factory PermissionItem.fromJson(
    Map<String, dynamic> json, {
    String category = 'uncategorized',
    String group = 'general',
  }) {
    final title = (json['title'] ?? json['name'] ?? '').toString().trim();
    return PermissionItem(
      id: asInt(json['id']) ?? -1,
      title: title.isEmpty ? 'Untitled permission' : title,
      name: (json['name'] ?? '').toString(),
      category: category,
      // NOTE: do NOT use the raw `group` column here. The backend stores
      // `"templates-whatsapp"`, while `category`/`group` above are the parsed
      // breadcrumb the UI groups by. Keeping the raw value would make every
      // permission its own bucket.
      group: group,
    );
  }
}

/// Flatten the nested `permissionGroups` response into a single list, keeping
/// the `category > group` breadcrumb on each item so the UI can group them.
List<PermissionItem> parsePermissionTree(dynamic payload) {
  final result = <PermissionItem>[];
  if (payload is! List) return result;

  for (final categoryNode in payload) {
    if (categoryNode is! Map) continue;
    final category = (categoryNode['name'] ?? 'uncategorized').toString();
    final groups = categoryNode['groups'];
    if (groups is! List) continue;

    for (final groupNode in groups) {
      if (groupNode is! Map) continue;
      final group = (groupNode['name'] ?? 'general').toString();
      final permissions = groupNode['permissions'];
      if (permissions is! List) continue;

      for (final permissionNode in permissions) {
        if (permissionNode is! Map) continue;
        final item = PermissionItem.fromJson(
          Map<String, dynamic>.from(permissionNode),
          category: category,
          group: group,
        );
        if (item.id >= 0) result.add(item);
      }
    }
  }
  return result;
}

/// Unwraps the `{ data: ... }` envelope used by `ApiResponse::success`.
/// Handles both `data: [...]` and `data: { data: [...] }`.
List<dynamic> unwrapList(dynamic payload) {
  if (payload is Map) {
    final data = payload['data'];
    if (data is Map) return unwrapList(data);
    if (data is List) return data;
    return const [];
  }
  if (payload is List) return payload;
  return const [];
}

List<RoleItem> parseRoles(dynamic payload) {
  final list = unwrapList(payload);
  final roles = <RoleItem>[];
  for (final node in list) {
    if (node is! Map) continue;
    final role = RoleItem.fromJson(Map<String, dynamic>.from(node));
    if (role.id >= 0) roles.add(role);
  }
  return roles;
}

/// Permission ids currently attached to a role. `RoleResource` returns titles
/// unless `?permission_value=id` is passed, so accept either.
Set<int> parseAssignedPermissionIds(dynamic value) {
  if (value is! List) return <int>{};
  final ids = <int>{};
  for (final node in value) {
    if (node is Map) {
      final id = asInt(node['id']);
      if (id != null) ids.add(id);
    } else {
      final id = asInt(node);
      if (id != null) ids.add(id);
    }
  }
  return ids;
}

int? asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? asBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().trim().toLowerCase();
  if (text == 'active' || text == '1' || text == 'true') return true;
  if (text == 'inactive' || text == '0' || text == 'false') return false;
  return null;
}
