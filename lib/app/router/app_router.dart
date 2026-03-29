import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuko_kadi_iebc_locator/app/navigation/main_navigation_shell.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/home_screen.dart';
import 'package:tuko_kadi_iebc_locator/features/nearby_spots/presentation/nearby_spots_screen.dart';
import 'package:tuko_kadi_iebc_locator/features/office_details/presentation/office_details_screen.dart';
import 'package:tuko_kadi_iebc_locator/features/profile/presentation/profile_screen.dart';
import 'package:tuko_kadi_iebc_locator/features/saved_favorites/presentation/saved_favorites_screen.dart';
import 'package:tuko_kadi_iebc_locator/features/search/presentation/search_screen.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String explore = '/explore';
  static const String officeDetails = '/office-details';
  static const String nearbySpots = '/nearby-spots';
  static const String search = '/search';
  static const String savedFavorites = '/saved';
  static const String profile = '/profile';
}

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        redirect: (_, _) => AppRoutes.explore,
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.explore,
                name: 'explore',
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.search,
                name: 'search',
                builder: (BuildContext context, GoRouterState state) =>
                    const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.savedFavorites,
                name: 'saved-favorites',
                builder: (BuildContext context, GoRouterState state) =>
                    const SavedFavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.officeDetails,
        name: 'office-details',
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          final Office? office = extra is Office ? extra : null;

          return OfficeDetailsScreen(office: office);
        },
      ),
      GoRoute(
        path: AppRoutes.nearbySpots,
        name: 'nearby-spots',
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          final Office? office = extra is Office ? extra : null;

          return NearbySpotsScreen(office: office);
        },
      ),
    ],
  );
}
