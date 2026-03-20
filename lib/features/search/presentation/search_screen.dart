import 'package:flutter/widgets.dart';
import 'package:tuko_kadi_iebc_locator/shared/widgets/placeholder_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Search',
      description:
          'Search by constituency, county, or office name with smart suggestions coming soon.',
    );
  }
}
