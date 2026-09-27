import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/auth_api.dart';
import 'package:field_visit_app/presentation/providers/auth_api_provider.dart';

final rolesProvider = StateNotifierProvider<AuthSettingsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) => AuthSettingsNotifier(ref.watch(authApiProvider), true));
final permissionsProvider = StateNotifierProvider<AuthSettingsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) => AuthSettingsNotifier(ref.watch(authApiProvider), false));

class AuthSettingsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final AuthApi api; final bool roles;
  AuthSettingsNotifier(this.api, this.roles) : super(const AsyncValue.data([])) { fetch(); }
  Future<void> fetch() async { state = const AsyncValue.loading(); try { final response = roles ? await api.roles() : await api.permissions(); final payload = Map<String, dynamic>.from(response.data as Map); final raw = payload['data']; final list = raw is Map ? raw['data'] : raw; state = AsyncValue.data((list as List<dynamic>? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList()); } catch (e, st) { state = AsyncValue.error(e, st); } }
  Future<void> save(Map<String, dynamic> data, int? id) async { if (id == null) await api.createRole(data); else await api.updateRole(id, data); await fetch(); }
  Future<void> remove(int id) async { await api.deleteRole(id); await fetch(); }
  Future<void> toggle(int id) async { await api.toggleRole(id); await fetch(); }
}
