import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_22/services/location_service.dart';
import 'package:flutter_application_22/services/tile_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'tracker.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _controller = MapController();
  final LocationService _locationService =
      LocationService(); // 🔥 IMPORT SERVICE

  StreamSubscription<Position>? _sub;

  String? _mapPath;
  LatLng? _current;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ================= INIT =================
  Future<void> _init() async {
    await _checkGPS();
    await _loadMapPath();
    _startGPS();
  }

  // ================= PERMISSION (via service) =================
  Future<void> _checkGPS() async {
    await _locationService.requestPermission(); // 🔥 using service
  }

  Future<void> _loadMapPath() async {
    _mapPath = await MapLoader.getLocalPath();
    if (mounted) setState(() {});
  }

  // ================= GPS STREAM =================
  void _startGPS() {
    _sub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen((pos) {
          final newPos = LatLng(pos.latitude, pos.longitude);

          _current = newPos;

          _controller.move(newPos, 16);

          if (mounted) setState(() {});
        });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final center = TrackingData.routePoints.isNotEmpty
        ? TrackingData.routePoints.last
        : const LatLng(29.3, 30.8);

    if (_mapPath == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("OFFLINE MAP")),

      body: FlutterMap(
        mapController: _controller,

        options: MapOptions(
          initialCenter: center,
          initialZoom: 16,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),

        children: [
          TileLayer(
            tileProvider: FileTileProvider(),
            urlTemplate: "$_mapPath/Fayom/{z}/{x}/{y}.png",
            errorTileCallback: (tile, error, stackTrace) {
              // ignore missing tiles
            },
            maxZoom: 18,
            minZoom: 12,
          ),

          PolylineLayer(
            polylines: [
              Polyline(
                points: List<LatLng>.from(TrackingData.routePoints),
                strokeWidth: 5,
                color: Colors.red,
              ),
            ],
          ),

          if (_current != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _current!,
                  width: 45,
                  height: 45,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
