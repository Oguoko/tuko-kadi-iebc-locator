import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuko_kadi_iebc_locator/app/router/app_router.dart';
import 'package:tuko_kadi_iebc_locator/features/home/application/offices_provider.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/widgets/filter_chip_row.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/widgets/home_bottom_sheet.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/widgets/home_search_bar.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/widgets/office_preview_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AsyncValue<List<Office>> officesAsync = ref.watch(officesProvider);

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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
              final List<Office> officesForCount = officesAsync.when(
                data: (List<Office> data) => data,
                loading: () => <Office>[],
                error: (_, __) => <Office>[],
              );
              final int resultsCount = officesForCount.length;

              return HomeBottomSheet(
                resultsCount: resultsCount,
                child: officesAsync.when(
                  loading: () => _CenteredSheetState(
                    scrollController: scrollController,
                    child: const CircularProgressIndicator(),
                  ),
                  error: (Object error, StackTrace stackTrace) => _CenteredSheetState(
                    scrollController: scrollController,
                    child: _MessageCard(
                      icon: Icons.error_outline_rounded,
                      title: 'Unable to load offices',
                      subtitle: 'Please check your connection and try again.',
                      actionLabel: 'Retry',
                      onActionPressed: () => ref.invalidate(officesProvider),
                    ),
                  ),
                  data: (List<Office> offices) {
                    if (offices.isEmpty) {
                      return _CenteredSheetState(
                        scrollController: scrollController,
                        child: const _MessageCard(
                          icon: Icons.inbox_rounded,
                          title: 'No offices available',
                          subtitle: 'IEBC offices will appear here once data is added.',
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
                      itemBuilder: (BuildContext context, int index) =>
                          OfficePreviewCard(office: offices[index]),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemCount: offices.length,
                    );
                  },
                ),
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

class _CenteredSheetState extends StatelessWidget {
  const _CenteredSheetState({
    required this.scrollController,
    required this.child,
  });

  final ScrollController scrollController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: <Widget>[
        const SizedBox(height: 24),
        Center(child: child),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
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
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 34, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            if (actionLabel != null && onActionPressed != null) ...<Widget>[
              const SizedBox(height: 14),
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
