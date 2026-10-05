import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _isLoading = true;
  String _search = '';
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
      _isLoading = false;
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
        _isLoading = false;
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${outlets.length} nearby outlets loaded')));
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

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Live Route',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (_apiKey == null)
            IconButton(
              tooltip: 'Add map API key',
              icon: const Icon(Icons.key_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => const MapSettingsScreen()))
                  .then((_) => _loadApiKey()),
            ),
          IconButton(
            tooltip: 'Fit all outlets',
            icon: const Icon(Icons.zoom_out_map_rounded),
            onPressed: _fitOutlets,
          ),
          IconButton(
            tooltip: 'Recenter on me',
            icon: const Icon(Icons.my_location_rounded),
            onPressed: hasLocation ? _recenter : null,
          ),
          PopupMenuButton<double>(
            tooltip: 'Outlets near me',
            icon: const Icon(Icons.travel_explore_rounded),
            onSelected: (r) {
              setState(() => _nearbyRadius = r);
              _loadNearby();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 1000, child: Text('Within 1 km')),
              PopupMenuItem(value: 3000, child: Text('Within 3 km')),
              PopupMenuItem(value: 5000, child: Text('Within 5 km')),
              PopupMenuItem(value: 10000, child: Text('Within 10 km')),
            ],
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
          if (_isLoading) const LinearProgressIndicator(minHeight: 3),
          if (_locationProblem != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _Notice(message: _locationProblem!),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'map_refresh',
        onPressed: _buildMarkers,
        child: const Icon(Icons.refresh),
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
