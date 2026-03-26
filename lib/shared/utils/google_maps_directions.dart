import 'package:url_launcher/url_launcher.dart';

abstract final class GoogleMapsDirections {
  static bool hasValidCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) {
      return false;
    }

    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  static Uri directionsUri({required double lat, required double lng}) {
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
  }

  static Future<bool> openDirections({
    required double lat,
    required double lng,
  }) {
    return launchUrl(
      directionsUri(lat: lat, lng: lng),
      mode: LaunchMode.externalApplication,
    );
  }
}
