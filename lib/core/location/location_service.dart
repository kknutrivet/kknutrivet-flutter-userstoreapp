import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationDetails {
  LocationDetails({
    this.buildingName,
    this.fullAddress,
    this.city,
    this.state,
    this.zipCode,
    this.latitude,
    this.longitude,
  });

  final String? buildingName;
  final String? fullAddress;
  final String? city;
  final String? state;
  final String? zipCode;
  final double? latitude;
  final double? longitude;
}

class LocationSearchResult {
  LocationSearchResult({
    required this.displayName,
    this.buildingName,
    this.title,
    this.subtitle,
    this.city,
    this.state,
    this.zipCode,
    this.latitude,
    this.longitude,
  });

  final String displayName;
  final String? buildingName;
  final String? title;
  final String? subtitle;
  final String? city;
  final String? state;
  final String? zipCode;
  final double? latitude;
  final double? longitude;
}

class LocationService {
  LocationService._internal();
  static final LocationService instance = LocationService._internal();

  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'User-Agent': 'KKNutrivet-Flutter/1.0 (support@kknutrivet.in)',
        'Accept': 'application/json',
      },
    ),
  );

  /// Requests permission and detects the current device GPS location,
  /// then reverse geocodes coordinates to street, city, state, and pincode.
  Future<LocationDetails> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled on your device. Please turn on GPS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied. Please allow location access.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in App Settings.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );

    return reverseGeocode(position.latitude, position.longitude);
  }

  /// Reverse geocodes latitude & longitude into Indian address details.
  Future<LocationDetails> reverseGeocode(double lat, double lon) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'addressdetails': '1',
          'lat': lat,
          'lon': lon,
          'zoom': '18',
        },
      );

      final data = response.data is Map ? response.data as Map : jsonDecode(response.data.toString()) as Map;
      final address = (data['address'] as Map?) ?? {};
      final displayName = data['display_name']?.toString() ?? '';

      final city = address['city'] ??
          address['town'] ??
          address['village'] ??
          address['county'] ??
          address['state_district'] ??
          '';

      final state = address['state']?.toString() ?? '';
      final rawPostcode = address['postcode']?.toString() ?? '';
      final pincode = RegExp(r'\d{6}').stringMatch(rawPostcode) ?? '';

      // Build clean street address
      final road = address['road']?.toString() ?? '';
      final suburb = address['suburb'] ?? address['neighbourhood'] ?? address['residential'] ?? '';
      final building = (address['building'] ?? address['house_name'] ?? address['house_number'] ?? address['flats'] ?? '')
          .toString()
          .trim();

      String cleanStreet = [road, suburb].where((s) => s.toString().trim().isNotEmpty).join(', ');
      if (cleanStreet.isEmpty && displayName.isNotEmpty) {
        cleanStreet = displayName.split(',').take(3).join(',').trim();
      }

      return LocationDetails(
        buildingName: building.isNotEmpty ? building : null,
        fullAddress: cleanStreet.isNotEmpty ? cleanStreet : displayName,
        city: city.toString().trim(),
        state: state.trim(),
        zipCode: pincode,
        latitude: lat,
        longitude: lon,
      );
    } catch (e) {
      debugPrint('[LocationService] reverseGeocode failed: $e');
      return LocationDetails(latitude: lat, longitude: lon);
    }
  }

  /// Searches locations, localities, cities, or pincodes across India.
  Future<List<LocationSearchResult>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'format': 'json',
          'addressdetails': '1',
          'q': trimmed,
          'countrycodes': 'in',
          'limit': '8',
        },
      );

      final list = response.data is List ? response.data as List : [];
      return list.whereType<Map>().map((item) {
        final address = (item['address'] as Map?) ?? {};
        final displayName = item['display_name']?.toString() ?? '';
        final name = item['name']?.toString() ?? '';

        final city = address['city'] ??
            address['town'] ??
            address['village'] ??
            address['county'] ??
            address['state_district'] ??
            '';

        final state = address['state']?.toString() ?? '';
        final rawPostcode = address['postcode']?.toString() ?? '';
        final pincode = RegExp(r'\d{6}').stringMatch(rawPostcode) ?? '';

        final lat = double.tryParse(item['lat']?.toString() ?? '');
        final lon = double.tryParse(item['lon']?.toString() ?? '');

        final parts = displayName.split(',').map((p) => p.trim()).toList();
        final title = name.isNotEmpty ? name : (parts.isNotEmpty ? parts.first : displayName);
        final subtitle = parts.length > 1 ? parts.skip(1).take(3).join(', ') : '';

        final building = (address['building'] ??
                address['house_name'] ??
                address['house_number'] ??
                address['flats'] ??
                '')
            .toString()
            .trim();

        return LocationSearchResult(
          displayName: displayName,
          buildingName: building.isNotEmpty ? building : null,
          title: title,
          subtitle: subtitle,
          city: city.toString().trim(),
          state: state.trim(),
          zipCode: pincode,
          latitude: lat,
          longitude: lon,
        );
      }).toList();
    } catch (e) {
      debugPrint('[LocationService] searchLocations error: $e');
      return [];
    }
  }
}
