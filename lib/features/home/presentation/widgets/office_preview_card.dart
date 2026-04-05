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
    final bool canOpenDirections = directionsService.hasValidDestination(
      office.lat,
      office.lng,
    );

    final Color cardColor = isSelected ? colors.primaryContainer : colors.surface;
    final Color borderColor = isSelected ? colors.primary : colors.outlineVariant;

    final Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Card(
        margin: EdgeInsets.zero,
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: borderColor,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: colors.outlineVariant),
                              ),
                              child: Image.asset(
                                'assets/branding/icon.png',
                                width: 14,
                                height: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                office.constituency,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          office.county,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        child: Text(
                          office.distanceLabel,
                          style: TextStyle(
                            color: colors.onSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        office.etaLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
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
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: canOpenDirections
                          ? () {
                              context.push(
                                AppRoutes.officeDetails,
                                extra: office,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text('Directions'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Open in Google Maps',
                    child: OutlinedButton(
                      onPressed: canOpenDirections
                          ? () async {
                              final DirectionsResult result =
                                  await directionsService.openDirections(
                                lat: office.lat,
                                lng: office.lng,
                                flow: DirectionsFlow.externalGoogleMaps,
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
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      child: const Icon(Icons.open_in_new_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(
                        AppRoutes.nearbySpots,
                        extra: office,
                      ),
                      icon: const Icon(Icons.local_activity_rounded, size: 17),
                      label: const Text('Nearby'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.secondary, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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
        borderRadius: BorderRadius.circular(10),
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
