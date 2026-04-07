import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/shared/services/directions_service.dart';
import 'package:tuko_kadi_iebc_locator/shared/services/google_routes_service.dart';
import 'package:tuko_kadi_iebc_locator/shared/utils/distance_utils.dart';
import 'package:tuko_kadi_iebc_locator/shared/utils/office_coordinate_validator.dart';

class RoutePage extends StatefulWidget {
  RoutePage({
    super.key,
    required this.office,
    this.directionsService = const DirectionsService(),
    GoogleRoutesService? routesService,
  }) : routesService = routesService ?? GoogleRoutesService();

  final Office office;
  final DirectionsService directionsService;
  final GoogleRoutesService routesService;

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(-1.286389, 36.817223),
    zoom: 10.5,
  );

  GoogleMapController? _mapController;
  LatLng? _userLocation;
  LatLng? _officeLocation;
  bool _isLoading = true;
  Set<Polyline> _polylines = <Polyline>{};

  @override
  void initState() {
    super.initState();
    _officeLocation = _resolveOfficeLocation();
    _loadUserLocation();
  }

  LatLng? _resolveOfficeLocation() {
    final double? latitude = widget.office.lat;
    final double? longitude = widget.office.lng;

    if (!OfficeCoordinateValidator.isValidOfficeCoordinate(latitude, longitude)) {
      return null;
    }

    if (latitude == null || longitude == null) {
      return null;
    }

    return LatLng(latitude, longitude);
  }

  Future<void> _loadUserLocation() async {
    LatLng? resolvedUserLocation;

    try {
      final Position? position = await _resolveUserPosition();
      if (position != null &&
          OfficeCoordinateValidator.hasValidWorldBounds(
            position.latitude,
            position.longitude,
          )) {
        resolvedUserLocation = LatLng(position.latitude, position.longitude);
      }
    } catch (_) {
      resolvedUserLocation = null;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _userLocation = resolvedUserLocation;
      _isLoading = false;
    });

    await _loadRoutePolyline();
    _fitBounds();
  }

  Future<void> _loadRoutePolyline() async {
    final LatLng? userLocation = _userLocation;
    final LatLng? officeLocation = _officeLocation;

    if (userLocation == null || officeLocation == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _polylines = <Polyline>{};
      });
      return;
    }

    try {
      final RoutePreviewData? routeData = await widget.routesService.computeRoute(
        originLat: userLocation.latitude,
        originLng: userLocation.longitude,
        destinationLat: officeLocation.latitude,
        destinationLng: officeLocation.longitude,
      );

      if (!mounted) {
        return;
      }

      final String? encodedPolyline = routeData?.encodedPolyline;
      if (encodedPolyline == null || encodedPolyline.isEmpty) {
        setState(() {
          _polylines = <Polyline>{};
        });
        return;
      }

      _drawPolyline(encodedPolyline);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _polylines = <Polyline>{};
      });
    }
  }

  void _drawPolyline(String encodedPolyline) {
    final PolylinePoints polylinePoints = PolylinePoints();

    final List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);

    final List<LatLng> points = result
        .map((PointLatLng point) => LatLng(point.latitude, point.longitude))
        .toList();

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.redAccent,
          width: 6,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          points: points,
        ),
      );
    });
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _fitBounds() async {
    final GoogleMapController? controller = _mapController;
    if (controller == null) {
      return;
    }

    final List<LatLng> points = <LatLng>[];
    final LatLng? userLocation = _userLocation;
    final LatLng? officeLocation = _officeLocation;
    if (userLocation != null) {
      points.add(userLocation);
    }
    if (officeLocation != null) {
      points.add(officeLocation);
    }

    if (points.isEmpty) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(_defaultCamera),
      );
      return;
    }

    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 13),
        ),
      );
      return;
    }

    final LatLngBounds? bounds = _boundsFromPoints(points);
    if (bounds == null) {
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

  Set<Marker> _markers() {
    final Set<Marker> markers = <Marker>{};

    final LatLng? user = _userLocation;
    if (user != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user-location'),
          position: user,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your location'),
        ),
      );
    }

    final LatLng? office = _officeLocation;
    if (office != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('office-location'),
          position: office,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: widget.office.constituency,
            snippet: 'IEBC Office',
          ),
        ),
      );
    }

    return markers;
  }

  double? _distanceMeters() {
    final LatLng? user = _userLocation;
    final LatLng? office = _officeLocation;

    return DistanceUtils.calculateDistanceMeters(
      user?.latitude,
      user?.longitude,
      office?.latitude,
      office?.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng? office = _officeLocation;
    final double? meters = _distanceMeters();
    final String distance = DistanceUtils.formatDistance(meters);
    final String eta = DistanceUtils.estimateETA(meters);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: office != null
                  ? CameraPosition(target: office, zoom: 13)
                  : _defaultCamera,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _fitBounds();
              },
              myLocationEnabled: !kIsWeb,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              markers: _markers(),
              polylines: _polylines,
            ),
          ),
          if (_isLoading)
            const Positioned(
              top: 48,
              right: 16,
              child: CircularProgressIndicator(),
            ),
          Positioned(
            top: 40,
            left: 12,
            child: SafeArea(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            ),
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
                        _InfoChip(icon: Icons.straighten_rounded, label: distance),
                        const SizedBox(width: 8),
                        _InfoChip(icon: Icons.schedule_rounded, label: eta),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: office == null
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
