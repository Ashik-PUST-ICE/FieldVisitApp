import 'package:dio/dio.dart';
import 'package:field_visit_app/core/utils/api_client.dart';

/// Auth-service API split into public and authenticated gateway clients.
class AuthApi {
  final ApiClient publicClient;
  final ApiClient userClient;

  AuthApi({required this.publicClient, required this.userClient});

  Future<Response> login({required String email, required String password}) =>
      publicClient.post('/auth/login', data: {'email': email, 'password': password});
  Future<Response> register(Map<String, dynamic> data) => publicClient.post('/auth/register', data: data);
  Future<Response> forgotPassword(String email) => publicClient.post('/auth/forgot-password', data: {'email': email});
  Future<Response> changePassword(Map<String, dynamic> data) => userClient.post('/auth/change-password', data: data);
  Future<Response> me() => userClient.get('/me');
  Future<Response> logout() => userClient.post('/logout');
  Future<Response> updateProfile(Map<String, dynamic> data) => userClient.put('/profile', data: data);

  Future<Response> roles({Map<String, dynamic>? query}) => userClient.get('/settings/roles', queryParameters: query);
  Future<Response> role(int id) => userClient.get('/settings/roles/$id');
  Future<Response> createRole(Map<String, dynamic> data) => userClient.post('/settings/roles', data: data);
  Future<Response> updateRole(int id, Map<String, dynamic> data) => userClient.put('/settings/roles/$id', data: data);
  Future<Response> deleteRole(int id) => userClient.delete('/settings/roles/$id');
  Future<Response> roleList() => userClient.get('/settings/roles/list');
  Future<Response> toggleRole(int id) => userClient.patch('/settings/roles/$id/toggle-status');
  Future<Response> assignRolePermissions(int id, List<int> permissions) =>
      userClient.post('/settings/roles/$id/permissions', data: {'permissions': permissions});

  Future<Response> permissions({Map<String, dynamic>? query}) => userClient.get('/settings/permissions', queryParameters: query);
  Future<Response> permission(int id) => userClient.get('/settings/permissions/$id');
  Future<Response> updatePermission(int id, Map<String, dynamic> data) => userClient.put('/settings/permissions/$id', data: data);
  Future<Response> permissionList() => userClient.get('/settings/permissions/list');
  Future<Response> companies({Map<String, dynamic>? query}) => userClient.get('/settings/companies', queryParameters: query);
  Future<Response> createCompany(Map<String, dynamic> data) => userClient.post('/settings/companies', data: data);
  Future<Response> updateCompany(int id, Map<String, dynamic> data) => userClient.put('/settings/companies/$id', data: data);
  Future<Response> deleteCompany(int id) => userClient.delete('/settings/companies/$id');
  Future<Response> users({Map<String, dynamic>? query}) => userClient.get('/settings/users', queryParameters: query);
  Future<Response> user(int id) => userClient.get('/settings/users/$id');
  Future<Response> createUser(Map<String, dynamic> data) => userClient.post('/settings/users', data: data);
  Future<Response> updateUser(int id, Map<String, dynamic> data) => userClient.put('/settings/users/$id', data: data);
  Future<Response> deleteUser(int id) => userClient.delete('/settings/users/$id');
  Future<Response> toggleUser(int id) => userClient.patch('/settings/users/$id/toggle-status');
}
