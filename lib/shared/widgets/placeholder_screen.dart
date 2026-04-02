import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.description,
    this.child,
    super.key,
  });

  final String title;
  final String description;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Image.asset('assets/branding/logo.png', height: 24),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Image.asset('assets/branding/icon.png', width: 18, height: 18),
                const SizedBox(width: 8),
                Text(title, style: textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: textTheme.bodyLarge),
            if (child != null) ...<Widget>[
              const SizedBox(height: 20),
              child ?? const SizedBox.shrink(),
            ],
          ],
        ),
      ),
    );
  }
}
