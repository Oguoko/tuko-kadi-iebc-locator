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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'IEBC Locator',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.red,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFFE53935), Color(0xFF1A1A1A)],
                ),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.18,
                      child: Image.asset('assets/branding/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Nearby Vibes', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(
                          office == null ? 'Select an office to explore places nearby.' : '${office.constituency} • ${office.county}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 8,
                          children: NearbySpotCategory.values
                              .map(
                                (NearbySpotCategory category) => ChoiceChip(
                                  label: Text(category.label),
                                  selected: _selectedCategory == category,
                                  onSelected: hasCoordinates ? (_) => _setCategory(category) : null,
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
                            itemCount: spots.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 86,
                height: 86,
                child: imageUrl == null
                    ? Container(
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_rounded),
                      )
                    : Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.black12,
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
                  Text(spot.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${spot.primaryType} • ${spot.distanceLabel}'),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('⭐ ${spot.ratingLabel}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: onOpenMap,
                        icon: const Icon(Icons.directions_rounded, size: 16),
                        label: const Text('Open in Maps'),
                      ),
                    ],
                  ),
                ],
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
