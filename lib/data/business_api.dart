import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:field_visit_app/core/utils/api_client.dart';

/// Gateway-backed API for the business service.
/// All paths are relative to /api/u/business_service/v1.
class BusinessApi {
  final ApiClient client;

  BusinessApi(this.client);

  Future<Response> dashboard() => client.get('/dashboard');
  Future<Response> outlets({Map<String, dynamic>? query}) => client.get('/outlets', queryParameters: query);
  Future<Response> outlet(int id) => client.get('/outlets/$id');
  Future<Response> createOutlet(Map<String, dynamic> data) => client.post('/outlets', data: data);
  Future<Response> updateOutlet(int id, Map<String, dynamic> data) => client.put('/outlets/$id', data: data);
  Future<Response> deleteOutlet(int id) => client.delete('/outlets/$id');
  Future<Response> regenerateOutletQr(int id) => client.post('/outlets/$id/regenerate-qr');
  Future<Response> downloadOutletQr(int id) => client.get('/outlets/$id/download-qr');
  Future<Response> deactivateOutletQr(int id) => client.post('/outlets/$id/deactivate-qr');
  Future<Response> verifyQr(String qrToken) => client.post('/outlets/verify-qr', data: {'qr_token': qrToken});

  Future<Response> assignments({Map<String, dynamic>? query}) => client.get('/outlet-assignments', queryParameters: query);
  Future<Response> assignment(int id) => client.get('/outlet-assignments/$id');
  Future<Response> createAssignment(Map<String, dynamic> data) => client.post('/outlet-assignments', data: data);
  Future<Response> updateAssignment(int id, Map<String, dynamic> data) => client.put('/outlet-assignments/$id', data: data);
  Future<Response> deleteAssignment(int id) => client.delete('/outlet-assignments/$id');

  Future<Response> visits({Map<String, dynamic>? query}) => client.get('/visits', queryParameters: query);
  Future<Response> visit(int id) => client.get('/visits/$id');
  Future<Response> createVisit(Map<String, dynamic> data) => client.post('/visits', data: data);
  Future<Response> updateVisit(int id, Map<String, dynamic> data) => client.put('/visits/$id', data: data);
  Future<Response> deleteVisit(int id) => client.delete('/visits/$id');
  Future<Response> startVisit(Map<String, dynamic> data) => client.post('/visits/start', data: data);
  Future<Response> verifyVisitLocation(int id, Map<String, dynamic> data) => client.post('/visits/$id/verify-location', data: data);
  Future<Response> completeVisit(int id, Map<String, dynamic> data) => client.post('/visits/$id/complete', data: data);
  Future<Response> visitHistory({Map<String, dynamic>? query}) => client.get('/visits/history', queryParameters: query);
  Future<Response> syncVisits(List<Map<String, dynamic>> visits) => client.post('/visits/sync', data: {'visits': visits});
  Future<Response> visitPhotos(int id) => client.get('/visits/$id/photos');
  Future<Response> uploadVisitPhoto(int id, String path, {Map<String, dynamic>? fields}) {
    final form = FormData.fromMap({...?(fields), 'photo': MultipartFile.fromFileSync(path)});
    return client.post('/visits/$id/photos', data: form);
  }
  Future<Response> uploadVisitPhotoBytes(int id, Uint8List bytes, String filename, {String? caption}) {
    final form = FormData.fromMap({
      'photo': MultipartFile.fromBytes(bytes, filename: filename),
      if (caption != null && caption.trim().isNotEmpty) 'caption': caption.trim(),
    });
    return client.post('/visits/$id/photos', data: form);
  }
  Future<Response> visitCompetitors(int id) => client.get('/visits/$id/competitors');
  Future<Response> addVisitCompetitor(int id, Map<String, dynamic> data) => client.post('/visits/$id/competitors', data: data);
  Future<Response> removeVisitCompetitor(int visitId, int competitorId) => client.delete('/visits/$visitId/competitors/$competitorId');
  Future<Response> visitProducts(int id) => client.get('/visits/$id/products');
  Future<Response> addVisitProduct(int id, Map<String, dynamic> data) => client.post('/visits/$id/products', data: data);
  Future<Response> removeVisitProduct(int visitId, int productId) => client.delete('/visits/$visitId/products/$productId');

  Future<Response> orders({Map<String, dynamic>? query}) => client.get('/orders', queryParameters: query);
  Future<Response> order(int id) => client.get('/orders/$id');
  Future<Response> createOrder(Map<String, dynamic> data) => client.post('/orders', data: data);
  Future<Response> updateOrder(int id, Map<String, dynamic> data) => client.put('/orders/$id', data: data);
  Future<Response> deleteOrder(int id) => client.delete('/orders/$id');
  Future<Response> orderItems(int orderId) => client.get('/orders/$orderId/items');
  Future<Response> createOrderItem(int orderId, Map<String, dynamic> data) => client.post('/orders/$orderId/items', data: data);
  Future<Response> updateOrderItem(int orderId, int itemId, Map<String, dynamic> data) => client.put('/orders/$orderId/items/$itemId', data: data);
  Future<Response> deleteOrderItem(int orderId, int itemId) => client.delete('/orders/$orderId/items/$itemId');

  Future<Response> products({Map<String, dynamic>? query}) => client.get('/products', queryParameters: query);
  Future<Response> product(int id) => client.get('/products/$id');
  Future<Response> createProduct(Map<String, dynamic> data) => client.post('/products', data: data);
  Future<Response> updateProduct(int id, Map<String, dynamic> data) => client.put('/products/$id', data: data);
  Future<Response> deleteProduct(int id) => client.delete('/products/$id');
  Future<Response> categories({Map<String, dynamic>? query}) => client.get('/product-categories', queryParameters: query);
  Future<Response> createCategory(Map<String, dynamic> data) => client.post('/product-categories', data: data);
  Future<Response> updateCategory(int id, Map<String, dynamic> data) => client.put('/product-categories/$id', data: data);
  Future<Response> deleteCategory(int id) => client.delete('/product-categories/$id');
  Future<Response> units({Map<String, dynamic>? query}) => client.get('/units', queryParameters: query);
  Future<Response> createUnit(Map<String, dynamic> data) => client.post('/units', data: data);
  Future<Response> updateUnit(int id, Map<String, dynamic> data) => client.put('/units/$id', data: data);
  Future<Response> deleteUnit(int id) => client.delete('/units/$id');
  Future<Response> competitors({Map<String, dynamic>? query}) => client.get('/competitors', queryParameters: query);
  Future<Response> createCompetitor(Map<String, dynamic> data) => client.post('/competitors', data: data);
  Future<Response> updateCompetitor(int id, Map<String, dynamic> data) => client.put('/competitors/$id', data: data);
  Future<Response> deleteCompetitor(int id) => client.delete('/competitors/$id');

  Future<Response> beats({Map<String, dynamic>? query}) => client.get('/beats', queryParameters: query);
  Future<Response> todayBeats({Map<String, dynamic>? query}) => client.get('/beats/today', queryParameters: query);
  Future<Response> beat(int id) => client.get('/beats/$id');
  Future<Response> createBeat(Map<String, dynamic> data) => client.post('/beats', data: data);
  Future<Response> updateBeat(int id, Map<String, dynamic> data) => client.put('/beats/$id', data: data);
  Future<Response> deleteBeat(int id) => client.delete('/beats/$id');
  Future<Response> beatOutlets(int beatId) => client.get('/beats/$beatId/outlets');
  Future<Response> addBeatOutlet(int beatId, Map<String, dynamic> data) => client.post('/beats/$beatId/outlets', data: data);
  Future<Response> removeBeatOutlet(int beatId, int outletId) => client.delete('/beats/$beatId/outlets/$outletId');

  Future<Response> mapOutlets({Map<String, dynamic>? query}) => client.get('/map/outlets', queryParameters: query);
  Future<Response> nearby({required double latitude, required double longitude, double? radius}) => client.get('/map/nearby', queryParameters: {
        'lat': latitude,
        'lng': longitude,
        if (radius != null) 'radius': radius,
      });
  Future<Response> visitReport({Map<String, dynamic>? query}) => client.get('/reports/visits', queryParameters: query);
  Future<Response> orderReport({Map<String, dynamic>? query}) => client.get('/reports/orders', queryParameters: query);
  Future<Response> officerPerformance({Map<String, dynamic>? query}) => client.get('/reports/officer-performance', queryParameters: query);

  Future<Response> notifications({Map<String, dynamic>? query}) => client.get('/notifications', queryParameters: query);
  Future<Response> markNotificationRead(int id) => client.post('/notifications/$id/mark-as-read');
  Future<Response> markAllNotificationsRead() => client.post('/notifications/mark-all-as-read');
  Future<Response> unreadCount() => client.get('/notifications/unread-count');

  Future<Response> kpiSummary({Map<String, dynamic>? query}) => client.get('/kpis/summary', queryParameters: query);
  Future<Response> kpiTargets({Map<String, dynamic>? query}) => client.get('/kpis', queryParameters: query);
  Future<Response> createKpiTarget(Map<String, dynamic> data) => client.post('/kpis', data: data);
  Future<Response> updateKpiTarget(int id, Map<String, dynamic> data) => client.put('/kpis/$id', data: data);
  Future<Response> deleteKpiTarget(int id) => client.delete('/kpis/$id');
}
