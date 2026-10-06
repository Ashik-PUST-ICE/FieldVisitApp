import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';
import 'package:field_visit_app/core/utils/map_credentials_store.dart';
import 'package:field_visit_app/core/widgets/runtime_google_map.dart';
import 'package:field_visit_app/data/models/outlet.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';
import 'package:field_visit_app/presentation/screens/map_settings_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  /// In google_maps_flutter 2.x there is no public constructor; the instance is
  /// handed to us through [GoogleMap.onMapCreated].
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  String _search = '';
  int? _selectedOutletId;
  bool _sheetCollapsed = false;
  double _nearbyRadius = 5000;

  /// Why the map has no blue dot, or null while everything is fine.
  String? _locationProblem;

  /// Camera used when the device location is unavailable, so the map still
  /// renders instead of the screen showing only an error string.
  static const _fallbackCenter = LatLng(23.8103, 90.4125); // Dhaka

  /// The Google Maps key saved in Map Settings. Null means none yet.
  String? _apiKey;
  final _credentials = MapCredentialsStore();

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await _credentials.read();
    if (!mounted || key == null) return;
    setState(() => _apiKey = key);
  }

  /// Pins derived from the loaded outlets, in the shape the WebView map wants.
  List<({double lat, double lng, String name})> get _pins {
    final query = _search.trim().toLowerCase();
    return [
      for (final outlet in ref.read(outletsProvider).valueOrNull ?? const [])
        if (outlet.latitude != null && outlet.longitude != null)
          if (query.isEmpty || outlet.name.toLowerCase().contains(query))
            (
              lat: outlet.latitude!,
              lng: outlet.longitude!,
              name: outlet.name,
            ),
    ];
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _requestPermissions();
    await _getCurrentLocation();
    _buildMarkers();
  }

  Future<void> _requestPermissions() async {
    // Geolocator's own check explains WHY location is unavailable (service off
    // vs permission denied), which permission_handler alone does not.
    if (!await Geolocator.isLocationServiceEnabled()) {
      _setProblem('Turn on location services to show your position');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      _setProblem('Location permission is blocked. Enable it in Settings.');
      return;
    }
    if (permission == LocationPermission.denied) {
      _setProblem('Location permission denied');
    }
  }

  void _setProblem(String message) {
    if (!mounted) return;
    setState(() {
      _locationProblem = message;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _locationProblem = null;
      });
    } catch (e) {
      // Keep the map usable - fall back to the city view rather than hiding it.
      _setProblem('Could not get your location - showing outlet map instead');
    }
  }

  /// Recomputes the outlet markers from the currently loaded outlets.
  ///
  /// This used to be a one-shot `ref.read` inside `initState`, which ran before
  /// the outlet list had arrived, so the map never showed a single pin. It is
  /// now also driven by a `ref.listen` below.
  void _buildMarkers() {
    final outlets = ref.read(outletsProvider).valueOrNull ?? const [];
    final query = _search.trim().toLowerCase();
    final matches = query.isEmpty
        ? outlets
        : outlets.where((o) => o.name.toLowerCase().contains(query)).toList();

    final pins = <Marker>{};
    for (final outlet in matches) {
      if (outlet.latitude == null || outlet.longitude == null) continue;
      pins.add(
        Marker(
          markerId: MarkerId('outlet_${outlet.id}'),
          position: LatLng(outlet.latitude!, outlet.longitude!),
          infoWindow: InfoWindow(title: outlet.name),
        ),
      );
    }
    setState(() => _markers
      ..clear()
      ..addAll(pins));
  }

  /// Frames every outlet that has coordinates.
  Future<void> _fitOutlets() async {
    final controller = _mapController;
    if (controller == null) return;
    final points = _markers.map((m) => m.position).toList(growable: false);
    if (points.isEmpty) return;

    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 15),
        ),
      );
      return;
    }

    // google_maps_flutter 2.x has no LatLngBounds.fromPoints, so build the
    // south-west / north-east corners by hand.
    var south = points.first.latitude;
    var north = points.first.latitude;
    var west = points.first.longitude;
    var east = points.first.longitude;
    for (final p in points) {
      south = p.latitude < south ? p.latitude : south;
      north = p.latitude > north ? p.latitude : north;
      west = p.longitude < west ? p.longitude : west;
      east = p.longitude > east ? p.longitude : east;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        80, // padding
      ),
    );
  }

  /// Moves the camera back to the device position.
  Future<void> _recenter() async {
    final position = _currentPosition;
    final controller = _mapController;
    if (position == null || controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        ),
      ),
    );
  }

  /// Great-circle distance in metres from the device to an outlet (haversine).
  double? _distanceTo(Outlet outlet) {
    final me = _currentPosition;
    if (me == null || outlet.latitude == null || outlet.longitude == null) {
      return null;
    }
    const earthRadius = 6371000.0;
    final dLat = _rad(outlet.latitude! - me.latitude);
    final dLng = _rad(outlet.longitude! - me.longitude);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_rad(me.latitude)) *
            _cos(_rad(outlet.latitude!)) *
            _sin(dLng / 2) *
            _sin(dLng / 2);
    return earthRadius * 2 * _atan2(_sqrt(a), _sqrt(1 - a));
  }

  static double _rad(double deg) => deg * 3.141592653589793 / 180.0;
  static double _sin(double v) => math.sin(v);
  static double _cos(double v) => math.cos(v);
  static double _sqrt(double v) => math.sqrt(v);
  static double _atan2(double y, double x) => math.atan2(y, x);

  static String formatDistance(double metres) => _formatDistance(metres);

  static String _formatDistance(double metres) {
    if (metres < 1000) return '${metres.round()} m';
    return '${(metres / 1000).toStringAsFixed(1)} km';
  }

  /// Centres the map on one outlet and highlights it.
  Future<void> _focusOutlet(Outlet outlet) async {
    if (outlet.latitude == null || outlet.longitude == null) return;
    final controller = _mapController;
    if (controller != null) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(outlet.latitude!, outlet.longitude!),
            zoom: 16,
          ),
        ),
      );
    }
    setState(() => _selectedOutletId = outlet.id);
  }

  Future<void> _loadNearby() async {
    final position = _currentPosition;
    if (position == null) return;
    try {
      final response = await ref.read(businessApiProvider).nearby(
            latitude: position.latitude,
            longitude: position.longitude,
            radius: _nearbyRadius,
          );
      final payload = Map<String, dynamic>.from(response.data as Map);
      final raw = payload['data'];
      final list = raw is Map ? raw['data'] : raw;
      final outlets = (list as List<dynamic>? ?? const [])
          .map(
              (item) => Outlet.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      if (!mounted) return;
      setState(() {
        _markers.clear();
        for (final outlet in outlets) {
          if (outlet.latitude != null && outlet.longitude != null) {
            _markers.add(Marker(
                markerId: MarkerId('nearby_${outlet.id}'),
                position: LatLng(outlet.latitude!, outlet.longitude!),
                infoWindow: InfoWindow(title: outlet.name)));
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr(ref, 'nearbyLoaded')
              .replaceAll('{n}', '${outlets.length}'))));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild the pins whenever the outlet list finishes loading. The previous
    // one-shot read inside initState ran before any data had arrived, so the
    // map never showed a single pin.
    ref.listen(outletsProvider, (_, __) => _buildMarkers());

    final hasLocation = _currentPosition != null;
    final initialTarget = hasLocation
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _fallbackCenter;

    final all = ref.watch(outletsProvider).valueOrNull ?? const [];
    final located = all.where((o) => o.latitude != null && o.longitude != null);
    final query = _search.trim().toLowerCase();
    final matches = query.isEmpty
        ? located.toList()
        : located
            .where((o) =>
                o.name.toLowerCase().contains(query) ||
                (o.address ?? '').toLowerCase().contains(query))
            .toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF136B3E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr(ref, 'liveRoute'),
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            Text(
              tr(ref, 'locatedOfTotal')
                  .replaceAll('{located}', '${located.length}')
                  .replaceAll('{total}', '${all.length}'),
              style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          if (_apiKey == null)
            IconButton(
              tooltip: tr(ref, 'addMapApiKey'),
              icon: const Icon(Icons.key_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => const MapSettingsScreen()))
                  .then((_) => _loadApiKey()),
            ),
          IconButton(
            tooltip: tr(ref, 'refresh'),
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _buildMarkers,
          ),
        ],
      ),
      body: Stack(
        children: [
          // The credential decides how the map renders:
          //  - key saved -> WebView + Maps JS API, so a key typed into Map
          //    Settings applies immediately, with no rebuild
          //  - no key    -> native map, which still works when the key was
          //    baked into AndroidManifest.xml at build time
          _apiKey == null
              ? GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialTarget,
                    zoom: hasLocation ? 14 : 11,
                  ),
                  markers: _markers,
                  myLocationEnabled: hasLocation,
                  myLocationButtonEnabled: hasLocation,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _fitOutlets());
                  },
                )
              : RuntimeGoogleMap(
                  apiKey: _apiKey!,
                  pins: _pins,
                  centerLat: initialTarget.latitude,
                  centerLng: initialTarget.longitude,
                  zoom: hasLocation ? 14 : 11,
                ),

          // ── Search (top) ────────────────────────────────────────────────
          Positioned(top: 12, left: 14, right: 74, child: _searchBar(matches)),

          // ── Action rail (top-right) ─────────────────────────────────────
          Positioned(
            top: 12,
            right: 14,
            child: Column(
              children: [
                _MapAction(
                  icon: Icons.fit_screen_outlined,
                  tooltip: tr(ref, 'fitAllOutlets'),
                  onTap: _fitOutlets,
                ),
                const SizedBox(height: 8),
                _MapAction(
                  icon: Icons.my_location_rounded,
                  tooltip: tr(ref, 'recenterOnMe'),
                  onTap: hasLocation ? _recenter : null,
                ),
                const SizedBox(height: 8),
                _NearbyButton(
                  radius: _nearbyRadius,
                  enabled: hasLocation,
                  onChanged: (r) {
                    setState(() => _nearbyRadius = r);
                    _loadNearby();
                  },
                ),
              ],
            ),
          ),

          if (_locationProblem != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 150,
              child: _Notice(message: _locationProblem!),
            ),

          // ── Outlet list (bottom sheet) ──────────────────────────────────
          _OutletSheet(
            outlets: matches,
            selectedId: _selectedOutletId,
            collapsed: _sheetCollapsed,
            distanceOf: _distanceTo,
            onTap: (o) {
              _focusOutlet(o);
              _collapseSheet();
            },
          ),
        ],
      ),
    );
  }

  /// Drag the outlet sheet back down so it does not cover the map.
  void _collapseSheet() {
    // DraggableScrollableSheet owns its own controller; snapping back keeps the
    // map visible after the user picks an outlet.
    setState(() => _sheetCollapsed = true);
  }

  /// Compact floating search field. Filters the map pins and the outlet list.
  ///
  /// Kept deliberately slim (~44px tall): the earlier version was padded out to
  /// ~60px and, sitting above the outlet bottom sheet, the two boxes together
  /// read as one oversized double input.
  Widget _searchBar(List<Outlet> matches) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF136B3E)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 13.5),
              onChanged: (v) {
                setState(() => _search = v);
                // Keep the native map in sync with the filtered set.
                _buildMarkers();
              },
              decoration: InputDecoration(
                hintText: tr(ref, 'searchOutlet'),
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_search.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _search = ''),
              child: const Icon(Icons.close_rounded, size: 16),
            )
          else if (matches.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${matches.length}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF136B3E))),
            ),
        ],
      ),
    );
  }
}

/// Rounded square map control used in the top-right rail.
class _MapAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _MapAction({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        elevation: 6,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 21,
              color: onTap == null
                  ? Colors.grey.shade400
                  : const Color(0xFF136B3E),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nearby-radius picker shown as a third control in the rail.
class _NearbyButton extends StatelessWidget {
  final double radius;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _NearbyButton({
    required this.radius,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: trOf(context, 'outletsNearMe'),
      enabled: enabled,
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onChanged,
      itemBuilder: (_) => [
        PopupMenuItem(
            value: 1000, child: Text(trOf(context, 'within1km'))),
        PopupMenuItem(
            value: 3000, child: Text(trOf(context, 'within3km'))),
        PopupMenuItem(
            value: 5000, child: Text(trOf(context, 'within5km'))),
        PopupMenuItem(
            value: 10000, child: Text(trOf(context, 'within10km'))),
      ],
      child: Material(
        color: Colors.white,
        elevation: 6,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: 20,
                color: enabled ? const Color(0xFF136B3E) : Colors.grey.shade400,
              ),
              Text(
                '${(radius / 1000).round()}k',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color:
                      enabled ? const Color(0xFF136B3E) : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draggable bottom sheet listing every outlet the search matched.
class _OutletSheet extends StatelessWidget {
  final List<Outlet> outlets;
  final int? selectedId;
  final bool collapsed;
  final double? Function(Outlet) distanceOf;
  final void Function(Outlet) onTap;

  const _OutletSheet({
    required this.outlets,
    required this.selectedId,
    required this.collapsed,
    required this.distanceOf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: collapsed ? 0.11 : 0.18,
      // Must be <= the smallest snapSize below, otherwise Flutter asserts:
      // "snapSize >= widget.minChildSize && snapSize <= widget.maxChildSize".
      minChildSize: 0.11,
      maxChildSize: 0.75,
      snap: true,
      snapSizes: const [0.11, 0.18, 0.75],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.place_rounded,
                        size: 18, color: Color(0xFF136B3E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        outlets.isEmpty
                            ? trOf(context, 'noOutletsOnMap')
                            : (outlets.length == 1
                                ? trOf(context, 'outletOnMapOne')
                                    .replaceAll('{n}', '1')
                                : trOf(context, 'outletOnMapMany')
                                    .replaceAll(
                                        '{n}', '${outlets.length}')),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14.5),
                      ),
                    ),
                    Text(trOf(context, 'dragToExpand'),
                        style: const TextStyle(
                            fontSize: 10.5, color: Colors.grey)),
                  ],
                ),
              ),
              Expanded(
                child: outlets.isEmpty
                    ? const _EmptyOutlets()
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: outlets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final o = outlets[i];
                          return _OutletTile(
                            outlet: o,
                            distance: distanceOf(o),
                            selected: o.id == selectedId,
                            onTap: () => onTap(o),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One outlet row inside the bottom sheet.
class _OutletTile extends StatelessWidget {
  final Outlet outlet;
  final double? distance;
  final bool selected;
  final VoidCallback onTap;

  const _OutletTile({
    required this.outlet,
    required this.distance,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF136B3E);
    final coords = '${outlet.latitude!.toStringAsFixed(4)}, '
        '${outlet.longitude!.toStringAsFixed(4)}';

    return Material(
      color: selected ? green.withOpacity(0.08) : const Color(0xFFF7F9F8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected ? green : green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.storefront_rounded,
                    size: 18, color: selected ? Colors.white : green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      outlet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: selected ? green : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (outlet.address?.isNotEmpty ?? false)
                          ? outlet.address!
                          : coords,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                    // Administrative hierarchy, so the officer can recognise
                    // the area without relying on the map pin.
                    if (outlet.locationLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        outlet.locationLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected ? green : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (distance != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _MapScreenState.formatDistance(distance!),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when no outlet matches the search.
class _EmptyOutlets extends StatelessWidget {
  const _EmptyOutlets();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded,
                size: 34, color: Colors.grey),
            const SizedBox(height: 8),
            Text(trOf(context, 'noOutletMatches'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(height: 4),
            Text(trOf(context, 'tryDifferentName'),
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Small inline banner explaining a non-fatal location problem.
class _Notice extends StatelessWidget {
  final String message;
  const _Notice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.75),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
