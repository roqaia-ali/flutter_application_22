
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_22/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'map_page.dart';


class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  final LocationService _locationService = LocationService();
  List<LatLng> routePoints = [];
  StreamSubscription<Position>? _positionStream;
  double _totalDistance = 0.0;
  bool _isTracking = false;

  void _toggleTracking() async {
    if (_isTracking) {
      _positionStream?.cancel();
      setState(() => _isTracking = false);
    } else {
      bool hasPermission = await _locationService.requestPermission();
      if (hasPermission) {
        setState(() {
          _isTracking = true;
          routePoints.clear();
          _totalDistance = 0.0;
        });
        _startStreaming();
      }
    }
  }

  void _startStreaming() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((pos) {
      final newPoint = LatLng(pos.latitude, pos.longitude);
      setState(() {
        if (routePoints.isNotEmpty) {
          _totalDistance += Geolocator.distanceBetween(
            routePoints.last.latitude, routePoints.last.longitude,
            newPoint.latitude, newPoint.longitude,
          );
        }
        routePoints.add(newPoint);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // أسود سينمائي
      appBar: AppBar(title: const Text("FAYOUM TRACKER"), centerTitle: true, backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatCard(),
            const SizedBox(height: 50),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_run, color: Colors.cyanAccent, size: 40),
          Text(
            "${(_totalDistance / 1000).toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Text("KILOMETERS", style: TextStyle(color: Colors.grey, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _circleBtn(
          icon: _isTracking ? Icons.stop : Icons.play_arrow,
          color: _isTracking ? Colors.redAccent : Colors.greenAccent,
          onTap: _toggleTracking,
        ),
        _circleBtn(
          icon: Icons.map_outlined,
          color: Colors.blueAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MapPage(routePoints: routePoints))),
        ),
      ],
    );
  }

  Widget _circleBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color)),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}