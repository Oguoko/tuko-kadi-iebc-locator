import 'package:flutter/foundation.dart';
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
import 'package:tuko_kadi_iebc_locator/shared/utils/office_coordinate_validator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const CameraPosition _defaultNairobiCamera = CameraPosition(
    target: LatLng(-1.286389, 36.817223),
    zoom: 10.5,
  );

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

enum _LocationIssue {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  bool _isLocationReady = false;
  bool _isLocating = false;
  String? _selectedOfficeId;
  final Set<String> _invalidMarkerLogIds = <String>{};
  late final TextEditingController _searchController;
  String _searchQuery = '';
  _LocationIssue? _locationIssue;

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
      _locationIssue = null;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLocationReady = true;
          _locationIssue = _LocationIssue.serviceDisabled;
        });
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
          _locationIssue = _LocationIssue.permissionDenied;
        });
        _centerMapToDefault();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLocationReady = true;
          _locationIssue = _LocationIssue.permissionDeniedForever;
        });
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
        _locationIssue = _LocationIssue.unavailable;
      });
      _centerMapToDefault();
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
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
    if (!OfficeCoordinateValidator.isValidOfficeCoordinate(office.lat, office.lng)) {
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

  _LocationCopy _locationCopyForIssue(_LocationIssue issue) {
    switch (issue) {
      case _LocationIssue.serviceDisabled:
        return const _LocationCopy(
          title: 'Location is turned off',
          subtitle: 'Enable device location to sort offices nearest to you.',
          action: 'Try again',
        );
      case _LocationIssue.permissionDenied:
        return const _LocationCopy(
          title: 'Location permission denied',
          subtitle: 'Allow location access so we can show the closest offices first.',
          action: 'Retry permission',
        );
      case _LocationIssue.permissionDeniedForever:
        return const _LocationCopy(
          title: 'Location access blocked',
          subtitle: 'Location permission is permanently denied. Open settings, then retry.',
          action: 'Retry',
        );
      case _LocationIssue.unavailable:
        return const _LocationCopy(
          title: 'Could not fetch your location',
          subtitle: 'We are showing all offices for now. You can retry anytime.',
          action: 'Try again',
        );
    }
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
    final bool mapBusy = officesAsync.isLoading || (_isLocating && !_isLocationReady);

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
          IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: mapBusy ? 1 : 0,
              child: const _MapLoadingOverlay(),
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _locationIssue == null
                        ? const SizedBox.shrink()
                        : Padding(
                            key: ValueKey<_LocationIssue>(_locationIssue!),
                            padding: const EdgeInsets.only(top: 12),
                            child: _LocationIssueBanner(
                              copy: _locationCopyForIssue(_locationIssue!),
                              isRetrying: _isLocating,
                              onRetry: _loadUserLocation,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.28,
            maxChildSize: 0.84,
            builder: (BuildContext context, ScrollController scrollController) {
              final int resultsCount = filteredOffices.length;

              return HomeBottomSheet(
                resultsCount: resultsCount,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: officesAsync.when(
                    loading: () => _CardsLoadingState(
                      key: const ValueKey<String>('loading'),
                      scrollController: scrollController,
                    ),
                    error: (Object error, StackTrace stackTrace) => _CenteredSheetState(
                      key: const ValueKey<String>('error'),
                      scrollController: scrollController,
                      child: _MessageCard(
                        icon: Icons.cloud_off_rounded,
                        title: 'We couldn\'t load offices right now',
                        subtitle:
                            'Check your internet connection and refresh to continue.',
                        actionLabel: 'Retry',
                        onActionPressed: () => ref.invalidate(officesProvider),
                      ),
                    ),
                    data: (List<Office> offices) {
                      final List<Office> sortedOffices = _sortOfficesByDistance(offices);
                      final List<Office> filteredOffices =
                          _filterOfficesBySearch(sortedOffices);

                      if (filteredOffices.isEmpty) {
                        return _CenteredSheetState(
                          key: const ValueKey<String>('empty'),
                          scrollController: scrollController,
                          child: _MessageCard(
                            icon: _searchQuery.isEmpty
                                ? Icons.location_city_rounded
                                : Icons.search_off_rounded,
                            title: _searchQuery.isEmpty
                                ? 'No offices available yet'
                                : 'No matches for "$_searchQuery"',
                            subtitle: _searchQuery.isEmpty
                                ? 'Office listings will appear here once data sync completes.'
                                : 'Try a county, constituency, office location, or nearby landmark.',
                            actionLabel:
                                _searchQuery.isEmpty ? null : 'Clear search filters',
                            onActionPressed: _searchQuery.isEmpty ? null : _clearSearch,
                          ),
                        );
                      }

                      return ListView.separated(
                        key: const ValueKey<String>('data'),
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
                        itemBuilder: (BuildContext context, int index) {
                          final Office office = filteredOffices[index];
                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 180 + (index * 26)),
                            curve: Curves.easeOut,
                            tween: Tween<double>(begin: 0.94, end: 1),
                            builder: (BuildContext context, double value, Widget? child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 16),
                                  child: child,
                                ),
                              );
                            },
                            child: OfficePreviewCard(
                              office: office,
                              isSelected: office.id == _selectedOfficeId,
                              onTap: () => _handleCardTap(office),
                            ),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemCount: filteredOffices.length,
                      );
                    },
                  ),
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
      if (!OfficeCoordinateValidator.isValidOfficeCoordinate(office.lat, office.lng)) {
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
      if (!OfficeCoordinateValidator.isValidOfficeCoordinate(lat, lng)) {
        _logInvalidOfficeCoordinates(office);
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

  void _logInvalidOfficeCoordinates(Office office) {
    if (!kDebugMode || _invalidMarkerLogIds.contains(office.id)) {
      return;
    }

    _invalidMarkerLogIds.add(office.id);
    debugPrint(
      'Skipping office marker due to invalid Kenya coordinates '
      '[id=${office.id}, constituency=${office.constituency}, lat=${office.lat}, lng=${office.lng}]',
    );
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
    super.key,
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
        const SizedBox(height: 16),
        Center(child: child),
      ],
    );
  }
}

class _CardsLoadingState extends StatelessWidget {
  const _CardsLoadingState({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
      itemBuilder: (_, __) => const _OfficeCardSkeleton(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: 4,
    );
  }
}

class _MapLoadingOverlay extends StatelessWidget {
  const _MapLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            colors.surface.withValues(alpha: 0.42),
            colors.surface.withValues(alpha: 0.1),
            colors.surface.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Loading map and nearby offices…',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfficeCardSkeleton extends StatelessWidget {
  const _OfficeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _SkeletonLine(
                    widthFactor: 0.68,
                    color: colors.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(width: 12),
                _SkeletonBox(
                  width: 72,
                  height: 26,
                  color: colors.surfaceContainerHigh,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SkeletonLine(widthFactor: 0.52, color: colors.surfaceContainerHighest),
            const SizedBox(height: 12),
            _SkeletonLine(widthFactor: 0.82, color: colors.surfaceContainerHighest),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _SkeletonBox(
                    width: double.infinity,
                    height: 38,
                    color: colors.surfaceContainerHigh,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SkeletonBox(
                    width: double.infinity,
                    height: 38,
                    color: colors.surfaceContainerHigh,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.widthFactor,
    required this.color,
  });

  final double widthFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: _SkeletonBox(width: double.infinity, height: 14, color: color),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(width: width, height: height),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            if (actionLabel != null && onActionPressed != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationIssueBanner extends StatelessWidget {
  const _LocationIssueBanner({
    required this.copy,
    required this.isRetrying,
    required this.onRetry,
  });

  final _LocationCopy copy;
  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: <Widget>[
            Icon(Icons.location_off_rounded, color: colors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    copy.title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    copy.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: isRetrying ? null : onRetry,
              child: isRetrying
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(copy.action),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCopy {
  const _LocationCopy({
    required this.title,
    required this.subtitle,
    required this.action,
  });

  final String title;
  final String subtitle;
  final String action;
}
