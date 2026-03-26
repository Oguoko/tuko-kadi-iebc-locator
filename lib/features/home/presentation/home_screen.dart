import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tuko_kadi_iebc_locator/app/router/app_router.dart';
import 'package:tuko_kadi_iebc_locator/features/home/application/offices_provider.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/widgets/filter_chip_row.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/widgets/home_bottom_sheet.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/widgets/home_search_bar.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/widgets/office_preview_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const CameraPosition _defaultKenyaCamera = CameraPosition(
    target: LatLng(-0.0236, 37.9062),
    zoom: 6.0,
  );

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  bool _isLocationReady = false;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLocationReady = true;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLocationReady = true;
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLocationReady = true;
      });

      _centerMapToUser();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLocationReady = true;
      });
    }
  }

  void _centerMapToUser() {
    final LatLng? userLocation = _userLocation;
    final GoogleMapController? controller = _mapController;

    if (userLocation == null || controller == null) {
      return;
    }

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: userLocation,
          zoom: 10.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Office>> officesAsync = ref.watch(officesProvider);
    final List<Office> officesForMap = officesAsync.maybeWhen(
      data: _sortOfficesByDistance,
      orElse: () => <Office>[],
    );

    final Set<Marker> markers = _buildMapMarkers(officesForMap);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: HomeScreen._defaultKenyaCamera,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _centerMapToUser();
              },
              markers: markers,
              myLocationEnabled: _userLocation != null,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  HomeSearchBar(
                    onTap: () => context.go(AppRoutes.search),
                  ),
                  const SizedBox(height: 12),
                  const FilterChipRow(),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.26,
            maxChildSize: 0.82,
            builder: (BuildContext context, ScrollController scrollController) {
              final List<Office> officesForCount = officesAsync.when(
                data: _sortOfficesByDistance,
                loading: () => <Office>[],
                error: (_, __) => <Office>[],
              );
              final int resultsCount = officesForCount.length;

              return HomeBottomSheet(
                resultsCount: resultsCount,
                child: officesAsync.when(
                  loading: () => _CenteredSheetState(
                    scrollController: scrollController,
                    child: const CircularProgressIndicator(),
                  ),
                  error: (Object error, StackTrace stackTrace) => _CenteredSheetState(
                    scrollController: scrollController,
                    child: _MessageCard(
                      icon: Icons.error_outline_rounded,
                      title: 'Unable to load offices',
                      subtitle: 'Please check your connection and try again.',
                      actionLabel: 'Retry',
                      onActionPressed: () => ref.invalidate(officesProvider),
                    ),
                  ),
                  data: (List<Office> offices) {
                    final List<Office> sortedOffices = _sortOfficesByDistance(offices);

                    if (sortedOffices.isEmpty) {
                      return _CenteredSheetState(
                        scrollController: scrollController,
                        child: const _MessageCard(
                          icon: Icons.inbox_rounded,
                          title: 'No offices available',
                          subtitle: 'IEBC offices will appear here once data is added.',
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
                      itemBuilder: (BuildContext context, int index) =>
                          OfficePreviewCard(office: sortedOffices[index]),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemCount: sortedOffices.length,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'current-location',
        onPressed: () {
          if (_userLocation != null) {
            _centerMapToUser();
            return;
          }
          _loadUserLocation();
        },
        child: Icon(
          _isLocationReady && _userLocation == null
              ? Icons.location_disabled_rounded
              : Icons.my_location_rounded,
        ),
      ),
    );
  }

  List<Office> _sortOfficesByDistance(List<Office> offices) {
    final LatLng? userLocation = _userLocation;
    if (userLocation == null) {
      return offices;
    }

    final List<Office> enriched = offices.map((Office office) {
      if (!_isValidCoordinate(office.lat, office.lng)) {
        return office;
      }

      final double distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        office.lat!,
        office.lng!,
      );

      return office.copyWith(distanceMeters: distance);
    }).toList(growable: false);

    enriched.sort((Office a, Office b) {
      final double aDistance = a.distanceMeters ?? double.infinity;
      final double bDistance = b.distanceMeters ?? double.infinity;
      return aDistance.compareTo(bDistance);
    });

    return enriched;
  }

  Set<Marker> _buildMapMarkers(List<Office> offices) {
    final Set<Marker> markers = offices
        .where((Office office) => _isValidCoordinate(office.lat, office.lng))
        .map((Office office) {
      final double lat = office.lat!;
      final double lng = office.lng!;
      final String title = office.constituency.isNotEmpty
          ? office.constituency
          : 'IEBC Office';
      final String snippet = _buildInfoSnippet(
        county: office.county,
        landmark: office.landmark,
      );

      return Marker(
        markerId: MarkerId(office.id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: title,
          snippet: snippet.isEmpty ? null : snippet,
        ),
      );
    }).toSet();

    final LatLng? userLocation = _userLocation;
    if (userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user-location'),
          position: userLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your location'),
        ),
      );
    }

    return markers;
  }

  bool _isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) {
      return false;
    }

    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  String _buildInfoSnippet({required String county, required String landmark}) {
    final List<String> parts = <String>[
      if (county.isNotEmpty) county,
      if (landmark.isNotEmpty) landmark,
    ];

    return parts.join(' • ');
  }
}

class _CenteredSheetState extends StatelessWidget {
  const _CenteredSheetState({
    required this.scrollController,
    required this.child,
  });

  final ScrollController scrollController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: <Widget>[
        const SizedBox(height: 24),
        Center(child: child),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 34, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            if (actionLabel != null && onActionPressed != null) ...<Widget>[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onActionPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
