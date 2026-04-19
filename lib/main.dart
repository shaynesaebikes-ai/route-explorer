import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Route Explorer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const RouteExplorerApp(),
    );
  }
}

class RouteExplorerApp extends StatefulWidget {
  const RouteExplorerApp({Key? key}) : super(key: key);

  @override
  State<RouteExplorerApp> createState() => _RouteExplorerAppState();
}

class _RouteExplorerAppState extends State<RouteExplorerApp> {
  late StreamSubscription<Position>? positionStream;
  
  double userLat = 40.7128;
  double userLon = -74.0060;
  
  final List<PointOfInterest> pointsOfInterest = [
    PointOfInterest(
      id: 1,
      name: 'Statue of Liberty',
      latitude: 40.6892,
      longitude: -74.0445,
      description: 'Iconic monument',
    ),
    PointOfInterest(
      id: 2,
      name: 'Times Square',
      latitude: 40.7580,
      longitude: -73.9855,
      description: 'Famous intersection',
    ),
    PointOfInterest(
      id: 3,
      name: 'Central Park',
      latitude: 40.7829,
      longitude: -73.9654,
      description: 'Large urban park',
    ),
    PointOfInterest(
      id: 4,
      name: 'Empire State Building',
      latitude: 40.7484,
      longitude: -73.9857,
      description: 'Historic skyscraper',
    ),
    PointOfInterest(
      id: 5,
      name: 'Brooklyn Bridge',
      latitude: 40.7061,
      longitude: -73.9969,
      description: 'Historic bridge',
    ),
  ];

  String selectedRoute = 'Route 1';
  List<String> availableRoutes = ['Route 1', 'Route 2', 'Route 3'];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestLocationPermission();
    _simulateLocationTracking();
  }

  Future<void> _requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permission denied');
      }
    } catch (e) {
      print('Permission error (normal in web): \$e');
    }
  }

  void _simulateLocationTracking() {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        userLat += (Random().nextDouble() - 0.5) * 0.001;
        userLon += (Random().nextDouble() - 0.5) * 0.001;
      });
      _checkNearbyPOIs(userLat, userLon);
    });
  }

  void _checkNearbyPOIs(double userLat, double userLon) {
    for (var poi in pointsOfInterest) {
      double distance = _calculateDistance(
        userLat,
        userLon,
        poi.latitude,
        poi.longitude,
      );

      if (distance < 0.1) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎯 Near: ${poi.name}\n\${(distance * 1000).toStringAsFixed(0)}m away',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Route Explorer'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Route',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selectedRoute,
                  isExpanded: true,
                  items: availableRoutes.map((String route) {
                    return DropdownMenuItem<String>(
                      value: route,
                      child: Text(route),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRoute = newValue ?? 'Route 1';
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pointsOfInterest.length,
              itemBuilder: (context, index) {
                final poi = pointsOfInterest[index];
                final distance = _calculateDistance(
                  userLat,
                  userLon,
                  poi.latitude,
                  poi.longitude,
                );
                final distanceText = distance < 0.001
                    ? 'You are here!'
                    : '\${(distance * 1000).toStringAsFixed(0)}m away';

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(poi.name),
                    subtitle: Text(distanceText),
                    trailing: distance < 0.1
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Location',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Lat: \${userLat.toStringAsFixed(6)}'),
                Text('Lon: \${userLon.toStringAsFixed(6)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }
}

class PointOfInterest {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String description;

  PointOfInterest({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
  });
}