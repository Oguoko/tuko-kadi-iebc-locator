import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tuko_kadi_iebc_locator/app/router/app_router.dart';
import 'package:tuko_kadi_iebc_locator/app/theme/app_theme.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/shared/services/directions_service.dart';
import 'package:tuko_kadi_iebc_locator/shared/services/google_routes_service.dart';
import 'package:tuko_kadi_iebc_locator/shared/utils/distance_utils.dart';

class OfficeDetailsScreen extends StatefulWidget {
  OfficeDetailsScreen({
    super.key,
    this.office,
    this.directionsService = const DirectionsService(),
    GoogleRoutesService? routesService,
  }) : routesService = routesService ?? GoogleRoutesService();

  final Office? office;
  final DirectionsService directionsService;
  final GoogleRoutesService routesService;

  @override
  State<OfficeDetailsScreen> createState() => _OfficeDetailsScreenState();
}

class _OfficeDetailsScreenState extends State<OfficeDetailsScreen> {
  RoutePreviewData? _routePreview;
  LatLng? _originLatLng;
  String? _routePreviewDebugError;
  bool _isRouteLoading = false;
  bool _isRoutePreviewVisible = false;

  @override
  void initState() {
    super.initState();
    _loadRoutePreview();
  }

  Future<void> _loadRoutePreview() async {
    final Office? currentOffice = widget.office;
    if (currentOffice == null || currentOffice.lat == null || currentOffice.lng == null) {
      return;
    }

    setState(() {
      _isRouteLoading = true;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final RoutePreviewData? preview = await widget.routesService.computeRoute(
        originLat: position.latitude,
        originLng: position.longitude,
        destinationLat: currentOffice.lat!,
        destinationLng: currentOffice.lng!,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _originLatLng = LatLng(position.latitude, position.longitude);
        _routePreview = preview;
        _routePreviewDebugError = null;
      });
    } on RoutesApiException catch (error) {
      if (kDebugMode) {
        debugPrint('Route preview failed: ${error.message}');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _routePreviewDebugError = error.message;
      });
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Unexpected route preview failure: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _routePreviewDebugError = 'Unexpected route preview error: $error';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRouteLoading = false;
      });
    }
  }

  Future<void> _handlePreviewRouteTap() async {
    if (_isRouteLoading) {
      return;
    }

    if (_routePreview == null || _originLatLng == null) {
      await _loadRoutePreview();
    }

    if (!mounted) {
      return;
    }

    if (_routePreview != null && _originLatLng != null && _routePreview!.points.length > 1) {
      setState(() {
        _isRoutePreviewVisible = true;
      });
    } else {
      final Office? currentOffice = widget.office;
      final DirectionsResult result = await widget.directionsService.openDirections(
        lat: currentOffice?.lat,
        lng: currentOffice?.lng,
        flow: DirectionsFlow.externalGoogleMaps,
      );

      if (!mounted || result.isSuccess) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(routeDirectionsErrorMessage(result.failure))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Office? currentOffice = widget.office;
    if (currentOffice == null) {
      return const Scaffold(
        body: SafeArea(child: _NoOfficeSelectedState()),
      );
    }

    final bool canOpenDirections = widget.directionsService.hasValidDestination(
      currentOffice.lat,
      currentOffice.lng,
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _TopHeader(office: currentOffice),
              const SizedBox(height: 18),
              _EditorialHero(
                office: currentOffice,
                routePreview: _routePreview,
                originLatLng: _originLatLng,
                isRouteLoading: _isRouteLoading,
                isRoutePreviewVisible: _isRoutePreviewVisible,
              ),
              const SizedBox(height: 18),
              _PrimaryActionRow(
                office: currentOffice,
                canOpenDirections: canOpenDirections,
                directionsService: widget.directionsService,
                routePreview: _routePreview,
                routePreviewDebugError: _routePreviewDebugError,
                isRouteLoading: _isRouteLoading,
                onPreviewRouteTap: _handlePreviewRouteTap,
                isRoutePreviewVisible: _isRoutePreviewVisible,
              ),
              if (!canOpenDirections) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  'Directions unavailable: office coordinates are missing or invalid.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 24),
              const _FaqSection(),
              const SizedBox(height: 24),
              _NearbySpotsPreview(office: currentOffice),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _StandaloneBottomNav(activeIndex: 0),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.office});

  final Office office;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                office.constituency,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                office.county,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.red,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.red.withValues(alpha: 0.34),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _EditorialHero extends StatelessWidget {
  const _EditorialHero({
    required this.office,
    required this.routePreview,
    required this.originLatLng,
    required this.isRouteLoading,
    required this.isRoutePreviewVisible,
  });

  final Office office;
  final RoutePreviewData? routePreview;
  final LatLng? originLatLng;
  final bool isRouteLoading;
  final bool isRoutePreviewVisible;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _MapHero(
          office: office,
          routePreview: routePreview,
          originLatLng: originLatLng,
          isRouteLoading: isRouteLoading,
          isRoutePreviewVisible: isRoutePreviewVisible,
        ),
      ),
    );
  }
}

class _MapHero extends StatefulWidget {
  const _MapHero({
    required this.office,
    required this.routePreview,
    required this.originLatLng,
    required this.isRouteLoading,
    required this.isRoutePreviewVisible,
  });

  final Office office;
  final RoutePreviewData? routePreview;
  final LatLng? originLatLng;
  final bool isRouteLoading;
  final bool isRoutePreviewVisible;

  @override
  State<_MapHero> createState() => _MapHeroState();
}

class _MapHeroState extends State<_MapHero> {
  GoogleMapController? _mapController;
  bool _hasAppliedRouteFit = false;

  bool get _hasRenderableRoute =>
      widget.isRoutePreviewVisible && (widget.routePreview?.points.length ?? 0) > 1;

  @override
  void didUpdateWidget(covariant _MapHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool pointsChanged = oldWidget.routePreview?.points.length != widget.routePreview?.points.length;
    final bool originChanged = oldWidget.originLatLng != widget.originLatLng;
    final bool visibilityChanged = oldWidget.isRoutePreviewVisible != widget.isRoutePreviewVisible;
    if (pointsChanged || originChanged || visibilityChanged) {
      _hasAppliedRouteFit = false;
      _fitRouteBoundsIfPossible();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCoordinates = widget.office.lat != null && widget.office.lng != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 328,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: hasCoordinates
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(widget.office.lat!, widget.office.lng!),
                        zoom: 14.4,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                        _fitRouteBoundsIfPossible();
                      },
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      markers: <Marker>{
                        if (_hasRenderableRoute && widget.originLatLng != null)
                          Marker(
                            markerId: const MarkerId('route-origin'),
                            position: widget.originLatLng!,
                            infoWindow: const InfoWindow(title: 'Your location'),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueBlue,
                            ),
                          ),
                        if (_hasRenderableRoute)
                          Marker(
                            markerId: const MarkerId('route-destination'),
                            position: LatLng(widget.office.lat!, widget.office.lng!),
                            infoWindow: InfoWindow(
                              title: widget.office.constituency,
                              snippet: 'IEBC Office',
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed,
                            ),
                          ),
                      },
                      polylines: <Polyline>{
                        if (_hasRenderableRoute)
                          Polyline(
                            polylineId: const PolylineId('office-preview-route'),
                            points: widget.routePreview!.points,
                            color: AppTheme.red,
                            width: 9,
                            geodesic: true,
                            jointType: JointType.round,
                            startCap: Cap.roundCap,
                            endCap: Cap.roundCap,
                          ),
                      },
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[Color(0xFF111111), Color(0xFFE53935)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.map_outlined, color: Colors.white, size: 46),
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.68),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Official IEBC Desk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.office.officeLocation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hasRenderableRoute
                        ? 'In-app route preview on map'
                        : DistanceUtils.formatDistanceLabel(
                            widget.office.distanceMeters,
                            fallback: widget.office.estimatedDistanceText ?? 'Distance unavailable',
                          ),
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (widget.isRouteLoading)
              const Positioned(
                right: 14,
                top: 14,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _fitRouteBoundsIfPossible() async {
    if (_hasAppliedRouteFit) {
      return;
    }
    final GoogleMapController? controller = _mapController;
    final double? lat = widget.office.lat;
    final double? lng = widget.office.lng;
    if (controller == null || lat == null || lng == null) {
      return;
    }

    final List<LatLng> routePoints = widget.routePreview?.points ?? <LatLng>[];
    if (!_hasRenderableRoute) {
      return;
    }

    LatLngBounds? fitBounds = widget.routePreview?.bounds;
    if (fitBounds == null && widget.originLatLng != null) {
      fitBounds = _boundsFromPoints(<LatLng>[
        widget.originLatLng!,
        LatLng(lat, lng),
      ]);
    }
    if (fitBounds == null && routePoints.length > 1) {
      fitBounds = _boundsFromPoints(routePoints);
    }
    if (fitBounds == null) {
      return;
    }

    _hasAppliedRouteFit = true;
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        fitBounds,
        58,
      ),
    );
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

    if ((maxLat - minLat).abs() < 0.00005) {
      minLat -= 0.0015;
      maxLat += 0.0015;
    }
    if ((maxLng - minLng).abs() < 0.00005) {
      minLng -= 0.0015;
      maxLng += 0.0015;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

class _PrimaryActionRow extends StatelessWidget {
  const _PrimaryActionRow({
    required this.office,
    required this.canOpenDirections,
    required this.directionsService,
    required this.routePreview,
    required this.routePreviewDebugError,
    required this.isRouteLoading,
    required this.onPreviewRouteTap,
    required this.isRoutePreviewVisible,
  });

  final Office office;
  final bool canOpenDirections;
  final DirectionsService directionsService;
  final RoutePreviewData? routePreview;
  final String? routePreviewDebugError;
  final bool isRouteLoading;
  final Future<void> Function() onPreviewRouteTap;
  final bool isRoutePreviewVisible;

  @override
  Widget build(BuildContext context) {
    final bool hasRoutePreview = routePreview != null;
    final bool hasRenderableRoute = (routePreview?.points.length ?? 0) > 1;

    return Column(
      children: <Widget>[
        _RouteSummaryCard(
          routePreview: routePreview,
          routePreviewDebugError: routePreviewDebugError,
          isRouteLoading: isRouteLoading,
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: canOpenDirections ? onPreviewRouteTap : null,
            icon: const Icon(Icons.route_rounded),
            label: Text(
              hasRoutePreview && isRoutePreviewVisible && hasRenderableRoute
                  ? 'Previewing Route In-App'
                  : 'Preview Route In-App',
            ),
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: canOpenDirections
                ? () async {
                    final DirectionsResult result = await directionsService.openDirections(
                      lat: office.lat,
                      lng: office.lng,
                      flow: DirectionsFlow.externalGoogleMaps,
                    );

                    if (!result.isSuccess && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(routeDirectionsErrorMessage(result.failure))),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open in Google Maps'),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Call Office will be enabled soon.')),
                  );
                },
                icon: const Icon(Icons.call_rounded),
                label: const Text('Call Office'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share location will be added soon.')),
                  );
                },
                icon: const Icon(Icons.share_location_rounded),
                label: const Text('Share Location'),
              ),
            ),
          ],
        ),
      ],
    );
  }

}

String routeDirectionsErrorMessage(DirectionsFailure? failure) {
  switch (failure) {
    case DirectionsFailure.invalidCoordinates:
      return 'Directions unavailable: office coordinates are missing or invalid.';
    case DirectionsFailure.unsupportedFlow:
      return 'In-app route preview is not available yet.';
    case DirectionsFailure.unableToLaunch:
    case null:
      return 'Unable to open Google Maps directions.';
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.routePreview,
    required this.routePreviewDebugError,
    required this.isRouteLoading,
  });

  final RoutePreviewData? routePreview;
  final String? routePreviewDebugError;
  final bool isRouteLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Route options',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _RouteStatTile(
                  icon: Icons.straighten_rounded,
                  title: 'Distance',
                  value: _distanceLabel(routePreview?.distanceMeters),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RouteStatTile(
                  icon: Icons.schedule_rounded,
                  title: 'ETA',
                  value: _durationLabel(routePreview?.duration),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            routePreview == null
                ? 'Live preview is still loading. We will fall back to Google Maps if needed.'
                : 'This map shows your in-app route preview.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (isRouteLoading) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Loading live route preview...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          if (kDebugMode && routePreviewDebugError != null && routePreviewDebugError!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Developer debug: $routePreviewDebugError',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.deepOrange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _distanceLabel(int? distanceMeters) {
    if (distanceMeters == null || distanceMeters < 0) {
      return 'Distance unavailable';
    }
    if (distanceMeters < 1000) {
      return '${distanceMeters} m';
    }
    final double kilometers = distanceMeters / 1000;
    return '${kilometers.toStringAsFixed(kilometers >= 10 ? 0 : 1)} km';
  }

  String _durationLabel(Duration? duration) {
    if (duration == null || duration.inSeconds <= 0) {
      return 'Time unavailable';
    }
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    }
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }
}

class _RouteStatTile extends StatelessWidget {
  const _RouteStatTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppTheme.red),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  static const List<_FaqItemData> _faqItems = <_FaqItemData>[
    _FaqItemData(
      question: 'What do I need to register as a voter?',
      answer: 'Your original national ID card or a valid Kenyan passport.',
    ),
    _FaqItemData(
      question: 'Do I need my acknowledgement slip to vote later?',
      answer:
          'No. IEBC says the acknowledgement slip is issued after registration, but it is not a requirement for voting.',
    ),
    _FaqItemData(
      question: 'Can I register more than once?',
      answer: 'No. A person is only allowed to register once.',
    ),
    _FaqItemData(
      question: 'Can I transfer my registration centre later?',
      answer: 'Yes. A voter may transfer to another registration centre during the registration period.',
    ),
    _FaqItemData(
      question: 'Why should I register?',
      answer:
          'Registration allows you to vote, vie for office, nominate candidates, and hold leaders accountable.',
    ),
    _FaqItemData(
      question: 'When can someone be denied registration?',
      answer:
          'A person may be denied if they are under 18, do not have the original ID/passport, are an undischarged bankrupt, have certain election-offence findings in the last five years, or are declared of unsound mind by a competent court.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionTitle(title: 'Registration FAQ', icon: Icons.quiz_rounded),
          const SizedBox(height: 10),
          Text(
            'Quick guidance from IEBC voter registration information.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          for (final _FaqItemData item in _faqItems)
            _FaqItem(question: item.question, answer: item.answer),
        ],
      ),
    );
  }
}

class _FaqItemData {
  const _FaqItemData({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        collapsedShape: const Border(),
        shape: const Border(),
        iconColor: AppTheme.red,
        collapsedIconColor: AppTheme.red,
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w800)),
        children: <Widget>[
          Text(
            answer,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _NearbySpotsPreview extends StatelessWidget {
  const _NearbySpotsPreview({required this.office});

  final Office office;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const _SectionTitle(title: 'Nearby Spots', icon: Icons.local_fire_department_rounded),
            TextButton(
              onPressed: () => context.push(AppRoutes.nearbySpots, extra: office),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 182,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              _PreviewSpotCard(
                title: 'Local Eateries',
                subtitle: 'Food • 2-8 min walk',
                icon: Icons.restaurant_rounded,
              ),
              _PreviewSpotCard(
                title: 'Coffee Stops',
                subtitle: 'Cafés • good Wi‑Fi',
                icon: Icons.local_cafe_rounded,
              ),
              _PreviewSpotCard(
                title: 'Chill Spots',
                subtitle: 'Parks • unwind nearby',
                icon: Icons.park_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewSpotCard extends StatelessWidget {
  const _PreviewSpotCard({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF101010), Color(0xFFE53935)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18, color: AppTheme.red),
        const SizedBox(width: 6),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
      ],
    );
  }
}

class _NoOfficeSelectedState extends StatelessWidget {
  const _NoOfficeSelectedState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.info_outline_rounded, size: 34, color: colors.primary),
                const SizedBox(height: 12),
                Text(
                  'No office selected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select an office from the home screen card or map marker to view full details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StandaloneBottomNav extends StatelessWidget {
  const _StandaloneBottomNav({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: NavigationBar(
        selectedIndex: activeIndex,
        indicatorColor: AppTheme.red.withValues(alpha: 0.16),
        onDestinationSelected: (int index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.explore);
              return;
            case 1:
              context.go(AppRoutes.search);
              return;
            case 2:
              context.go(AppRoutes.savedFavorites);
              return;
            case 3:
              context.go(AppRoutes.profile);
              return;
          }
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
