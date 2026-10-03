import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  String _search = '';
  double _nearbyRadius = 5000;

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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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
      final response = await ref.read(businessApiProvider).nearby(
            latitude: position.latitude,
            longitude: position.longitude,
            radius: _nearbyRadius,
          );
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPosition == null
              ? const Center(child: Text('Unable to get location'))
              : kIsWeb
                  ? _buildWebMapFallback(context)
                  : GoogleMap(
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

  Widget _buildWebMapFallback(BuildContext context) {
    final allOutlets = ref.watch(outletsProvider).valueOrNull ?? const [];
    final outlets = _search.isEmpty
        ? allOutlets
        : allOutlets.where((o) => o.name.toLowerCase().contains(_search.toLowerCase())).toList();
    final position = _currentPosition!;
    return Column(
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3)),
            ],
          ),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search outlets by name…',
              prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF136B3E)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        // My location card
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.my_location, color: Color(0xFF136B3E)),
              ),
              title: const Text('Your current location', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}'),
              trailing: PopupMenuButton<double>(
                tooltip: 'Nearby radius',
                icon: const Icon(Icons.radar, color: Color(0xFF136B3E)),
                initialValue: _nearbyRadius,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 1000, child: Text('1 km radius')),
                  const PopupMenuItem(value: 3000, child: Text('3 km radius')),
                  const PopupMenuItem(value: 5000, child: Text('5 km radius')),
                  const PopupMenuItem(value: 10000, child: Text('10 km radius')),
                ],
                onSelected: (r) {
                  setState(() => _nearbyRadius = r);
                  _loadNearby();
                },
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Outlet locations', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            children: [
              if (outlets.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: const ListTile(
                    leading: Icon(Icons.location_off, color: Colors.grey),
                    title: Text('No outlets found'),
                    subtitle: Text('Try adjusting your search or add outlets with coordinates.'),
                  ),
                )
              else
                ...outlets.map(
                  (outlet) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.place_rounded, color: Color(0xFF136B3E), size: 20),
                      ),
                      title: Text(outlet.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        outlet.latitude != null && outlet.longitude != null
                            ? '${outlet.latitude!.toStringAsFixed(5)}, ${outlet.longitude!.toStringAsFixed(5)}'
                            : 'Coordinates not set',
                        style: TextStyle(
                          color: outlet.latitude != null ? Colors.grey[600] : Colors.red[300],
                          fontSize: 12,
                        ),
                      ),
                      trailing: outlet.latitude != null
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF136B3E), size: 18)
                          : const Icon(Icons.cancel_rounded, color: Colors.grey, size: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
