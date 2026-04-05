import 'package:tuko_kadi_iebc_locator/shared/utils/google_maps_directions.dart';

enum DirectionsFlow {
  externalGoogleMaps,
  inAppPreview,
}

enum DirectionsFailure {
  invalidCoordinates,
  unableToLaunch,
  unsupportedFlow,
}

class DirectionsResult {
  const DirectionsResult._({this.failure});

  const DirectionsResult.success() : this._();

  const DirectionsResult.failure(DirectionsFailure failure)
      : this._(failure: failure);

  final DirectionsFailure? failure;

  bool get isSuccess => failure == null;
}

class DirectionsService {
  const DirectionsService({
    this.defaultFlow = DirectionsFlow.externalGoogleMaps,
  });

  final DirectionsFlow defaultFlow;

  bool hasValidDestination(double? lat, double? lng) {
    return GoogleMapsDirections.hasValidCoordinates(lat, lng);
  }

  Future<DirectionsResult> openDirections({
    required double? lat,
    required double? lng,
    DirectionsFlow? flow,
  }) async {
    if (!hasValidDestination(lat, lng)) {
      return const DirectionsResult.failure(
        DirectionsFailure.invalidCoordinates,
      );
    }

    if (lat == null || lng == null) {
      return const DirectionsResult.failure(
        DirectionsFailure.invalidCoordinates,
      );
    }

    switch (flow ?? defaultFlow) {
      case DirectionsFlow.externalGoogleMaps:
        final bool launched =
            await GoogleMapsDirections.openDirections(
          lat: lat,
          lng: lng,
        );

        return launched
            ? const DirectionsResult.success()
            : const DirectionsResult.failure(
                DirectionsFailure.unableToLaunch,
              );

      case DirectionsFlow.inAppPreview:
        return const DirectionsResult.failure(
          DirectionsFailure.unsupportedFlow,
        );
    }
  }
}