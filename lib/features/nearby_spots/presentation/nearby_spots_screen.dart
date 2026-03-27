import 'package:flutter/material.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/features/nearby_spots/data/services/google_places_service.dart';
import 'package:tuko_kadi_iebc_locator/features/nearby_spots/domain/entities/nearby_spot.dart';

class NearbySpotsScreen extends StatefulWidget {
  const NearbySpotsScreen({super.key, this.office});

  final Office? office;

  @override
  State<NearbySpotsScreen> createState() => _NearbySpotsScreenState();
}

class _NearbySpotsScreenState extends State<NearbySpotsScreen> {
  late final GooglePlacesService _placesService;
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
      appBar: AppBar(title: const Text('Nearby Spots')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
            const SizedBox(height: 16),
            Expanded(
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
                            return _NearbySpotCard(spot: spot);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbySpotCard extends StatelessWidget {
  const _NearbySpotCard({required this.spot});

  final NearbySpot spot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              spot.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text('Type: ${spot.primaryType}'),
            const SizedBox(height: 4),
            Text('Rating: ${spot.ratingLabel}'),
            const SizedBox(height: 4),
            Text('Distance: ${spot.distanceLabel}'),
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
                    fontWeight: FontWeight.w700,
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
