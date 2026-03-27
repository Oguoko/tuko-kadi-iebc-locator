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
import 'package:tuko_kadi_iebc_locator/shared/utils/distance_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const CameraPosition _defaultNairobiCamera = CameraPosition(
    target: LatLng(-1.286389, 36.817223),
    zoom: 10.5,
  );

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  bool _isLocationReady = false;
  bool _isLocating = false;
  bool _hasShownLocationMessage = false;
  String? _selectedOfficeId;
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _onLocationButtonPressed() async {
    if (_isLocating) {
      return;
    }

    final LatLng? existingLocation = _userLocation;
    if (existingLocation != null) {
      _centerMapToUser();
      return;
    }

    await _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    if (_isLocating) {
      return;
    }

    setState(() {
      _isLocating = true;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLocationReady = true;
        });
        _showSoftLocationMessage(
          'Location services are off. Showing offices in default order.',
        );
        _centerMapToDefault();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLocationReady = true;
        });
        _showSoftLocationMessage(
          'Location permission denied. Showing offices in default order.',
        );
        _centerMapToDefault();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLocationReady = true;
        });
        _showSoftLocationMessage(
          'Location permission is permanently denied. Showing offices in default order.',
        );
        _centerMapToDefault();
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
      _showSoftLocationMessage(
        'Could not get your location right now. Showing default office order.',
      );
      _centerMapToDefault();
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLocating = false;
      });
    }
  }

  void _showSoftLocationMessage(String message) {
    if (_hasShownLocationMessage || !mounted) {
      return;
    }

    _hasShownLocationMessage = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  void _centerMapToUser() {
    final LatLng? userLocation = _userLocation;

    if (userLocation == null) {
      return;
    }

    _updateCamera(
      target: userLocation,
      zoom: 12.5,
    );
  }

  void _centerMapToDefault() {
    _updateCamera(
      target: HomeScreen._defaultNairobiCamera.target,
      zoom: HomeScreen._defaultNairobiCamera.zoom,
    );
  }

  void _updateCamera({
    required LatLng target,
    required double zoom,
  }) {
    final GoogleMapController? controller = _mapController;
    if (controller == null) {
      return;
    }

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
        ),
      ),
    );
  }

  void _setSelectedOffice(Office office) {
    setState(() {
      _selectedOfficeId = office.id;
    });
    _moveCameraToOffice(office);
  }

  void _handleMarkerTap(Office office) {
    _setSelectedOffice(office);
    _openOfficeDetails(office);
  }

  void _handleCardTap(Office office) {
    _setSelectedOffice(office);
    _openOfficeDetails(office);
  }

  void _openOfficeDetails(Office office) {
    context.push(
      AppRoutes.officeDetails,
      extra: office,
    );
  }

  void _moveCameraToOffice(Office office) {
    if (!_isValidCoordinate(office.lat, office.lng)) {
      return;
    }

    _updateCamera(
      target: LatLng(office.lat!, office.lng!),
      zoom: 13,
    );
  }

  void _handleSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    if (_searchQuery.isEmpty) {
      return;
    }

    setState(() {
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Office>> officesAsync = ref.watch(officesProvider);
    final List<Office> sortedOffices = officesAsync.maybeWhen(
      data: _sortOfficesByDistance,
      orElse: () => <Office>[],
    );
    final List<Office> filteredOffices = _filterOfficesBySearch(sortedOffices);

    final Set<Marker> markers = _buildMapMarkers(filteredOffices);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: HomeScreen._defaultNairobiCamera,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                if (_userLocation != null) {
                  _centerMapToUser();
                  return;
                }
                _centerMapToDefault();
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
                    controller: _searchController,
                    onChanged: _handleSearchChanged,
                    onClear: _clearSearch,
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
              final int resultsCount = filteredOffices.length;

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
                    final List<Office> filteredOffices = _filterOfficesBySearch(sortedOffices);

                    if (filteredOffices.isEmpty) {
                      return _CenteredSheetState(
                        scrollController: scrollController,
                        child: _MessageCard(
                          icon: Icons.inbox_rounded,
                          title: _searchQuery.isEmpty
                              ? 'No offices available'
                              : 'No offices match your search',
                          subtitle: _searchQuery.isEmpty
                              ? 'IEBC offices will appear here once data is added.'
                              : 'Try another county, constituency, office location, or landmark.',
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
                      itemBuilder: (BuildContext context, int index) {
                        final Office office = filteredOffices[index];
                        return OfficePreviewCard(
                          office: office,
                          isSelected: office.id == _selectedOfficeId,
                          onTap: () => _handleCardTap(office),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemCount: filteredOffices.length,
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
        onPressed: _onLocationButtonPressed,
        child: _isLocating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Icon(
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
      return List<Office>.from(offices, growable: false);
    }

    final List<Office> enriched = offices.map((Office office) {
      if (!_isValidCoordinate(office.lat, office.lng)) {
        return office;
      }

      final double distance = DistanceUtils.calculateDistanceMeters(
        startLatitude: userLocation.latitude,
        startLongitude: userLocation.longitude,
        endLatitude: office.lat!,
        endLongitude: office.lng!,
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

  List<Office> _filterOfficesBySearch(List<Office> offices) {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return offices;
    }

    return offices.where((Office office) {
      return _matchesSearch(office.constituency, query) ||
          _matchesSearch(office.county, query) ||
          _matchesSearch(office.officeLocation, query) ||
          _matchesSearch(office.landmark, query);
    }).toList(growable: false);
  }

  bool _matchesSearch(String value, String query) {
    if (value.isEmpty) {
      return false;
    }

    return value.toLowerCase().contains(query);
  }

  Set<Marker> _buildMapMarkers(List<Office> offices) {
    final Set<Marker> markers = <Marker>{};
    for (final Office office in offices) {
      final double? lat = office.lat;
      final double? lng = office.lng;
      if (!_isValidCoordinate(lat, lng)) {
        continue;
      }

      final String title = office.constituency.isNotEmpty
          ? office.constituency
          : 'IEBC Office';
      final String snippet = _buildInfoSnippet(
        county: office.county,
        landmark: office.landmark,
      );

      markers.add(
        Marker(
          markerId: MarkerId(office.id),
          position: LatLng(lat, lng),
          icon: office.id == _selectedOfficeId
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: title,
            snippet: snippet.isEmpty ? null : snippet,
          ),
          onTap: () => _handleMarkerTap(office),
        ),
      );
    }

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
