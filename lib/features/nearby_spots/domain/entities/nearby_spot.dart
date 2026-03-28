class NearbySpot {
  const NearbySpot({
    required this.id,
    required this.name,
    required this.primaryType,
    this.rating,
    this.distanceMeters,
  });

  final String id;
  final String name;
  final String primaryType;
  final double? rating;
  final double? distanceMeters;

  String get ratingLabel {
    final double? currentRating = rating;
    if (currentRating == null) {
      return 'No ratings yet';
    }

    return currentRating.toStringAsFixed(1);
  }

  String get distanceLabel {
    final double? meters = distanceMeters;
    if (meters == null) {
      return 'Distance unavailable';
    }

    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    final double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km away';
  }

  factory NearbySpot.fromPlacesJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? primaryTypeDisplayName =
        _asStringMap(json['primaryTypeDisplayName']);
    final Map<String, dynamic>? displayName = _asStringMap(json['displayName']);

    return NearbySpot(
      id: _asString(json['id']),
      name: _asString(displayName?['text']),
      primaryType: _resolvePrimaryType(primaryTypeDisplayName, json['types']),
      rating: _asDouble(json['rating']),
      distanceMeters: _asDouble(json['distanceMeters']),
    );
  }

  static String _resolvePrimaryType(
    Map<String, dynamic>? primaryTypeDisplayName,
    Object? types,
  ) {
    final String primary = _asString(primaryTypeDisplayName?['text']);
    if (primary.isNotEmpty) {
      return primary;
    }

    if (types is List<Object?>) {
      for (final Object? value in types) {
        final String type = _asString(value);
        if (type.isNotEmpty) {
          return type.replaceAll('_', ' ');
        }
      }
    }

    return 'Place';
  }

  static String _asString(Object? value) {
    if (value is String) {
      return value;
    }

    return '';
  }

  static Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    return null;
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return null;
  }
}

enum NearbySpotCategory {
  eateries(
    label: 'Eateries',
    includedTypes: <String>['restaurant'],
  ),
  cafes(
    label: 'Cafes',
    includedTypes: <String>['cafe'],
  ),
  chillSpots(
    label: 'Chill Spots',
    includedTypes: <String>['tourist_attraction', 'park', 'shopping_mall'],
  );

  const NearbySpotCategory({
    required this.label,
    required this.includedTypes,
  });

  final String label;
  final List<String> includedTypes;
}
