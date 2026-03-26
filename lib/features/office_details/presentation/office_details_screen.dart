import 'package:flutter/material.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/shared/utils/google_maps_directions.dart';

class OfficeDetailsScreen extends StatelessWidget {
  const OfficeDetailsScreen({super.key, this.office});

  final Office? office;

  @override
  Widget build(BuildContext context) {
    final Office? currentOffice = office;
    final bool canOpenDirections = GoogleMapsDirections.hasValidCoordinates(
      currentOffice?.lat,
      currentOffice?.lng,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Office Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              currentOffice?.constituency ?? 'Office details unavailable',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(currentOffice?.county ?? ''),
            const SizedBox(height: 12),
            Text(
              currentOffice == null
                  ? 'Select an office from the home screen to view its details.'
                  : '${currentOffice.officeLocation} • ${currentOffice.landmark}',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canOpenDirections
                    ? () async {
                        final bool launched = await GoogleMapsDirections.openDirections(
                          lat: currentOffice!.lat!,
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
                icon: const Icon(Icons.directions_rounded),
                label: const Text('Directions'),
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
        ),
      ),
    );
  }
}
