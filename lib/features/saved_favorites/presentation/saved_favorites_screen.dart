import 'package:flutter/widgets.dart';
import 'package:tuko_kadi_iebc_locator/shared/widgets/placeholder_screen.dart';

class SavedFavoritesScreen extends StatelessWidget {
  const SavedFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Saved Favorites',
      description:
          'Keep your frequently used offices and preferred nearby spots in one list.',
    );
  }
}
