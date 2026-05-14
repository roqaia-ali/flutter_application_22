import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

class MapPage extends StatefulWidget {
  final List<LatLng> routePoints;

  const MapPage({super.key, required this.routePoints});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String? _localPath;
  final MapController _mapController = MapController();

  bool _follow = true; // 🔥 جديد فقط

  @override
  void initState() {
    super.initState();
    _initPath();
  }

  Future<void> _initPath() async {
    final directory = await getApplicationDocumentsDirectory();
    setState(() {
      _localPath = '${directory.path}/offline_maps/Fayom';
    });
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔥 LIVE TRACKING (الجزء المهم)
    if (_follow && widget.routePoints.isNotEmpty) {
      _mapController.move(widget.routePoints.last, _mapController.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    const LatLng fayoumCenter = LatLng(29.3084, 30.8428);

    final LatLng currentMarkerPoint = widget.routePoints.isNotEmpty
        ? widget.routePoints.last
        : fayoumCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text("OFFLINE MAP"),
        backgroundColor: Colors.black,
        actions: [
          // 🔥 زر تشغيل/إيقاف الـ follow
         

          // زر الرجوع للمكان
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(currentMarkerPoint, 15);
            },
          ),
        ],
      ),

      body: _localPath == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: fayoumCenter,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  tileProvider: FileTileProvider(),
                  urlTemplate: '$_localPath/{z}/{x}/{y}.png',
                ),

                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routePoints,
                      strokeWidth: 5,
                      color: Colors.cyanAccent,
                    ),
                  ],
                ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentMarkerPoint,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
