import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LocationData {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, time: $timestamp)';
  }
}

class MapService {
  static const String _baseUrl = 'http://192.168.191.125:5001'; // Replace with your Flask server URL
  static const String _locationEndpoint = '/get_location';
  static const Duration _fetchInterval = Duration(minutes: 5);

  Timer? _timer;
  final StreamController<LocationData> _locationController = 
      StreamController<LocationData>.broadcast();
  final ValueNotifier<LocationData?> _locationNotifier = 
      ValueNotifier<LocationData?>(null);

  // Stream for reactive updates
  Stream<LocationData> get locationStream => _locationController.stream;
  
  // ValueNotifier for reactive updates (alternative approach)
  ValueNotifier<LocationData?> get locationNotifier => _locationNotifier;

  // Current location getter
  LocationData? get currentLocation => _locationNotifier.value;

  // Singleton pattern
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  /// Start periodic location fetching
  void startLocationUpdates() {
    // Fetch immediately on start
    _fetchLocation();
    
    // Then fetch every 5 minutes
    _timer = Timer.periodic(_fetchInterval, (_) {
      _fetchLocation();
    });
    
    if (kDebugMode) {
      print('MapService: Started location updates every ${_fetchInterval.inMinutes} minutes');
    }
  }

  /// Stop periodic location fetching
  void stopLocationUpdates() {
    _timer?.cancel();
    _timer = null;
    
    if (kDebugMode) {
      print('MapService: Stopped location updates');
    }
  }

  /// Fetch location from Flask backend
  Future<void> _fetchLocation() async {
    try {
      final url = Uri.parse('$_baseUrl$_locationEndpoint');
      
      if (kDebugMode) {
        print('MapService: Fetching location from $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final locationData = LocationData.fromJson(data);
        
        // Update both stream and notifier
        _locationController.add(locationData);
        _locationNotifier.value = locationData;
        
        if (kDebugMode) {
          print('MapService: Location updated - $locationData');
        }
      } else {
        throw Exception('Failed to fetch location: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('MapService: Request timeout - $e');
      }
      _handleError('Request timeout. Please check your internet connection.');
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        print('MapService: Network error - $e');
      }
      _handleError('Network error. Please check your connection.');
    } catch (e) {
      if (kDebugMode) {
        print('MapService: Error fetching location - $e');
      }
      _handleError('Failed to fetch location: $e');
    }
  }

  /// Handle errors by adding error state to stream
  void _handleError(String errorMessage) {
    // You can customize this to add error handling to your stream
    // For now, we'll just log the error
    if (kDebugMode) {
      print('MapService Error: $errorMessage');
    }
    
    // Optionally, you could add error states to your stream
    // _locationController.addError(errorMessage);
  }

  /// Manual location fetch (useful for pull-to-refresh)
  Future<LocationData?> fetchLocationOnce() async {
    try {
      await _fetchLocation();
      return currentLocation;
    } catch (e) {
      if (kDebugMode) {
        print('MapService: Manual fetch failed - $e');
      }
      return null;
    }
  }

  /// Check if service is actively fetching
  bool get isActive => _timer != null && _timer!.isActive;

  /// Dispose resources
  void dispose() {
    stopLocationUpdates();
    _locationController.close();
    _locationNotifier.dispose();
  }
}