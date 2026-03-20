import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuko_kadi_iebc_locator/app/router/app_router.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/models/office_preview.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/widgets/filter_chip_row.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/widgets/home_bottom_sheet.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/widgets/home_search_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<OfficePreview> _mockOffices = <OfficePreview>[
    OfficePreview(
      constituency: 'Westlands Constituency Office',
      county: 'Nairobi County',
      landmark: 'Near Safaricom Centre',
      eta: '8 min away',
    ),
    OfficePreview(
      constituency: 'Kibra Constituency Office',
      county: 'Nairobi County',
      landmark: 'Adjacent to Huduma Centre',
      eta: '12 min away',
    ),
    OfficePreview(
      constituency: 'Lang\'ata Constituency Office',
      county: 'Nairobi County',
      landmark: 'Near Five Star Road',
      eta: '15 min away',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    colors.primaryContainer.withValues(alpha: 0.45),
                    colors.tertiaryContainer.withValues(alpha: 0.2),
                    colors.surface,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 168, 16, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.map_rounded,
                        size: 52,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Map View',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Live map integration drops in here.\nShowing nearby constituency offices around you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  HomeSearchBar(
                    onTap: () => context.go(AppRoutes.search),
                  ),
                  const SizedBox(height: 12),
                  const FilterChipRow(),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.26,
            maxChildSize: 0.82,
            builder: (BuildContext context, ScrollController scrollController) {
              return HomeBottomSheet(
                offices: _mockOffices,
                scrollController: scrollController,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'current-location',
        onPressed: () => context.go(AppRoutes.search),
        child: const Icon(Icons.my_location_rounded),
      ),
    );
  }
}
