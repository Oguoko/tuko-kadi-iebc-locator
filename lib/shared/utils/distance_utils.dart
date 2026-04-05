import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class DistanceUtils {
  const DistanceUtils._();

  static const double _defaultUrbanSpeedKmh = 40;

  static double? calculateDistanceMeters(
    double? lat1,
    double? lon1,
    double? lat2,
    double? lon2,
  ) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
      return null;
    }

    if (!lat1.isFinite || !lon1.isFinite || !lat2.isFinite || !lon2.isFinite) {
      return null;
    }

    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  static String formatDistance(
    double? meters, {
    String fallback = 'Distance unavailable',
  }) {
    if (meters == null || !meters.isFinite || meters < 0) {
      return fallback;
    }

    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    final double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km away';
  }

  static String estimateETA(
    double? meters, {
    String fallback = 'ETA unavailable',
    double speedKmh = _defaultUrbanSpeedKmh,
  }) {
    if (meters == null || !meters.isFinite || meters < 0) {
      return fallback;
    }

    if (!speedKmh.isFinite || speedKmh <= 0) {
      return fallback;
    }

    final double speedMetersPerMinute = (speedKmh * 1000) / 60;
    final int estimatedMinutes = (meters / speedMetersPerMinute).ceil();
    final int minutes = math.max(1, estimatedMinutes);
    return '$minutes min away';
  }

  static int? estimateEtaMinutes(
    double? distanceMeters, {
    double speedKmh = _defaultUrbanSpeedKmh,
  }) {
    if (distanceMeters == null || !distanceMeters.isFinite || distanceMeters < 0) {
      return null;
    }

    if (!speedKmh.isFinite || speedKmh <= 0) {
      return null;
    }

    final double speedMetersPerMinute = (speedKmh * 1000) / 60;
    final int estimatedMinutes = (distanceMeters / speedMetersPerMinute).ceil();
    return math.max(1, estimatedMinutes);
  }

  static String formatDistanceLabel(
    double? distanceMeters, {
    String fallback = 'Distance unavailable',
  }) {
    return formatDistance(distanceMeters, fallback: fallback);
  }

  static String formatEtaLabel(
    int? etaMinutes, {
    String fallback = 'ETA unavailable',
  }) {
    if (etaMinutes == null || etaMinutes <= 0) {
      return fallback;
    }

    return '$etaMinutes min away';
  }

  static String formatEtaLabelFromDistance(
    double? distanceMeters, {
    String fallback = 'ETA unavailable',
    double speedKmh = _defaultUrbanSpeedKmh,
  }) {
    if (distanceMeters == null) {
      return fallback;
    }

    return estimateETA(
      distanceMeters,
      fallback: fallback,
      speedKmh: speedKmh,
    );
  }
}
