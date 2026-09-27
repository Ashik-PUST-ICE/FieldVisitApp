import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/data/models/outlet.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _requestPermissions();
    await _getCurrentLocation();
    await _loadOutlets();
  }

  Future<void> _requestPermissions() async {
    final locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOutlets() async {
    final outletsAsync = ref.read(outletsProvider);
    outletsAsync.whenOrNull(
      data: (outlets) {
        setState(() {
          _markers.clear();
          for (final outlet in outlets) {
            if (outlet.latitude != null && outlet.longitude != null) {
              _markers.add(
                Marker(
                  markerId: MarkerId('outlet_${outlet.id}'),
                  position: LatLng(outlet.latitude!, outlet.longitude!),
                  infoWindow: InfoWindow(title: outlet.name),
                ),
              );
            }
          }
        });
      },
    );
  }

  Future<void> _loadNearby() async {
    final position = _currentPosition;
    if (position == null) return;
    try {
      final response = await ref.read(businessApiProvider).nearby(latitude: position.latitude, longitude: position.longitude, radius: 5000);
      final payload = Map<String, dynamic>.from(response.data as Map);
      final raw = payload['data'];
      final list = raw is Map ? raw['data'] : raw;
      final outlets = (list as List<dynamic>? ?? const []).map((item) => Outlet.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      if (!mounted) return;
      setState(() {
        _markers.clear();
        for (final outlet in outlets) {
          if (outlet.latitude != null && outlet.longitude != null) {
            _markers.add(Marker(markerId: MarkerId('nearby_${outlet.id}'), position: LatLng(outlet.latitude!, outlet.longitude!), infoWindow: InfoWindow(title: outlet.name)));
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${outlets.length} nearby outlets loaded')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map'), actions: [IconButton(onPressed: _loadNearby, icon: const Icon(Icons.radar))]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPosition == null
              ? const Center(child: Text('Unable to get location'))
              : GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    zoom: 14,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadOutlets,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
