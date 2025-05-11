import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';

class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  gmaps.LatLng? _currentLatLng;
  bool _loading = true;
  String? _error;
  final Set<gmaps.Marker> _markers = {};
  int _markerIdCounter = 0;
// _mapController is only used in onMapCreated, so suppress the warning for now.
// ignore: unused_field
  gmaps.GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _addDefaultAstanaMarkers();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permission denied.';
            _loading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permissions are permanently denied.';
          _loading = false;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLatLng = gmaps.LatLng(position.latitude, position.longitude);
        _loading = false;
        _markers.add(
          gmaps.Marker(
            markerId: const gmaps.MarkerId('me'),
            position: _currentLatLng!,
            infoWindow: const gmaps.InfoWindow(title: 'You are here'),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to get location: $e';
        _loading = false;
      });
    }
  }

  void _addDefaultAstanaMarkers() {
    // Astana coordinates for 3 locations
    final List<gmaps.LatLng> astanaLocations = [
      gmaps.LatLng(51.1694, 71.4491), // Baiterek Tower
      gmaps.LatLng(51.1280, 71.4304), // Khan Shatyr
      gmaps.LatLng(51.0907, 71.4187), // Expo 2017
    ];
    final List<String> titles = [
      'Baiterek Tower',
      'Khan Shatyr',
      'Expo 2017',
    ];
    for (int i = 0; i < astanaLocations.length; i++) {
      _markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('astana_$i'),
          position: astanaLocations[i],
          infoWindow: gmaps.InfoWindow(title: titles[i]),
        ),
      );
    }
  }

  void _addMarker(gmaps.LatLng position) {
    setState(() {
      _markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('custom_${_markerIdCounter++}'),
          position: position,
          infoWindow: const gmaps.InfoWindow(title: 'Custom Marker'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        title: Text(
          'Map',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 26),
        ),
      ),
      body: _loading
          ? Center(
              child: Lottie.asset(
                'assets/lottie/loading_music.json',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                repeat: true,
              ),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : _currentLatLng == null
                  ? const Center(child: Text('Location not available'))
                  : gmaps.GoogleMap(
                      initialCameraPosition: gmaps.CameraPosition(
                        target: _currentLatLng!,
                        zoom: 13,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      markers: _markers,
                      onMapCreated: (controller) => _mapController = controller,
                      onLongPress: _addMarker,
                    ),
    );
  }
}
