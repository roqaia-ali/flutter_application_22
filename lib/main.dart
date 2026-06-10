import 'package:flutter/material.dart';
import 'package:flutter_application_22/pages/tracker.dart';
import 'package:flutter_application_22/services/tile_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MapLoader.extractMapZip(); //  extract map
  
  runApp(const FayoumTrackerApp());
}

class FayoumTrackerApp extends StatelessWidget {
  const FayoumTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fayoum University Tracker',

      theme: ThemeData(
        //useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A), 

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
          primary: Colors.cyanAccent,
          surface: const Color(0xFF121212),
        ),
  
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),

      home: const TrackerPage(),
    );
  }
}
