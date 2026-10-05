import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A Google map rendered with the **Maps JavaScript API** inside a WebView.
///
/// The native Android Maps SDK can only read its API key from
/// `AndroidManifest.xml` at process start (flutter/flutter#41244 is still an
/// open proposal), so a key typed into the app could never reach a native
/// `GoogleMap`. With the JS API the key is just a URL parameter, which is what
/// makes the in-app Map Settings form actually take effect.
class RuntimeGoogleMap extends StatefulWidget {
  final String apiKey;

  /// Outlets to pin. Only entries that have coordinates are rendered.
  final List<({double lat, double lng, String name})> pins;

  final double centerLat;
  final double centerLng;
  final double zoom;

  const RuntimeGoogleMap({
    super.key,
    required this.apiKey,
    required this.pins,
    required this.centerLat,
    required this.centerLng,
    this.zoom = 12,
  });

  @override
  State<RuntimeGoogleMap> createState() => _RuntimeGoogleMapState();
}

class _RuntimeGoogleMapState extends State<RuntimeGoogleMap> {
  late final WebViewController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => _ready = true),
      )
      ..loadHtmlString(_buildHtml());
  }

  /// Pushes the pins into the live page (called on every rebuild).
  void _syncPins() {
    if (!_ready) return;
    final json = jsonEncode([
      for (final p in widget.pins) {'lat': p.lat, 'lng': p.lng, 'name': p.name},
    ]);
    _controller.runJavaScript('applyPins($json);');
  }

  void recenter() => _controller.runJavaScript('recenter();');
  void fitAll() => _controller.runJavaScript('fitAll();');

  String _buildHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
  html, body, #map { height: 100%; margin: 0; padding: 0; }
  #map { width: 100%; }
</style>
<script src="https://maps.googleapis.com/maps/api/js?key=${widget.apiKey}"></script>
</head>
<body>
<div id="map"></div>
<script>
  var map = null;
  var markers = [];
  var lastPins = [];

  function init() {
    map = new google.maps.Map(document.getElementById('map'), {
      center: {lat: ${widget.centerLat}, lng: ${widget.centerLng}},
      zoom: ${widget.zoom},
      mapTypeControl: false,
      streetViewControl: false,
      fullscreenControl: false,
      gestureHandling: 'greedy'
    });
  }

  function applyPins(list) {
    lastPins = list;
    markers.forEach(function (m) { m.setMap(null); });
    markers = [];
    var bounds = new google.maps.LatLngBounds();
    list.forEach(function (p) {
      var pos = {lat: p.lat, lng: p.lng};
      markers.push(new google.maps.Marker({
        position: pos, map: map, title: p.name,
        label: {text: '●', color: '#136B3E'}
      }));
      bounds.extend(pos);
    });
    if (list.length > 1) { map.fitBounds(bounds, 70); }
    else if (list.length === 1) { map.setCenter(list[0]); map.setZoom(14); }
  }

  function recenter() {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(function (pos) {
        map.setCenter({lat: pos.coords.latitude, lng: pos.coords.longitude});
        map.setZoom(15);
      });
    }
  }

  function fitAll() { applyPins(lastPins); }

  if (typeof google === 'undefined' || !google.maps) {
    console.log('MAP_ERROR:Google Maps JavaScript API failed to load');
  } else {
    init();
  }
</script>
</body>
</html>''';
  }

  @override
  void didUpdateWidget(covariant RuntimeGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new key means the page has to be rebuilt around the new credential.
    if (oldWidget.apiKey != widget.apiKey) {
      _ready = false;
      _controller.loadHtmlString(_buildHtml());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pins are pushed after the frame so the page is guaranteed to be loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPins());
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (!_ready) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
