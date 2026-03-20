import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuko_kadi_iebc_locator/app/router/app_router.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';

class OfficePreviewCard extends StatelessWidget {
  const OfficePreviewCard({
    super.key,
    required this.office,
  });

  final Office office;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    office.constituency,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              office.county,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Icon(Icons.place_rounded, color: colors.primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${office.officeLocation} · ${office.landmark}',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.officeDetails),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text('Directions'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.nearbySpots),
                    icon: const Icon(Icons.local_activity_rounded, size: 18),
                    label: const Text('Nearby Spots'),
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
