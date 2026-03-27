import 'package:geolocator/geolocator.dart';

class DistanceUtils {
  const DistanceUtils._();

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

  static String formatDistanceLabel(
    double? distanceMeters, {
    String fallback = 'Distance unavailable',
  }) {
    final double? meters = distanceMeters;
    if (meters == null) {
      return fallback;
    }

    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    final double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km away';
  }
}
