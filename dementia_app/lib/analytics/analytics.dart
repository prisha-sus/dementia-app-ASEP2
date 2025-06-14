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
            _currentLocation =
                LatLng(locationData.latitude, locationData.longitude);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title:
              Text('Analytics', style: TextStyle(color: colorScheme.onPrimary)),
          backgroundColor: colorScheme.primary,
        ),
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (!_hasAccess) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Access Denied',
              style: TextStyle(color: colorScheme.onError)),
          backgroundColor: colorScheme.error,
        ),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, size: 80, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only caregivers can access this page',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Location Analytics',
            style: TextStyle(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLocation,
            tooltip: 'Refresh Location',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ValueListenableBuilder<LocationData?>(
              valueListenable: _mapService.locationNotifier,
              builder: (context, location, child) {
                return Center(
                  child: Text(
                    location != null
                        ? 'Updated: ${location.timestamp.hour.toString().padLeft(2, '0')}:${location.timestamp.minute.toString().padLeft(2, '0')}'
                        : 'No data',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _mapService.isActive
                  ? colorScheme.primaryContainer
                  : colorScheme.errorContainer,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  _mapService.isActive
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _mapService.isActive
                      ? colorScheme.primary
                      : colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _mapService.isActive
                        ? 'Live tracking active (updates every 5 minutes)'
                        : 'Location tracking inactive',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _mapService.isActive
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map Container
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _currentLocation ?? _defaultLocation,
                  zoom: 15.0,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.your_app',
                    maxZoom: 18,
                  ),
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: 60,
                          height: 60,
                          builder: (context) => Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: colorScheme.primary,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Location Info Panel
          Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<LocationData?>(
                valueListenable: _mapService.locationNotifier,
                builder: (context, location, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_searching,
                              color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Current Location',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      if (_currentLocation != null) ...[
                        const SizedBox(height: 12),
                        _buildLocationInfoRow(
                          icon: Icons.my_location,
                          label: 'Latitude',
                          value: _currentLocation!.latitude.toStringAsFixed(6),
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 8),
                        _buildLocationInfoRow(
                          icon: Icons.explore,
                          label: 'Longitude',
                          value: _currentLocation!.longitude.toStringAsFixed(6),
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'Location not available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
