import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_theme.dart';
import 'package:field_visit_app/data/models/outlet.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
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
