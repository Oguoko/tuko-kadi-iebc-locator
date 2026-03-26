import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tuko_kadi_iebc_locator/features/nearby_spots/domain/entities/nearby_spot.dart';

class GooglePlacesService {
  GooglePlacesService({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? const String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  static const String _endpoint = 'https://places.googleapis.com/v1/places:searchNearby';
  static const List<String> _includedTypes = <String>[
    'restaurant',
    'cafe',
    'bar',
    'tourist_attraction',
    'park',
  ];

  final http.Client _client;
  final String _apiKey;

  Future<List<NearbySpot>> fetchNearbyLifestyleSpots({
    required double latitude,
    required double longitude,
  }) async {
    if (_apiKey.isEmpty) {
      throw const PlacesApiException(
        'Google Places API key is missing. Pass --dart-define=GOOGLE_PLACES_API_KEY=your_key.',
      );
    }

    final Uri uri = Uri.parse(_endpoint);
    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'places.id,places.displayName,places.primaryTypeDisplayName,places.types,places.rating,places.distanceMeters',
      },
      body: jsonEncode(<String, dynamic>{
        'includedTypes': _includedTypes,
        'maxResultCount': 20,
        'rankPreference': 'DISTANCE',
        'locationRestriction': <String, dynamic>{
          'circle': <String, dynamic>{
            'center': <String, double>{
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': 5000,
          },
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlacesApiException(
        'Failed to load nearby spots (${response.statusCode}).',
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
}

class PlacesApiException implements Exception {
  const PlacesApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
