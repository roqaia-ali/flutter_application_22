import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required List<LatLng> routePoints});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  List<LatLng> routePoints = [];

  StreamSubscription<Position>? _positionStream;

  String? localPath;

  @override
  void initState() {
    super.initState();
    _prepareMapPath();
    _startTracking();
  }

  Future<void> _prepareMapPath() async {
    final directory = await getApplicationDocumentsDirectory();

    setState(() {
      localPath = '${directory.path}/offline_maps/Fayom';
    });
  }

  void _startTracking() {
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          ),
        ).listen((pos) {
          final newPoint = LatLng(pos.latitude, pos.longitude);

          setState(() {
            routePoints.add(newPoint);
          });

          // تحريك الخريطة للموقع الحالي
          _mapController.move(newPoint, 17);
        });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialPos = routePoints.isNotEmpty
        ? routePoints.last
        : const LatLng(29.3197, 30.8357);

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("LIVE GPS TRACKING"),
        backgroundColor: Colors.black,
      ),

      body: localPath == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,

              options: MapOptions(
                initialCenter: initialPos,
                initialZoom: 16,
                minZoom: 12,
                maxZoom: 18,
              ),

              children: [
                TileLayer(
                  tileProvider: FileTileProvider(),
                  urlTemplate: '$localPath/{z}/{x}/{y}.png',
                ),

                // رسم المسار
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5,
                      color: Colors.cyanAccent,
                    ),
                  ],
                ),

                // الماركر الحالي
                if (routePoints.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: routePoints.last,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.red,
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
