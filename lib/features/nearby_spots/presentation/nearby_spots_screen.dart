import 'package:flutter/widgets.dart';
import 'package:tuko_kadi_iebc_locator/shared/widgets/placeholder_screen.dart';

class NearbySpotsScreen extends StatelessWidget {
  const NearbySpotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Nearby Spots',
      description:
          'Explore eateries and chill places around the selected IEBC office in upcoming releases.',
    );
  }
}
