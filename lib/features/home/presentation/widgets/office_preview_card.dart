import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuko_kadi_iebc_locator/app/router/app_router.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/shared/services/directions_service.dart';

class OfficePreviewCard extends StatelessWidget {
  const OfficePreviewCard({
    super.key,
    required this.office,
    this.isSelected = false,
    this.onTap,
    this.directionsService = const DirectionsService(),
  });

  final Office office;
  final bool isSelected;
  final VoidCallback? onTap;
  final DirectionsService directionsService;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color selectedBorderColor = colors.primary;
    final Color selectedCardColor = colors.primaryContainer.withValues(alpha: 0.3);
    final bool canOpenDirections = directionsService.hasValidDestination(
      office.lat,
      office.lng,
    );

    final Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Card(
        margin: EdgeInsets.zero,
        color: isSelected ? selectedCardColor : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? selectedBorderColor : colors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          office.constituency,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          office.county,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      office.distanceLabel,
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(Icons.place_rounded, color: colors.primary, size: 17),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${office.officeLocation} • ${office.landmark}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.3,
                          ),
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
                              final DirectionsResult result =
                                  await directionsService.openDirections(
                                lat: office.lat,
                                lng: office.lng,
                              );

                              if (!result.isSuccess && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _directionsErrorMessage(result.failure),
                                    ),
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
                        extra: office,
                      ),
                      icon: const Icon(Icons.local_activity_rounded, size: 18),
                      label: const Text('Nearby Spots'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: cardContent,
      ),
    );
  }

  String _directionsErrorMessage(DirectionsFailure? failure) {
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
}
