import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_22/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'map_page.dart';

class TrackingData {
  static List<LatLng> routePoints = [];
}

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;

  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;
  Duration _duration = Duration.zero;
  bool _isTracking = false;

  
  LatLng? _lastSpeedPoint;
  DateTime? _lastSpeedTime;

  
  LatLng? _lastDistancePoint;

  double _speedSmooth = 0.0;

  final LocationService _locationService = LocationService();

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  
  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _duration += const Duration(seconds: 1);
      });
    });
  }

  
  void _toggleTracking() async {
    if (_isTracking) {
      await _positionStream?.cancel();
      _timer?.cancel();

      setState(() {
        _isTracking = false;
      });
    } else {
      final ok = await _locationService.requestPermission();
      if (!ok) return;

      setState(() {
        _isTracking = true;

        _totalDistance = 0.0;
        _currentSpeed = 0.0;
        _duration = Duration.zero;

        _lastSpeedPoint = null;
        _lastSpeedTime = null;
        _lastDistancePoint = null;

        _speedSmooth = 0.0;

        TrackingData.routePoints.clear();
      });

      _startTimer();
      _startStreaming();
    }
  }

  
  void _startStreaming() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((pos) {
          if (!_isTracking) return;

          
          if (pos.accuracy > 30) return;

          final newPoint = LatLng(pos.latitude, pos.longitude);

          final now = DateTime.now();

          
          if (_lastSpeedPoint == null) {
            _lastSpeedPoint = newPoint;
            _lastSpeedTime = now;
            _lastDistancePoint = newPoint;

            TrackingData.routePoints.add(newPoint);

            if (mounted) setState(() {});
            return;
          }

          

          final speedGap = Geolocator.distanceBetween(
            _lastSpeedPoint!.latitude,
            _lastSpeedPoint!.longitude,
            newPoint.latitude,
            newPoint.longitude,
          );

          
          if (speedGap > 100) {
            _lastSpeedPoint = newPoint;
            _lastSpeedTime = now;
            return;
          }

          final timeSec = now.difference(_lastSpeedTime!).inMilliseconds / 1000;

          
          _lastSpeedPoint = newPoint;
          _lastSpeedTime = now;

          if (timeSec > 0 && speedGap > 0) {
            final instantSpeed = (speedGap / timeSec) * 3.6;

            
            if (instantSpeed < 40) {
              _speedSmooth = (_speedSmooth * 0.8) + (instantSpeed * 0.2);

              _currentSpeed = _speedSmooth;
              
            }
          }

          if (_currentSpeed < 0.5) {
            _currentSpeed = 0;
          }

        

          final distGap = Geolocator.distanceBetween(
            _lastDistancePoint!.latitude,
            _lastDistancePoint!.longitude,
            newPoint.latitude,
            newPoint.longitude,
          );

          
          if (distGap >= 3) {
            _totalDistance += distGap;

            TrackingData.routePoints.add(newPoint);

            _lastDistancePoint = newPoint;

            print("Distance = $_totalDistance");
            print("Points = ${TrackingData.routePoints.length}");
          }

          if (mounted) {
            setState(() {});
          }
        });
  }

  
  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');

    return "${two(d.inHours)}:"
        "${two(d.inMinutes.remainder(60))}:"
        "${two(d.inSeconds.remainder(60))}";
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Text(
              "LIVE TRACKING",
              style: TextStyle(color: Colors.cyanAccent, letterSpacing: 3),
            ),

            const SizedBox(height: 20),

            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                  width: 8,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentSpeed.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text("KM/H", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _box("TIME", _formatDuration(_duration)),
                _box(
                  "DISTANCE",
                  "${(_totalDistance / 1000).toStringAsFixed(2)} KM",
                ),
              ],
            ),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _toggleTracking,
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: _isTracking
                        ? Colors.red
                        : Colors.greenAccent,
                    child: Icon(
                      _isTracking ? Icons.stop : Icons.play_arrow,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(width: 30),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapPage()),
                    );
                  },
                  child: const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.map, color: Colors.white, size: 35),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _box(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
