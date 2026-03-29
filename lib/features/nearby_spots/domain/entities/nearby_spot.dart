class NearbySpot {
  const NearbySpot({
    required this.id,
    required this.name,
    required this.primaryType,
    this.rating,
    this.distanceMeters,
    this.latitude,
    this.longitude,
    this.photoReference,
  });

  final String id;
  final String name;
  final String primaryType;
  final double? rating;
  final double? distanceMeters;
  final double? latitude;
  final double? longitude;
  final String? photoReference;

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
    final Map<String, dynamic>? displayName = _asStringMap(json['displayName']);
    final Map<String, dynamic>? location = _asStringMap(json['location']);

    String? firstPhotoReference;
    final Object? photos = json['photos'];
    if (photos is List<Object?> && photos.isNotEmpty) {
      final Map<String, dynamic>? firstPhoto = _asStringMap(photos.first);
      firstPhotoReference = _asString(firstPhoto?['name']);
    }

    return NearbySpot(
      id: _asString(json['id']),
      name: _asString(displayName?['text']),
      primaryType: _resolvePrimaryType(json['primaryType'], json['types']),
      rating: _asDouble(json['rating']),
      distanceMeters: _asDouble(json['distanceMeters']),
      latitude: _asDouble(location?['latitude']),
      longitude: _asDouble(location?['longitude']),
      photoReference: firstPhotoReference,
    );
  }

  static String _resolvePrimaryType(
    Object? primaryType,
    Object? types,
  ) {
    final String primary = _asString(primaryType);
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
    label: 'Cafés',
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
