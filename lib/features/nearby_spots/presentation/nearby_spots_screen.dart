import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuko_kadi_iebc_locator/app/router/app_router.dart';
import 'package:tuko_kadi_iebc_locator/app/theme/app_theme.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/features/nearby_spots/data/services/google_places_service.dart';
import 'package:tuko_kadi_iebc_locator/features/nearby_spots/domain/entities/nearby_spot.dart';
import 'package:tuko_kadi_iebc_locator/shared/services/directions_service.dart';

class NearbySpotsScreen extends StatefulWidget {
  const NearbySpotsScreen({super.key, this.office});

  final Office? office;

  @override
  State<NearbySpotsScreen> createState() => _NearbySpotsScreenState();
}

class _NearbySpotsScreenState extends State<NearbySpotsScreen> {
  late final GooglePlacesService _placesService;
  final DirectionsService _directionsService = const DirectionsService();
  late NearbySpotCategory _selectedCategory;
  Future<List<NearbySpot>>? _nearbySpotsFuture;

  @override
  void initState() {
    super.initState();
    _placesService = GooglePlacesService();
    _selectedCategory = NearbySpotCategory.eateries;
    _nearbySpotsFuture = _loadNearbySpots();
  }

  Future<List<NearbySpot>> _loadNearbySpots() {
    final Office? office = widget.office;
    if (office == null || office.lat == null || office.lng == null) {
      return Future<List<NearbySpot>>.value(<NearbySpot>[]);
    }

    return _placesService.fetchNearbySpots(
      latitude: office.lat!,
      longitude: office.lng!,
      category: _selectedCategory,
    );
  }

  void _setCategory(NearbySpotCategory category) {
    if (_selectedCategory == category) {
      return;
    }

    setState(() {
      _selectedCategory = category;
      _nearbySpotsFuture = _loadNearbySpots();
    });
  }

  void _retry() {
    setState(() {
      _nearbySpotsFuture = _loadNearbySpots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Office? office = widget.office;
    final bool hasCoordinates = office?.lat != null && office?.lng != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Nearby Spots',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.red,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppTheme.red.withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SpotsHero(
                office: office,
                selectedCategory: _selectedCategory,
                enabled: hasCoordinates,
                onCategorySelected: _setCategory,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: !hasCoordinates
                    ? const _InfoState(
                        icon: Icons.location_off_rounded,
                        title: 'Nearby spots unavailable',
                        subtitle: 'Select an office with valid coordinates to view nearby spots.',
                      )
                    : FutureBuilder<List<NearbySpot>>(
                        future: _nearbySpotsFuture,
                        builder: (BuildContext context, AsyncSnapshot<List<NearbySpot>> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return _InfoState(
                              icon: Icons.error_outline_rounded,
                              title: 'Failed to load nearby spots',
                              subtitle: '${snapshot.error}',
                              actionLabel: 'Retry',
                              onActionPressed: _retry,
                            );
                          }

                          final List<NearbySpot> spots = snapshot.data ?? <NearbySpot>[];
                          if (spots.isEmpty) {
                            return _InfoState(
                              icon: Icons.explore_off_rounded,
                              title: 'No ${_selectedCategory.label.toLowerCase()} found nearby',
                              subtitle: 'Try a different category or select another office.',
                              actionLabel: 'Refresh',
                              onActionPressed: _retry,
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: spots.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 14),
                            itemBuilder: (BuildContext context, int index) {
                              final NearbySpot spot = spots[index];
                              return _NearbySpotCard(
                                spot: spot,
                                imageUrl: _placesService.buildPhotoUrl(spot.photoReference),
                                onOpenMap: () async {
                                  final DirectionsResult result = await _directionsService.openDirections(
                                    lat: spot.latitude,
                                    lng: spot.longitude,
                                  );

                                  if (!result.isSuccess && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Unable to open map directions for this spot.')),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _StandaloneBottomNav(activeIndex: 0),
    );
  }
}

class _SpotsHero extends StatelessWidget {
  const _SpotsHero({
    required this.office,
    required this.selectedCategory,
    required this.enabled,
    required this.onCategorySelected,
  });

  final Office? office;
  final NearbySpotCategory selectedCategory;
  final bool enabled;
  final ValueChanged<NearbySpotCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFE53935), Color(0xFF111111)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Street-side Picks',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        office == null
                            ? 'Select an office to explore places nearby.'
                            : '${office!.constituency} • ${office!.county}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 90,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          Image.asset('assets/branding/logo.png', fit: BoxFit.cover),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.56),
                            ),
                          ),
                          const Center(
                            child: Icon(Icons.place_rounded, color: Colors.white, size: 34),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: NearbySpotCategory.values
                    .map(
                      (NearbySpotCategory category) => ChoiceChip(
                        label: Text(category.label),
                        selected: selectedCategory == category,
                        onSelected: enabled ? (_) => onCategorySelected(category) : null,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbySpotCard extends StatelessWidget {
  const _NearbySpotCard({
    required this.spot,
    required this.imageUrl,
    required this.onOpenMap,
  });

  final NearbySpot spot;
  final String? imageUrl;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: imageUrl == null
                        ? Container(
                            color: const Color(0xFFF0F0F0),
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported_rounded),
                          )
                        : Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: const Color(0xFFF0F0F0),
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        spot.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${spot.primaryType} • ${spot.distanceLabel}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.red.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '⭐ ${spot.ratingLabel}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenMap,
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('Open in Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoState extends StatelessWidget {
  const _InfoState({
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null && onActionPressed != null) ...<Widget>[
              const SizedBox(height: 16),
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
