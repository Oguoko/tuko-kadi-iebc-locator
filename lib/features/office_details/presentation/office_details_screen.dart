import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:tuko_kadi_iebc_locator/app/router/app_router.dart';
import 'package:tuko_kadi_iebc_locator/app/theme/app_theme.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/features/routing/presentation/route_page.dart';
import 'package:tuko_kadi_iebc_locator/shared/utils/distance_utils.dart';
import 'package:tuko_kadi_iebc_locator/shared/utils/office_coordinate_validator.dart';

class OfficeDetailsScreen extends StatefulWidget {
  const OfficeDetailsScreen({
    super.key,
    this.office,
  });

  final Office? office;

  @override
  State<OfficeDetailsScreen> createState() => _OfficeDetailsScreenState();
}

class _OfficeDetailsScreenState extends State<OfficeDetailsScreen> {
  double? _distanceMeters;
  bool _isLoadingMetrics = false;

  @override
  void initState() {
    super.initState();
    _distanceMeters = widget.office?.distanceMeters;
    _loadDistanceMetrics();
  }

  Future<void> _loadDistanceMetrics() async {
    final Office? office = widget.office;
    if (office == null) {
      return;
    }

    final double? officeLat = office.lat;
    final double? officeLng = office.lng;
    if (!OfficeCoordinateValidator.isValidOfficeCoordinate(officeLat, officeLng)) {
      return;
    }

    setState(() {
      _isLoadingMetrics = true;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!OfficeCoordinateValidator.hasValidWorldBounds(
        position.latitude,
        position.longitude,
      )) {
        return;
      }

      if (officeLat == null || officeLng == null) {
        return;
      }

      final double? distanceMeters = DistanceUtils.calculateDistanceMeters(
        position.latitude,
        position.longitude,
        officeLat,
        officeLng,
      );

      if (distanceMeters == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _distanceMeters = distanceMeters;
      });
    } catch (_) {
      // Keep non-blocking fallback labels in UI.
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingMetrics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Office? currentOffice = widget.office;
    if (currentOffice == null) {
      return const Scaffold(
        body: SafeArea(child: _NoOfficeSelectedState()),
      );
    }

    final bool canOpenDirections = OfficeCoordinateValidator.isValidOfficeCoordinate(
      currentOffice.lat,
      currentOffice.lng,
    );

    final String distanceLabel = DistanceUtils.formatDistanceLabel(
      _distanceMeters,
      fallback: currentOffice.estimatedDistanceText ?? 'Location unavailable',
    );
    final String etaLabel = DistanceUtils.formatEtaLabelFromDistance(
      _distanceMeters,
      fallback: 'ETA not available',
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
              _OfficeHero(
                office: currentOffice,
                distanceLabel: distanceLabel,
                etaLabel: etaLabel,
                isLoadingMetrics: _isLoadingMetrics,
              ),
              const SizedBox(height: 18),
              _PrimaryActionRow(
                office: currentOffice,
                canOpenDirections: canOpenDirections,
              ),
              const SizedBox(height: 24),
              const _FaqSection(),
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

class _OfficeHero extends StatelessWidget {
  const _OfficeHero({
    required this.office,
    required this.distanceLabel,
    required this.etaLabel,
    required this.isLoadingMetrics,
  });

  final Office office;
  final String distanceLabel;
  final String etaLabel;
  final bool isLoadingMetrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF111111), Color(0xFFE53935)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
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
            const SizedBox(height: 18),
            Text(
              office.officeLocation,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              office.landmark,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MetricTile(
                    icon: Icons.straighten_rounded,
                    title: 'Distance',
                    value: distanceLabel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.schedule_rounded,
                    title: 'ETA',
                    value: etaLabel,
                  ),
                ),
              ],
            ),
            if (isLoadingMetrics)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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
  });

  final Office office;
  final bool canOpenDirections;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: canOpenDirections
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute<RoutePage>(
                    builder: (BuildContext context) => RoutePage(office: office),
                  ),
                );
              }
            : null,
        icon: const Icon(Icons.directions_rounded),
        label: const Text('Directions'),
      ),
    );
  }
}

class _RouteStatTile extends StatelessWidget {
  const _RouteStatTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppTheme.red),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  static const List<_FaqItemData> _faqItems = <_FaqItemData>[
    _FaqItemData(
      question: 'What do I need to register as a voter?',
      answer: 'Your original national ID card or a valid Kenyan passport.',
    ),
    _FaqItemData(
      question: 'Do I need my acknowledgement slip to vote later?',
      answer:
          'No. IEBC says the acknowledgement slip is issued after registration, but it is not a requirement for voting.',
    ),
    _FaqItemData(
      question: 'Can I register more than once?',
      answer: 'No. A person is only allowed to register once.',
    ),
    _FaqItemData(
      question: 'Can I transfer my registration centre later?',
      answer: 'Yes. A voter may transfer to another registration centre during the registration period.',
    ),
    _FaqItemData(
      question: 'Why should I register?',
      answer:
          'Registration allows you to vote, vie for office, nominate candidates, and hold leaders accountable.',
    ),
    _FaqItemData(
      question: 'When can someone be denied registration?',
      answer:
          'A person may be denied if they are under 18, do not have the original ID/passport, are an undischarged bankrupt, have certain election-offence findings in the last five years, or are declared of unsound mind by a competent court.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
        children: <Widget>[
          const _SectionTitle(title: 'Registration FAQ', icon: Icons.quiz_rounded),
          const SizedBox(height: 10),
          Text(
            'Quick guidance from IEBC voter registration information.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          for (final _FaqItemData item in _faqItems)
            _FaqItem(question: item.question, answer: item.answer),
        ],
      ),
    );
  }
}

class _FaqItemData {
  const _FaqItemData({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        collapsedShape: const Border(),
        shape: const Border(),
        iconColor: AppTheme.red,
        collapsedIconColor: AppTheme.red,
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w800)),
        children: <Widget>[
          Text(
            answer,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.3),
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
