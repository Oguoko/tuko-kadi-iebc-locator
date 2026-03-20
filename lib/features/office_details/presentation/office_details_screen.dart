import 'package:flutter/widgets.dart';
import 'package:tuko_kadi_iebc_locator/shared/widgets/placeholder_screen.dart';

class OfficeDetailsScreen extends StatelessWidget {
  const OfficeDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Office Details',
      description:
          'Constituency office profile, contacts, opening hours, and directions will appear here.',
    );
  }
}
