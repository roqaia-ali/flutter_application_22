import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'tracker.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _controller = MapController();

  StreamSubscription<Position>? _sub;

  String? _mapPath;
  LatLng? _current;

  @override
  void initState() {
    super.initState();
    _checkGPS();
    _initOfflineMap();
    _startGPS();
  }

  Future<void> _checkGPS() async {
    await Geolocator.requestPermission();
  }

  Future<void> _initOfflineMap() async {
    final dir = await getApplicationDocumentsDirectory();
    _mapPath = "${dir.path}/offline_maps";
    if (mounted) setState(() {});
  }

  /// 🔥 GPS STREAM
  void _startGPS() {
    _sub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 2,
          ),
        ).listen((pos) {
          final newPos = LatLng(pos.latitude, pos.longitude);

          setState(() {
            _current = newPos;
          });

          /// ✅ CAMERA MOVE (CORRECT)
          _controller.move(newPos, _controller.camera.zoom);
        });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

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
        mapController: _controller, // 🔥 IMPORTANT FIX

        options: MapOptions(
          initialCenter: center,
          initialZoom: 16,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),

        children: [
          /// 🗺️ OFFLINE TILES
          TileLayer(
            tileProvider: FileTileProvider(),
            urlTemplate: "$_mapPath/Fayom/{z}/{x}/{y}.png",
            keepBuffer: 6,
            maxZoom: 18,
            minZoom: 12,
          ),

          /// 📍 ROUTE LINE
          PolylineLayer(
            polylines: [
              Polyline(
                points: List<LatLng>.from(TrackingData.routePoints),
                strokeWidth: 5,
                color: Colors.red,
              ),
            ],
          ),

          /// 📍 CURRENT LOCATION
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
