import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/business_api.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

final productsProvider = StateNotifierProvider<ProductsNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ProductsNotifier(ref.watch(businessApiProvider));
});

class ProductsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final BusinessApi api;
  ProductsNotifier(this.api) : super(const AsyncValue.data([])) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _list(await api.products()));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    await api.createProduct(data);
    await fetch();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await api.updateProduct(id, data);
    await fetch();
  }

  Future<void> remove(int id) async {
    await api.deleteProduct(id);
    await fetch();
  }

  Future<void> refresh() => fetch();
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return CategoriesNotifier(ref.watch(businessApiProvider));
});

class CategoriesNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final BusinessApi api;
  CategoriesNotifier(this.api) : super(const AsyncValue.data([])) {
    fetch();
  }
  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _list(await api.categories()));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    await api.createCategory(data);
    await fetch();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await api.updateCategory(id, data);
    await fetch();
  }

  Future<void> remove(int id) async {
    await api.deleteCategory(id);
    await fetch();
  }

  Future<void> refresh() => fetch();
}

Future<List<Map<String, dynamic>>> _list(dynamic response) async {
  final payload = Map<String, dynamic>.from(response.data as Map);
  final raw = payload['data'];
  final list = raw is Map ? raw['data'] : raw;
  return (list as List<dynamic>? ?? const [])
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
}
