import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tuko_kadi_iebc_locator/features/nearby_spots/domain/entities/nearby_spot.dart';

class GooglePlacesService {
  GooglePlacesService({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? const String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  static const String _endpoint = 'https://places.googleapis.com/v1/places:searchNearby';

  final http.Client _client;
  final String _apiKey;

  String? buildPhotoUrl(String? photoReference) {
    if (_apiKey.isEmpty || photoReference == null || photoReference.trim().isEmpty) {
      return null;
    }

    return 'https://places.googleapis.com/v1/$photoReference/media?maxHeightPx=420&maxWidthPx=420&key=$_apiKey';
  }

  Future<List<NearbySpot>> fetchNearbySpots({
    required double latitude,
    required double longitude,
    required NearbySpotCategory category,
  }) async {
    if (_apiKey.isEmpty) {
      throw const PlacesApiException(
        'Google Places API key is missing. Pass --dart-define=GOOGLE_PLACES_API_KEY=your_key.',
      );
    }
    if (!_isValidLatitude(latitude) || !_isValidLongitude(longitude)) {
      throw PlacesApiException(
        'Invalid office coordinates provided (latitude: $latitude, longitude: $longitude).',
      );
    }

    final Uri uri = Uri.parse(_endpoint);
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'includedTypes': category.includedTypes,
      'maxResultCount': 20,
      'rankPreference': 'DISTANCE',
      'locationRestriction': <String, dynamic>{
        'circle': <String, dynamic>{
          'center': <String, double>{
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': 5000.0,
        },
      },
    };
    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'places.id,places.displayName,places.primaryType,places.types,places.rating,places.formattedAddress,places.location',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (kDebugMode) {
        debugPrint('Google Places nearby search failed.');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Endpoint: $uri');
        debugPrint('Request body: ${jsonEncode(requestBody)}');
        debugPrint('Response body: ${response.body}');
      }
      throw PlacesApiException(
        'Failed to load nearby ${category.label.toLowerCase()} (${response.statusCode}).',
      );
    }

    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const PlacesApiException('Unexpected response from Places API.');
    }

    final Object? places = decoded['places'];
    if (places is! List<Object?>) {
      return <NearbySpot>[];
    }

    return places
        .whereType<Map<String, dynamic>>()
        .map(NearbySpot.fromPlacesJson)
        .where((NearbySpot spot) => spot.name.trim().isNotEmpty)
        .toList(growable: false);
  }

  static bool _isValidLatitude(double value) =>
      value.isFinite && value >= -90 && value <= 90;

  static bool _isValidLongitude(double value) =>
      value.isFinite && value >= -180 && value <= 180;
}

class PlacesApiException implements Exception {
  const PlacesApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
