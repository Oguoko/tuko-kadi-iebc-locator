import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tuko_kadi_iebc_locator/app/router/app_router.dart';
import 'package:tuko_kadi_iebc_locator/app/theme/app_theme.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/shared/services/directions_service.dart';
import 'package:tuko_kadi_iebc_locator/shared/utils/distance_utils.dart';

class OfficeDetailsScreen extends StatelessWidget {
  const OfficeDetailsScreen({
    super.key,
    this.office,
    this.directionsService = const DirectionsService(),
  });

  final Office? office;
  final DirectionsService directionsService;

  @override
  Widget build(BuildContext context) {
    final Office? currentOffice = office;
    if (currentOffice == null) {
      return const Scaffold(
        body: SafeArea(child: _NoOfficeSelectedState()),
      );
    }

    final bool canOpenDirections = directionsService.hasValidDestination(
      currentOffice.lat,
      currentOffice.lng,
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _TopHeader(office: currentOffice),
              const SizedBox(height: 18),
              _EditorialHero(office: currentOffice),
              const SizedBox(height: 18),
              _PrimaryActionRow(
                office: currentOffice,
                canOpenDirections: canOpenDirections,
                directionsService: directionsService,
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
              const SizedBox(height: 24),
              const _WhatToCarrySection(),
              const SizedBox(height: 24),
              _NearbySpotsPreview(office: currentOffice),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _StandaloneBottomNav(activeIndex: 0),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.office});

  final Office office;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                office.constituency,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                office.county,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.red,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.red.withValues(alpha: 0.34),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _EditorialHero extends StatelessWidget {
  const _EditorialHero({required this.office});

  final Office office;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            _MapHero(office: office),
            const SizedBox(height: 12),
            _HeroMetaPanel(office: office),
          ],
        ),
      ),
    );
  }
}

class _MapHero extends StatelessWidget {
  const _MapHero({required this.office});

  final Office office;

  @override
  Widget build(BuildContext context) {
    final bool hasCoordinates = office.lat != null && office.lng != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 244,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: hasCoordinates
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(office.lat!, office.lng!),
                        zoom: 14.4,
                      ),
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      markers: <Marker>{
                        Marker(
                          markerId: MarkerId(office.id),
                          position: LatLng(office.lat!, office.lng!),
                          infoWindow: InfoWindow(title: office.constituency),
                        ),
                      },
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[Color(0xFF111111), Color(0xFFE53935)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.map_outlined, color: Colors.white, size: 46),
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.68),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Official IEBC Desk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    office.officeLocation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DistanceUtils.formatDistanceLabel(
                      office.distanceMeters,
                      fallback: office.estimatedDistanceText ?? 'Distance unavailable',
                    ),
                    style: const TextStyle(color: Colors.white70),
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

class _HeroMetaPanel extends StatelessWidget {
  const _HeroMetaPanel({required this.office});

  final Office office;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _MetaStat(
                  title: 'Constituency Office',
                  value: office.constituency,
                  icon: Icons.account_balance_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetaStat(
                  title: 'County',
                  value: office.county,
                  icon: Icons.map_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaStat extends StatelessWidget {
  const _MetaStat({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.red.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: AppTheme.red, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionRow extends StatelessWidget {
  const _PrimaryActionRow({
    required this.office,
    required this.canOpenDirections,
    required this.directionsService,
  });

  final Office office;
  final bool canOpenDirections;
  final DirectionsService directionsService;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: canOpenDirections
                ? () async {
                    final DirectionsResult result = await directionsService.openDirections(
                      lat: office.lat,
                      lng: office.lng,
                    );

                    if (!result.isSuccess && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_directionsErrorMessage(result.failure))),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.map_rounded),
            label: const Text('Get Directions'),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Call Office will be enabled soon.')),
                  );
                },
                icon: const Icon(Icons.call_rounded),
                label: const Text('Call Office'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share location will be added soon.')),
                  );
                },
                icon: const Icon(Icons.share_location_rounded),
                label: const Text('Share Location'),
              ),
            ),
          ],
        ),
      ],
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

class _WhatToCarrySection extends StatelessWidget {
  const _WhatToCarrySection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          _SectionTitle(title: 'What to Carry', icon: Icons.fact_check_rounded),
          SizedBox(height: 10),
          Text(
            'Prepare these essentials before heading to the office.',
            style: TextStyle(color: Color(0xFF6B6B6B), height: 1.3),
          ),
          SizedBox(height: 12),
          _CarryItem(
            icon: Icons.badge_rounded,
            title: 'National ID Card',
            subtitle: 'Bring original national ID for verification',
          ),
          _CarryItem(
            icon: Icons.description_outlined,
            title: 'Proof of Residence',
            subtitle: 'Utility bill or local address confirmation',
          ),
          _CarryItem(
            icon: Icons.edit_note_rounded,
            title: 'Personal Pen',
            subtitle: 'Recommended for quick form filling',
          ),
        ],
      ),
    );
  }
}

class _CarryItem extends StatelessWidget {
  const _CarryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.red.withValues(alpha: 0.13),
            child: Icon(icon, color: AppTheme.red, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbySpotsPreview extends StatelessWidget {
  const _NearbySpotsPreview({required this.office});

  final Office office;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const _SectionTitle(title: 'Nearby Spots', icon: Icons.local_fire_department_rounded),
            TextButton(
              onPressed: () => context.push(AppRoutes.nearbySpots, extra: office),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 182,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              _PreviewSpotCard(
                title: 'Local Eateries',
                subtitle: 'Food • 2-8 min walk',
                icon: Icons.restaurant_rounded,
              ),
              _PreviewSpotCard(
                title: 'Coffee Stops',
                subtitle: 'Cafés • good Wi‑Fi',
                icon: Icons.local_cafe_rounded,
              ),
              _PreviewSpotCard(
                title: 'Chill Spots',
                subtitle: 'Parks • unwind nearby',
                icon: Icons.park_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewSpotCard extends StatelessWidget {
  const _PreviewSpotCard({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF101010), Color(0xFFE53935)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18, color: AppTheme.red),
        const SizedBox(width: 6),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
      ],
    );
  }
}

class _NoOfficeSelectedState extends StatelessWidget {
  const _NoOfficeSelectedState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.info_outline_rounded, size: 34, color: colors.primary),
                const SizedBox(height: 12),
                Text(
                  'No office selected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
