import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RoutePreviewData {
  const RoutePreviewData({
    required this.points,
    required this.distanceMeters,
    required this.duration,
  });

  final List<LatLng> points;
  final int? distanceMeters;
  final Duration? duration;
}

class GoogleRoutesService {
  GoogleRoutesService({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey =
            apiKey ??
            const String.fromEnvironment(
              'GOOGLE_ROUTES_API_KEY',
              defaultValue: String.fromEnvironment('GOOGLE_PLACES_API_KEY'),
            );

  static const String _endpoint =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  final http.Client _client;
  final String _apiKey;

  Future<RoutePreviewData?> computeRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    if (_apiKey.isEmpty) {
      throw const RoutesApiException(
        'Google Routes API key is missing. Pass --dart-define=GOOGLE_ROUTES_API_KEY=your_key.',
      );
    }

    final Uri uri = Uri.parse(_endpoint);
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'origin': <String, dynamic>{
        'location': <String, dynamic>{
          'latLng': <String, double>{
            'latitude': originLat,
            'longitude': originLng,
          },
        },
      },
      'destination': <String, dynamic>{
        'location': <String, dynamic>{
          'latLng': <String, double>{
            'latitude': destinationLat,
            'longitude': destinationLng,
          },
        },
      },
      'travelMode': 'DRIVE',
      'routingPreference': 'TRAFFIC_UNAWARE',
      'computeAlternativeRoutes': false,
      'languageCode': 'en-US',
      'units': 'METRIC',
    };

    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (kDebugMode) {
        debugPrint('Google Routes computeRoutes failed.');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Endpoint: $uri');
        debugPrint('Request body: ${jsonEncode(requestBody)}');
        debugPrint('Response body: ${response.body}');
      }
      throw RoutesApiException(
        'Failed to compute route preview (${response.statusCode}).',
      );
    }

    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const RoutesApiException('Unexpected response from Routes API.');
    }

    final Object? routes = decoded['routes'];
    if (routes is! List<Object?> || routes.isEmpty) {
      return null;
    }

    final Map<String, dynamic> firstRoute =
        (routes.first as Map<String, dynamic>?) ?? <String, dynamic>{};
    final String? encodedPolyline =
        (firstRoute['polyline'] as Map<String, dynamic>?)?['encodedPolyline']
            as String?;
    if (encodedPolyline == null || encodedPolyline.isEmpty) {
      return null;
    }

    return RoutePreviewData(
      points: _decodePolyline(encodedPolyline),
      distanceMeters: _asInt(firstRoute['distanceMeters']),
      duration: _parseDuration(firstRoute['duration'] as String?),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> coordinates = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final int deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final int deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      coordinates.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return coordinates;
  }

  int? _asInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is double) {
      return raw.round();
    }
    return int.tryParse(raw?.toString() ?? '');
  }

  Duration? _parseDuration(String? raw) {
    if (raw == null || raw.isEmpty || !raw.endsWith('s')) {
      return null;
    }

    final String secondsText = raw.substring(0, raw.length - 1);
    final double? seconds = double.tryParse(secondsText);
    if (seconds == null || !seconds.isFinite || seconds < 0) {
      return null;
    }

    return Duration(milliseconds: (seconds * 1000).round());
  }
}

class RoutesApiException implements Exception {
  const RoutesApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
