import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_map/flutter_map.dart';

class MapPage extends StatefulWidget {
  final List<LatLng> routePoints;
  const MapPage({super.key, required this.routePoints});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    _prepareMapPath();
  }

  Future<void> _prepareMapPath() async {
    final directory = await getApplicationDocumentsDirectory();
    setState(() {
      // تأكد إن المسار بيوصل للي جواه مجلدات (12, 13..)
      localPath = '${directory.path}/offline_maps/Fayom';
    });
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialPos = widget.routePoints.isNotEmpty
        ? widget.routePoints.last
        : const LatLng(29.3197, 30.8357);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("OFFLINE MAP"),
        backgroundColor: Colors.black,
      ),
      body: localPath == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : FlutterMap(
              options: MapOptions(
                initialCenter: initialPos,
                initialZoom: 14,
                minZoom: 12,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  tileProvider: FileTileProvider(),
                  urlTemplate: '$localPath/{z}/{x}/{y}.png',
                
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
                if (widget.routePoints.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.routePoints.last,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
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
