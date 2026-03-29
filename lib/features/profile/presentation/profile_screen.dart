import 'package:flutter/widgets.dart';
import 'package:tuko_kadi_iebc_locator/shared/widgets/placeholder_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Profile',
      description:
          'Manage your account details, accessibility preferences, and app settings.',
    );
  }
}
