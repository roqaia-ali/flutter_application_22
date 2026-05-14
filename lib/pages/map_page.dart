import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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
  Timer? _uiTimer;

  String? _path;
  LatLng? _currentPos;
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    initMap();
    startGPS();
    startUITimer();
  }

  Future<void> initMap() async {
    final dir = await getApplicationDocumentsDirectory();
    _path = "${dir.path}/offline_maps";
    setState(() {});
  }

  /// 🔥 UI refresh slow (NOT GPS rebuild)
  void startUITimer() {
    _uiTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) setState(() {});
    });
  }

  /// 🔥 GPS ONLY updates variables (NO setState here)
  void startGPS() {
    _sub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen((pos) {
          _currentPos = LatLng(pos.latitude, pos.longitude);

          if (_follow && _currentPos != null) {
            _controller.move(_currentPos!, _controller.camera.zoom);
          }
        });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = TrackingData.routePoints.isNotEmpty
        ? TrackingData.routePoints.last
        : const LatLng(29.3, 30.8);

    return Scaffold(
      appBar: AppBar(
        title: const Text("LIVE MAP"),
        actions: [
          IconButton(
            icon: Icon(_follow ? Icons.gps_fixed : Icons.gps_not_fixed),
            onPressed: () => setState(() => _follow = !_follow),
          ),
        ],
      ),

      body: _path == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _controller,
              options: MapOptions(initialCenter: center, initialZoom: 16),
              children: [
                /// 🗺 TILE LAYER (FIXED STABILITY)
                TileLayer(
                  tileProvider: FileTileProvider(),
                  urlTemplate: "$_path/Fayom/{z}/{x}/{y}.png",
                  keepBuffer: 3, // 🔥 important fix
                ),

                /// 📍 POLYLINE (FAST COPY ONLY)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: List<LatLng>.of(TrackingData.routePoints),
                      strokeWidth: 5,
                      color: Colors.red,
                    ),
                  ],
                ),

                /// 📍 MARKER
                if (_currentPos != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPos!,
                        width: 50,
                        height: 50,
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
