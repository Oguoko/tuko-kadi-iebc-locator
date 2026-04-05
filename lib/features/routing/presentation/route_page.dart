import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tuko_kadi_iebc_locator/app/theme/app_theme.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/shared/services/directions_service.dart';
import 'package:tuko_kadi_iebc_locator/shared/services/google_routes_service.dart';
import 'package:tuko_kadi_iebc_locator/shared/utils/distance_utils.dart';
import 'package:tuko_kadi_iebc_locator/shared/utils/office_coordinate_validator.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({
    super.key,
    required this.office,
    GoogleRoutesService? routesService,
    this.directionsService = const DirectionsService(),
  }) : routesService = routesService ?? GoogleRoutesService();

  final Office office;
  final GoogleRoutesService routesService;
  final DirectionsService directionsService;

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(-1.286389, 36.817223),
    zoom: 10.5,
  );

  GoogleMapController? _mapController;
  LatLng? _origin;
  LatLng? _destination;
  RoutePreviewData? _routePreview;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _destination = _officeDestination();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    final LatLng? destination = _officeDestination();
    if (destination == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _destination = null;
        _origin = null;
        _routePreview = null;
        _isLoading = false;
      });
      return;
    }

    LatLng? origin;
    RoutePreviewData? routePreview;

    try {
      final Position? position = await _resolveUserPosition();
      if (position != null &&
          OfficeCoordinateValidator.hasValidWorldBounds(
            position.latitude,
            position.longitude,
          )) {
        origin = LatLng(position.latitude, position.longitude);
      }
    } catch (_) {
      origin = null;
    }

    if (origin != null) {
      try {
        routePreview = await widget.routesService.computeRoute(
          originLat: origin.latitude,
          originLng: origin.longitude,
          destinationLat: destination.latitude,
          destinationLng: destination.longitude,
        );
      } catch (_) {
        routePreview = null;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _origin = origin;
      _destination = destination;
      _routePreview = routePreview;
      _isLoading = false;
    });

    _fitBounds();
  }

  LatLng? _officeDestination() {
    final double? lat = widget.office.lat;
    final double? lng = widget.office.lng;
    if (!OfficeCoordinateValidator.isValidOfficeCoordinate(lat, lng)) {
      return null;
    }

    if (lat == null || lng == null) {
      return null;
    }

    return LatLng(lat, lng);
  }

  Future<Position?> _resolveUserPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Set<Marker> _markers() {
    final Set<Marker> markers = <Marker>{};

    final LatLng? origin = _origin;
    if (origin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: origin,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
          infoWindow: const InfoWindow(title: 'Your location'),
        ),
      );
    }

    final LatLng? destination = _destination;
    if (destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: widget.office.constituency,
            snippet: 'IEBC Office',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _polylines() {
    final List<LatLng> points = _routePreview?.points ?? <LatLng>[];
    if (points.length < 2) {
      return const <Polyline>{};
    }

    return <Polyline>{
      Polyline(
        polylineId: const PolylineId('office-route'),
        points: points,
        color: AppTheme.red,
        width: 7,
        geodesic: true,
      ),
    };
  }

  Future<void> _fitBounds() async {
    final GoogleMapController? controller = _mapController;
    if (controller == null) {
      return;
    }

    final LatLng? origin = _origin;
    final LatLng? destination = _destination;

    if (origin == null && destination == null) {
      return;
    }

    final LatLngBounds? bounds =
        _routePreview?.bounds ?? _boundsFromPoints(<LatLng>[...?_routePreview?.points, if (origin != null) origin, if (destination != null) destination]);
    if (bounds == null) {
      final LatLng? target = destination ?? origin;
      if (target == null) {
        return;
      }
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 13),
        ),
      );
      return;
    }

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 56));
  }

  LatLngBounds? _boundsFromPoints(List<LatLng> points) {
    if (points.length < 2) {
      return null;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final LatLng point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng? origin = _origin;
    final LatLng? destination = _destination;
    final double? distanceMeters = _distanceMeters();
    final String distanceLabel = DistanceUtils.formatDistanceLabel(distanceMeters);
    final String etaLabel = DistanceUtils.formatEtaLabelFromDistance(distanceMeters);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: destination != null
                  ? CameraPosition(target: destination, zoom: 13)
                  : _defaultCamera,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _fitBounds();
              },
              myLocationEnabled: !kIsWeb,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              markers: _markers(),
              polylines: _polylines(),
            ),
          ),
          if (_isLoading)
            const Positioned(
              top: 48,
              right: 16,
              child: CircularProgressIndicator(),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 22,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.office.constituency,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        _InfoChip(icon: Icons.straighten_rounded, label: distanceLabel),
                        const SizedBox(width: 8),
                        _InfoChip(icon: Icons.schedule_rounded, label: etaLabel),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: destination == null
                                ? null
                                : () async {
                                    final DirectionsResult result =
                                        await widget.directionsService.openDirections(
                                      lat: widget.office.lat,
                                      lng: widget.office.lng,
                                      flow: DirectionsFlow.externalGoogleMaps,
                                    );

                                    if (!result.isSuccess && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Unable to open Google Maps directions.'),
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Open in Google Maps'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back'),
                        ),
                      ],
                    ),
                    if (origin == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Your location is unavailable. Showing office marker only.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double? _distanceMeters() {
    final LatLng? origin = _origin;
    final LatLng? destination = _destination;
    if (origin == null || destination == null) {
      return widget.office.distanceMeters;
    }

    return DistanceUtils.calculateDistanceMeters(
      startLatitude: origin.latitude,
      startLongitude: origin.longitude,
      endLatitude: destination.latitude,
      endLongitude: destination.longitude,
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
