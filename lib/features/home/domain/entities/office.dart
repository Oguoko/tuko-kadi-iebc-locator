import 'package:tuko_kadi_iebc_locator/shared/utils/distance_utils.dart';

class Office {
  const Office({
    required this.id,
    required this.county,
    required this.constituency,
    required this.officeLocation,
    required this.landmark,
    this.estimatedDistanceText,
    this.lat,
    this.lng,
    this.distanceMeters,
  });

  final String id;
  final String county;
  final String constituency;
  final String officeLocation;
  final String landmark;
  final String? estimatedDistanceText;
  final double? lat;
  final double? lng;
  final double? distanceMeters;

  Office copyWith({
    String? id,
    String? county,
    String? constituency,
    String? officeLocation,
    String? landmark,
    String? estimatedDistanceText,
    double? lat,
    double? lng,
    double? distanceMeters,
  }) {
    return Office(
      id: id ?? this.id,
      county: county ?? this.county,
      constituency: constituency ?? this.constituency,
      officeLocation: officeLocation ?? this.officeLocation,
      landmark: landmark ?? this.landmark,
      estimatedDistanceText: estimatedDistanceText ?? this.estimatedDistanceText,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }

  String get distanceLabel {
    return DistanceUtils.formatDistanceLabel(
      distanceMeters,
      fallback: estimatedDistanceText ?? 'Distance unavailable',
    );
  }

  String get etaLabel {
    return DistanceUtils.formatEtaLabelFromDistance(distanceMeters);
  }
}
