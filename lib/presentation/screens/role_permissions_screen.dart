import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/providers/auth_api_provider.dart';

class RolePermissionsScreen extends ConsumerStatefulWidget {
  const RolePermissionsScreen({super.key});
  @override ConsumerState<RolePermissionsScreen> createState() => _RolePermissionsState();
}

class _RolePermissionsState extends ConsumerState<RolePermissionsScreen> {
  List<Map<String, dynamic>> roles = [];
  List<Map<String, dynamic>> permissions = [];
  int? selectedRole;
  final selected = <int>{};
  bool loading = true;
  String? error;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final api = ref.read(authApiProvider);
      final responses = await Future.wait([api.roleList(), api.permissionList()]);
      List<Map<String, dynamic>> parse(Response response) { final payload = Map<String, dynamic>.from(response.data as Map); final raw = payload['data']; final list = raw is Map ? raw['data'] : raw; return (list as List<dynamic>? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList(); }
      if (!mounted) return;
      setState(() { roles = parse(responses[0]); permissions = parse(responses[1]); loading = false; });
    } catch (e) { if (mounted) setState(() { error = e.toString(); loading = false; }); }
  }

  Future<void> _save() async {
    if (selectedRole == null) return;
    try { await ref.read(authApiProvider).assignRolePermissions(selectedRole!, selected.toList()); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions assigned'))); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_message(e)))); }
  }

  @override Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(appBar: AppBar(title: const Text('Role permissions')), body: Center(child: Text(error!)));
    return Scaffold(
      appBar: AppBar(title: const Text('Role permissions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          DropdownButtonFormField<int>(
            value: selectedRole,
            decoration: const InputDecoration(labelText: 'Role'),
            items: roles.map((role) {
              final id = _intValue(role['id']);
              if (id == null) return null;
              return DropdownMenuItem<int>(value: id, child: Text('${role['name'] ?? 'Unnamed role'}'));
            }).whereType<DropdownMenuItem<int>>().toList(),
            onChanged: (value) => setState(() => selectedRole = value),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: permissions.isEmpty
                ? const Center(child: Text('No permissions found'))
                : ListView(
                    children: permissions.where((permission) => _intValue(permission['id']) != null).map((permission) {
                      final id = _intValue(permission['id'])!;
                      return CheckboxListTile(
                        value: selected.contains(id),
                        title: Text('${permission['title'] ?? permission['name'] ?? ''}'),
                        subtitle: Text('${permission['name'] ?? ''}'),
                        onChanged: selectedRole == null ? null : (value) => setState(() { if (value == true) { selected.add(id); } else { selected.remove(id); } }),
                      );
                    }).toList(),
                  ),
          ),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: selectedRole == null ? null : _save, child: const Text('Save permissions'))),
        ]),
      ),
    );
  }
}

String _message(Object e) => e is DioException && e.response?.data is Map ? ((e.response!.data as Map)['message'] ?? (e.response!.data as Map)['errors'] ?? e.message).toString() : e.toString();

int? _intValue(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
