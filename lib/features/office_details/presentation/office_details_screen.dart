import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuko_kadi_iebc_locator/app/router/app_router.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/shared/utils/distance_utils.dart';
import 'package:tuko_kadi_iebc_locator/shared/utils/google_maps_directions.dart';

class OfficeDetailsScreen extends StatelessWidget {
  const OfficeDetailsScreen({super.key, this.office});

  final Office? office;

  @override
  Widget build(BuildContext context) {
    final Office? currentOffice = office;
    final bool hasOffice = currentOffice != null;
    final bool canOpenDirections = GoogleMapsDirections.hasValidCoordinates(
      currentOffice?.lat,
      currentOffice?.lng,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Office Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: hasOffice
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      currentOffice.constituency,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      children: <Widget>[
                        _DetailRow(
                          label: 'Constituency',
                          value: currentOffice.constituency,
                        ),
                        _DetailRow(label: 'County', value: currentOffice.county),
                        _DetailRow(
                          label: 'Office location',
                          value: currentOffice.officeLocation,
                        ),
                        _DetailRow(label: 'Landmark', value: currentOffice.landmark),
                        _DetailRow(
                          label: 'Estimated distance',
                          value: currentOffice.estimatedDistanceText,
                          fallback: 'Not provided',
                        ),
                        _DetailRow(
                          label: 'Current distance',
                          value: DistanceUtils.formatDistanceLabel(
                            currentOffice.distanceMeters,
                            fallback: 'Not available (turn on location)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: canOpenDirections
                                ? () async {
                                    final bool launched = await GoogleMapsDirections.openDirections(
                                      lat: currentOffice.lat!,
                                      lng: currentOffice.lng!,
                                    );

                                    if (!launched && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Unable to open Google Maps directions.'),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.directions_rounded, size: 18),
                            label: const Text('Directions'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.go(
                              AppRoutes.nearbySpots,
                              extra: currentOffice,
                            ),
                            icon: const Icon(Icons.local_activity_rounded, size: 18),
                            label: const Text('Nearby Spots'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share location will be added soon.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_location_rounded, size: 18),
                        label: const Text('Share Location'),
                      ),
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
                  ],
                )
              : const _NoOfficeSelectedState(),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    this.value,
    this.fallback = 'Not available',
  });

  final String label;
  final String? value;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final String resolvedValue = (value != null && value!.trim().isNotEmpty)
        ? value!.trim()
        : fallback;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              resolvedValue,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoOfficeSelectedState extends StatelessWidget {
  const _NoOfficeSelectedState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.info_outline_rounded, size: 34, color: colors.primary),
              const SizedBox(height: 12),
              Text(
                'No office selected',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
    );
  }
}
