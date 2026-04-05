class NearbySpot {
  const NearbySpot({
    required this.id,
    required this.name,
    required this.primaryType,
    this.rating,
    this.distanceMeters,
    this.latitude,
    this.longitude,
    this.photos = const <NearbySpotPhoto>[],
  });

  final String id;
  final String name;
  final String primaryType;
  final double? rating;
  final double? distanceMeters;
  final double? latitude;
  final double? longitude;
  final List<NearbySpotPhoto> photos;

  String? get firstPhotoName {
    if (photos.isEmpty) return null;
    return photos.first.name;
  }

  String get ratingLabel {
    if (rating == null) return 'No ratings yet';
    return rating!.toStringAsFixed(1);
  }

  String get distanceLabel {
    if (distanceMeters == null) return 'Distance unavailable';

    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m away';
    }

    final km = distanceMeters! / 1000;
    return '${km.toStringAsFixed(1)} km away';
  }

  factory NearbySpot.fromPlacesJson(Map<String, dynamic> json) {
    final displayName = _asMap(json['displayName']);
    final location = _asMap(json['location']);

    return NearbySpot(
      id: _asString(json['id']),
      name: _asString(displayName?['text']),
      primaryType: _resolvePrimaryType(json['primaryType'], json['types']),
      rating: _asDouble(json['rating']),
      distanceMeters: _asDouble(json['distanceMeters']),
      latitude: _asDouble(location?['latitude']),
      longitude: _asDouble(location?['longitude']),
      photos: NearbySpotPhoto.listFromJson(json['photos']),
    );
  }

  static String _resolvePrimaryType(Object? primaryType, Object? types) {
    final primary = _asString(primaryType);
    if (primary.isNotEmpty) return primary;

    if (types is List) {
      for (final t in types) {
        final value = _asString(t);
        if (value.isNotEmpty) {
          return value.replaceAll('_', ' ');
        }
      }
    }

    return 'Place';
  }

  static String _asString(Object? value) {
    return value is String ? value : '';
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static double? _asDouble(Object? value) {
    return value is num ? value.toDouble() : null;
  }
}

class NearbySpotPhoto {
  const NearbySpotPhoto({
    required this.name,
    this.widthPx,
    this.heightPx,
  });

  final String name;
  final int? widthPx;
  final int? heightPx;

  factory NearbySpotPhoto.fromJson(Map<String, dynamic> json) {
    return NearbySpotPhoto(
      name: _asString(json['name']),
      widthPx: _asInt(json['widthPx']),
      heightPx: _asInt(json['heightPx']),
    );
  }

  static List<NearbySpotPhoto> listFromJson(Object? photos) {
    if (photos is! List) return const [];

    return photos
        .whereType<Map<String, dynamic>>()
        .map(NearbySpotPhoto.fromJson)
        .where((p) => p.name.trim().isNotEmpty)
        .toList();
  }

  static String _asString(Object? value) {
    return value is String ? value : '';
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}

enum NearbySpotCategory {
  eateries(
    label: 'Eateries',
    includedTypes: ['restaurant'],
  ),
  cafes(
    label: 'Cafés',
    includedTypes: ['cafe'],
  ),
  chillSpots(
    label: 'Chill Spots',
    includedTypes: ['tourist_attraction', 'park', 'shopping_mall'],
  );

  const NearbySpotCategory({
    required this.label,
    required this.includedTypes,
  });

  final String label;
  final List<String> includedTypes;
}