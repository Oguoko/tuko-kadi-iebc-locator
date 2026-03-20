import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuko_kadi_iebc_locator/app/router/app_router.dart';
import 'package:tuko_kadi_iebc_locator/shared/widgets/placeholder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Tuko Kadi IEBC Locator',
      description:
          'Find your nearest IEBC constituency office, check details, and plan your visit.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: <Widget>[
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.search),
            icon: const Icon(Icons.search),
            label: const Text('Search Offices'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.savedFavorites),
            icon: const Icon(Icons.bookmark_outline),
            label: const Text('Saved'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.officeDetails),
            icon: const Icon(Icons.location_city_outlined),
            label: const Text('Office Details'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.nearbySpots),
            icon: const Icon(Icons.celebration_outlined),
            label: const Text('Nearby Spots'),
          ),
        ],
      ),
    );
  }
}
