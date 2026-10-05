import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/business_api.dart';
import 'package:field_visit_app/data/models/visit.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

final visitsProvider =
    StateNotifierProvider<VisitsNotifier, AsyncValue<List<Visit>>>((ref) {
  return VisitsNotifier(ref.watch(businessApiProvider));
});

class VisitsNotifier extends StateNotifier<AsyncValue<List<Visit>>> {
  final BusinessApi api;

  VisitsNotifier(this.api) : super(const AsyncValue.data([])) {
    fetchVisits();
  }

  Future<void> fetchVisits({Map<String, dynamic>? queryParams}) async {
    state = const AsyncValue.loading();
    try {
      final response = await api.visits(query: queryParams);
      final payload = Map<String, dynamic>.from(response.data as Map);
      final raw = payload['data'];
      final list = raw is Map ? raw['data'] : raw;
      final visits = (list as List<dynamic>? ?? const [])
          .map((item) => Visit.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      state = AsyncValue.data(visits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> start(
      {required int outletId,
      required String latitude,
      required String longitude}) async {
    await api.startVisit(
        {'outlet_id': outletId, 'latitude': latitude, 'longitude': longitude});
    await fetchVisits();
  }

  Future<void> verifyLocation(int id,
      {required String latitude, required String longitude}) async {
    await api.verifyVisitLocation(
        id, {'latitude': latitude, 'longitude': longitude});
    await fetchVisits();
  }

  Future<void> complete(int id, {String? remarks}) async {
    await api.completeVisit(id, {
      if (remarks != null && remarks.trim().isNotEmpty)
        'remarks': remarks.trim()
    });
    await fetchVisits();
  }

  Future<void> remove(int id) async {
    await api.deleteVisit(id);
    await fetchVisits();
  }

  // --- Visit Photos ---
  Future<List<Map<String, dynamic>>> getPhotos(int visitId) async {
    final response = await api.visitPhotos(visitId);
    final payload = Map<String, dynamic>.from(response.data as Map);
    final raw = payload['data'];
    return (raw is List ? raw : const <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> uploadPhoto(int visitId, Uint8List bytes, String filename,
      {String? caption}) async {
    await api.uploadVisitPhotoBytes(visitId, bytes, filename, caption: caption);
  }

  // --- Visit Competitors ---
  Future<List<Map<String, dynamic>>> getCompetitors(int visitId) async {
    final response = await api.visitCompetitors(visitId);
    final payload = Map<String, dynamic>.from(response.data as Map);
    final raw = payload['data'];
    return (raw is List ? raw : const <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> addCompetitor(int visitId,
      {required int competitorId, String? notes}) async {
    await api.addVisitCompetitor(visitId, {
      'competitor_id': competitorId,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
  }

  Future<void> removeCompetitor(int visitId, int visitCompetitorId) async {
    await api.removeVisitCompetitor(visitId, visitCompetitorId);
  }

  // --- Visit Products ---
  Future<List<Map<String, dynamic>>> getProducts(int visitId) async {
    final response = await api.visitProducts(visitId);
    final payload = Map<String, dynamic>.from(response.data as Map);
    final raw = payload['data'];
    return (raw is List ? raw : const <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> addProduct(
    int visitId, {
    required int productId,
    int? quantity,
    bool? availability,
    String? notes,
  }) async {
    await api.addVisitProduct(visitId, {
      'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (availability != null) 'availability': availability,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
  }

  Future<void> removeProduct(int visitId, int visitProductId) async {
    await api.removeVisitProduct(visitId, visitProductId);
  }

  Future<void> refresh() => fetchVisits();
}

/// Fetches the completed visit history from /visits/history.
final visitHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(businessApiProvider);
  final response = await api.visitHistory();
  final payload = Map<String, dynamic>.from(response.data as Map);
  final raw = payload['data'];
  final list = raw is Map ? raw['data'] : raw;
  return (list as List<dynamic>? ?? const [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
});
