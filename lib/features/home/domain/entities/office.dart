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
  });

  final String id;
  final String county;
  final String constituency;
  final String officeLocation;
  final String landmark;
  final String? estimatedDistanceText;
  final double? lat;
  final double? lng;

  String get distanceLabel => estimatedDistanceText ?? 'Distance unavailable';
}
