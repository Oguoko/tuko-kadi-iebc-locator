import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/home_screen.dart';
import 'package:tuko_kadi_iebc_locator/features/nearby_spots/presentation/nearby_spots_screen.dart';
import 'package:tuko_kadi_iebc_locator/features/office_details/presentation/office_details_screen.dart';
import 'package:tuko_kadi_iebc_locator/features/saved_favorites/presentation/saved_favorites_screen.dart';
import 'package:tuko_kadi_iebc_locator/features/search/presentation/search_screen.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String officeDetails = '/office-details';
  static const String nearbySpots = '/nearby-spots';
  static const String search = '/search';
  static const String savedFavorites = '/saved-favorites';
}

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
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
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (BuildContext context, GoRouterState state) =>
            const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.savedFavorites,
        name: 'saved-favorites',
        builder: (BuildContext context, GoRouterState state) =>
            const SavedFavoritesScreen(),
      ),
    ],
  );
}
