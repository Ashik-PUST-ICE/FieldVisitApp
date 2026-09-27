import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/auth_api.dart';
import 'package:field_visit_app/presentation/providers/auth_api_provider.dart';

final usersProvider = StateNotifierProvider<DirectoryNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) => DirectoryNotifier(ref.watch(authApiProvider), true));
final companiesProvider = StateNotifierProvider<DirectoryNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) => DirectoryNotifier(ref.watch(authApiProvider), false));

class DirectoryNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final AuthApi api; final bool users;
  DirectoryNotifier(this.api, this.users) : super(const AsyncValue.data([])) { fetch(); }
  Future<void> fetch() async { state = const AsyncValue.loading(); try { final response = users ? await api.users() : await api.companies(); final payload = Map<String, dynamic>.from(response.data as Map); final raw = payload['data']; final list = raw is Map ? raw['data'] : raw; state = AsyncValue.data((list as List<dynamic>? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList()); } catch (e, st) { state = AsyncValue.error(e, st); } }
  Future<void> save(Map<String, dynamic> data, int? id) async { if (users) { if (id == null) await api.createUser(data); else await api.updateUser(id, data); } else { if (id == null) await api.createCompany(data); else await api.updateCompany(id, data); } await fetch(); }
  Future<void> remove(int id) async { if (users) await api.deleteUser(id); else await api.deleteCompany(id); await fetch(); }
  Future<void> toggle(int id) async { await api.toggleUser(id); await fetch(); }
}
