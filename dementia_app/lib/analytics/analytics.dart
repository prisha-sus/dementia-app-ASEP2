import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytestapp/services/mapService.dart';

// Role checking function (provided)
Future<String?> getUserRole(String uid) async {
  try {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      return userDoc.data()!['role'] ?? 'No Role';
    } else {
      return 'No Role';
    }
  } catch (e) {
    print('Error fetching user role: $e');
    return 'No Role';
  }
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final MapService _mapService = MapService();
  final MapController _mapController = MapController();
  
  bool _isLoading = true;
  bool _hasAccess = false;
  String _errorMessage = '';
  LatLng? _currentLocation;
  
  // Default location (you can change this to your preferred default)
  static const LatLng _defaultLocation = LatLng(18.5204, 73.8567);

  @override
  void initState() {
    super.initState();
    _checkAccessAndInitialize();
  }

  @override
  void dispose() {
    _mapService.stopLocationUpdates();
    super.dispose();
  }

  Future<void> _checkAccessAndInitialize() async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Please log in to access this page';
          _isLoading = false;
        });
        return;
      }

      // Check user role
      final role = await getUserRole(user.uid);
      if (role?.toLowerCase() != 'caregiver') {
        setState(() {
          _hasAccess = false;
          _isLoading = false;
        });
        return;
      }

      // User has access, initialize map service
      setState(() {
        _hasAccess = true;
        _isLoading = false;
      });

      _initializeLocationService();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking access: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeLocationService() {
    // Set initial location
    _currentLocation = _defaultLocation;
    
    // Listen to location updates
    _mapService.locationStream.listen(
      (locationData) {
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(locationData.latitude, locationData.longitude);
          });
          
          // Animate map to new location
          _mapController.move(_currentLocation!, 15.0);
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location update failed: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    // Start periodic location updates
    _mapService.startLocationUpdates();
  }

  Future<void> _refreshLocation() async {
    final location = await _mapService.fetchLocationOnce();
    if (location != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location refreshed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasAccess) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 80,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Only caregivers can access this page',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = '';
                    _isLoading = true;
                  });
                  _checkAccessAndInitialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location Analytics'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLocation,
            tooltip: 'Refresh Location',
          ),
          ValueListenableBuilder<LocationData?>(
            valueListenable: _mapService.locationNotifier,
            builder: (context, location, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    location != null 
                        ? 'Updated: ${location.timestamp.hour.toString().padLeft(2, '0')}:${location.timestamp.minute.toString().padLeft(2, '0')}'
                        : 'No data',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: _mapService.isActive ? Colors.green.shade100 : Colors.orange.shade100,
            child: Row(
              children: [
                Icon(
                  _mapService.isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: _mapService.isActive ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _mapService.isActive 
                      ? 'Live tracking active (updates every 5 minutes)'
                      : 'Location tracking inactive',
                  style: TextStyle(
                    color: _mapService.isActive ? Colors.green.shade800 : Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentLocation ?? _defaultLocation,
                zoom: 15.0,
                minZoom: 3.0,
                maxZoom: 18.0,
              ),
              children: [
                // OpenStreetMap tile layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.your_app', // Replace with your package name
                  maxZoom: 18,
                ),
                
                // Marker layer
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 60,
                        height: 60,
                        builder: (context) => const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Location info panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: ValueListenableBuilder<LocationData?>(
              valueListenable: _mapService.locationNotifier,
              builder: (context, location, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Current Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_currentLocation != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.my_location, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.my_location, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Lng: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      if (location != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Last updated: ${location.timestamp.toString().substring(0, 19)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'Location not available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}