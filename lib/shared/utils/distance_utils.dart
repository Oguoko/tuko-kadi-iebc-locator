import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class DistanceUtils {
  const DistanceUtils._();

  static const double _defaultUrbanSpeedKmh = 40;

  static double calculateDistanceMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  static int? estimateEtaMinutes(
    double? distanceMeters, {
    double speedKmh = _defaultUrbanSpeedKmh,
  }) {
    final double? meters = distanceMeters;
    if (meters == null || !meters.isFinite || meters < 0) {
      return null;
    }

    if (!speedKmh.isFinite || speedKmh <= 0) {
      return null;
    }

    final double speedMetersPerMinute = (speedKmh * 1000) / 60;
    final int estimatedMinutes = (meters / speedMetersPerMinute).ceil();
    return math.max(1, estimatedMinutes);
  }

  static String formatDistanceLabel(
    double? distanceMeters, {
    String fallback = 'Distance unavailable',
  }) {
    final double? meters = distanceMeters;
    if (meters == null || !meters.isFinite || meters < 0) {
      return fallback;
    }

    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    final double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km away';
  }

  static String formatEtaLabel(
    int? etaMinutes, {
    String fallback = 'ETA unavailable',
  }) {
    final int? minutes = etaMinutes;
    if (minutes == null || minutes <= 0) {
      return fallback;
    }

    return '$minutes min away';
  }

  static String formatEtaLabelFromDistance(
    double? distanceMeters, {
    String fallback = 'ETA unavailable',
    double speedKmh = _defaultUrbanSpeedKmh,
  }) {
    final int? etaMinutes = estimateEtaMinutes(
      distanceMeters,
      speedKmh: speedKmh,
    );
    return formatEtaLabel(etaMinutes, fallback: fallback);
  }
}
