import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RoutePreviewData {
  const RoutePreviewData({
    required this.points,
    required this.distanceMeters,
    required this.duration,
    this.bounds,
  });

  final List<LatLng> points;
  final int? distanceMeters;
  final Duration? duration;
  final LatLngBounds? bounds;
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

  static const String _responseFieldMask =
      'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline';

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
        'Route preview fallback reason: missing API key.',
        fallbackReason: RouteFallbackReason.missingApiKey,
      );
    }

    _validateCoordinates(
      originLat: originLat,
      originLng: originLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    );

    final Uri uri = Uri.parse(_endpoint);

    final Map<String, dynamic> requestBody = {
      'origin': {
        'location': {
          'latLng': {
            'latitude': originLat,
            'longitude': originLng,
          },
        },
      },
      'destination': {
        'location': {
          'latLng': {
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

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': _responseFieldMask,
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final failure = _classifyFailure(response);

      if (kDebugMode) {
        debugPrint('Routes API failed: ${failure.reason}');
        debugPrint(response.body);
      }

      throw RoutesApiException(
        failure.message,
        fallbackReason: failure.reason,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final routes = decoded['routes'];

    // ✅ FULL SAFE CHECK
    if (routes is! List || routes.isEmpty) {
      return null;
    }

    final first = routes.first;

    if (first is! Map<String, dynamic>) {
      return null;
    }

    final firstRoute = first;

    final polyline = firstRoute['polyline'];

    if (polyline is! Map<String, dynamic>) {
      return null;
    }

    final encodedPolyline = polyline['encodedPolyline'];

    if (encodedPolyline is! String || encodedPolyline.isEmpty) {
      return null;
    }

    return RoutePreviewData(
      points: _decodePolyline(encodedPolyline),
      distanceMeters: _asInt(firstRoute['distanceMeters']),
      duration: _parseDuration(firstRoute['duration'] as String?),
      bounds: _parseBounds(firstRoute['viewport']),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> coordinates = [];
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

      final deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      coordinates.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return coordinates;
  }

  int? _asInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    return int.tryParse(raw?.toString() ?? '');
  }

  Duration? _parseDuration(String? raw) {
    if (raw == null || !raw.endsWith('s')) return null;

    final seconds = double.tryParse(raw.replaceAll('s', ''));

    if (seconds == null) return null;

    return Duration(milliseconds: (seconds * 1000).round());
  }

  LatLngBounds? _parseBounds(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;

    final low = _parseLatLng(raw['low']);
    final high = _parseLatLng(raw['high']);

    if (low == null || high == null) return null;

    return LatLngBounds(southwest: low, northeast: high);
  }

  LatLng? _parseLatLng(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;

    final lat = _asDouble(raw['latitude']);
    final lng = _asDouble(raw['longitude']);

    if (lat == null || lng == null) return null;

    return LatLng(lat, lng);
  }

  double? _asDouble(Object? raw) {
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }

  void _validateCoordinates({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) {
    if (!originLat.isFinite ||
        !originLng.isFinite ||
        !destinationLat.isFinite ||
        !destinationLng.isFinite) {
      throw const RoutesApiException('Invalid coordinates');
    }
  }

  _RoutesFailure _classifyFailure(http.Response response) {
    return const _RoutesFailure(
      reason: RouteFallbackReason.unknown,
      message: 'Routes API error',
    );
  }
}

enum RouteFallbackReason {
  missingApiEnablement,
  permissionDenied,
  missingBilling,
  malformedRequest,
  missingApiKey,
  unknown,
}

class RoutesApiException implements Exception {
  const RoutesApiException(this.message, {this.fallbackReason = RouteFallbackReason.unknown});

  final String message;
  final RouteFallbackReason fallbackReason;

  @override
  String toString() => message;
}

class _RoutesFailure {
  const _RoutesFailure({
    required this.reason,
    required this.message,
  });

  final RouteFallbackReason reason;
  final String message;
}