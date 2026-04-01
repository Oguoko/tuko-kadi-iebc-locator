abstract final class OfficeCoordinateValidator {
  static const double _minKenyaLatitude = -5.5;
  static const double _maxKenyaLatitude = 5.5;
  static const double _minKenyaLongitude = 33.5;
  static const double _maxKenyaLongitude = 42.5;

  static bool hasValidWorldBounds(double? lat, double? lng) {
    if (lat == null || lng == null) {
      return false;
    }

    if (!lat.isFinite || !lng.isFinite) {
      return false;
    }

    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  static bool isWithinKenyaBounds(double lat, double lng) {
    return lat >= _minKenyaLatitude &&
        lat <= _maxKenyaLatitude &&
        lng >= _minKenyaLongitude &&
        lng <= _maxKenyaLongitude;
  }

  static bool isValidOfficeCoordinate(double? lat, double? lng) {
    if (!hasValidWorldBounds(lat, lng) || lat == null || lng == null) {
      return false;
    }

    return isWithinKenyaBounds(lat, lng);
  }
}
