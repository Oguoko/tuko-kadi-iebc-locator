import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RoutePreviewData {
  const RoutePreviewData({
    required this.points,
    required this.distanceMeters,
    required this.duration,
    required this.encodedPolyline,
    this.bounds,
  });

  final List<LatLng> points;
  final int? distanceMeters;
  final Duration? duration;
  final String encodedPolyline;
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
        'Route preview fallback reason: missing API key. '
        'Pass --dart-define=GOOGLE_ROUTES_API_KEY=your_key.',
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
        'X-Goog-FieldMask': _responseFieldMask,
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final _RoutesFailure failure = _classifyFailure(response);
      if (kDebugMode) {
        debugPrint('Google Routes computeRoutes request failed.');
        debugPrint('Endpoint: $uri');
        debugPrint('Method: POST');
        debugPrint('Field mask: $_responseFieldMask');
        debugPrint('HTTP status: ${response.statusCode}');
        debugPrint('Fallback reason: ${failure.reason.name}');
        debugPrint('Request JSON: ${jsonEncode(requestBody)}');
        debugPrint('Response body (${response.bodyBytes.length} bytes): ${response.body}');
      }
      throw RoutesApiException(
        failure.message,
        fallbackReason: failure.reason,
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
      encodedPolyline: encodedPolyline,
      bounds: _parseBounds(firstRoute['viewport']),
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

  LatLngBounds? _parseBounds(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }

    final LatLng? low = _parseLatLng(raw['low']);
    final LatLng? high = _parseLatLng(raw['high']);
    if (low == null || high == null) {
      return null;
    }
    return LatLngBounds(southwest: low, northeast: high);
  }

  LatLng? _parseLatLng(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }

    final double? lat = _asDouble(raw['latitude']);
    final double? lng = _asDouble(raw['longitude']);
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  }

  double? _asDouble(Object? raw) {
    if (raw is double) {
      return raw;
    }
    if (raw is int) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '');
  }

  void _validateCoordinates({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) {
    final bool isValidOrigin =
        originLat.isFinite &&
        originLng.isFinite &&
        originLat >= -90 &&
        originLat <= 90 &&
        originLng >= -180 &&
        originLng <= 180;
    final bool isValidDestination =
        destinationLat.isFinite &&
        destinationLng.isFinite &&
        destinationLat >= -90 &&
        destinationLat <= 90 &&
        destinationLng >= -180 &&
        destinationLng <= 180;
    if (!isValidOrigin || !isValidDestination) {
      throw const RoutesApiException(
        'Route preview fallback reason: malformed request. '
        'Origin or destination coordinates are invalid.',
        fallbackReason: RouteFallbackReason.malformedRequest,
      );
    }
  }

  _RoutesFailure _classifyFailure(http.Response response) {
    final _ApiErrorDetails details = _parseApiError(response.body);
    final int statusCode = response.statusCode;
    final String statusText = details.status.toUpperCase();
    final String combinedText = '${details.message} ${response.body}'.toLowerCase();
    final bool hasBillingSignal =
        combinedText.contains('billing') || combinedText.contains('billing_disabled');
    final bool hasApiEnablementSignal =
        combinedText.contains('service_disabled') ||
        combinedText.contains('api has not been used') ||
        combinedText.contains('is not enabled') ||
        combinedText.contains('routes api has not been used');

    if (statusCode == 400 || statusText == 'INVALID_ARGUMENT') {
      return const _RoutesFailure(
        reason: RouteFallbackReason.malformedRequest,
        message:
            'Route preview fallback reason: malformed request. '
            'Google Routes rejected request parameters (HTTP 400 / INVALID_ARGUMENT).',
      );
    }

    if (hasBillingSignal) {
      return const _RoutesFailure(
        reason: RouteFallbackReason.missingBilling,
        message:
            'Route preview fallback reason: missing billing. '
            'Enable billing for the Google Cloud project used by GOOGLE_ROUTES_API_KEY.',
      );
    }

    if (hasApiEnablementSignal) {
      return const _RoutesFailure(
        reason: RouteFallbackReason.missingApiEnablement,
        message:
            'Route preview fallback reason: missing API enablement. '
            'Enable the Routes API for this key/project in Google Cloud.',
      );
    }

    if (statusCode == 403 || statusText == 'PERMISSION_DENIED') {
      return const _RoutesFailure(
        reason: RouteFallbackReason.permissionDenied,
        message:
            'Route preview fallback reason: 403 permission issue. '
            'Check API key restrictions (HTTP referrer/app restrictions) and allowed APIs.',
      );
    }

    return _RoutesFailure(
      reason: RouteFallbackReason.unknown,
      message:
          'Route preview fallback reason: unexpected error '
          '(HTTP $statusCode${details.status.isEmpty ? '' : ' / ${details.status}'}).',
    );
  }

  _ApiErrorDetails _parseApiError(String body) {
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return const _ApiErrorDetails();
      }
      final Object? error = decoded['error'];
      if (error is! Map<String, dynamic>) {
        return const _ApiErrorDetails();
      }
      return _ApiErrorDetails(
        status: error['status']?.toString() ?? '',
        message: error['message']?.toString() ?? '',
      );
    } catch (_) {
      return const _ApiErrorDetails();
    }
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
  const RoutesApiException(
    this.message, {
    this.fallbackReason = RouteFallbackReason.unknown,
  });

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

class _ApiErrorDetails {
  const _ApiErrorDetails({
    this.status = '',
    this.message = '',
  });

  final String status;
  final String message;
}
