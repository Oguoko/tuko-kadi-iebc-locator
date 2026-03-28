import 'package:flutter/material.dart';
import 'package:tuko_kadi_iebc_locator/app/theme/app_theme.dart';

class TukoKadiBrandLockup extends StatelessWidget {
  const TukoKadiBrandLockup({
    super.key,
    this.textScale = 1,
    this.showSubTitle = true,
  });

  final double textScale;
  final bool showSubTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'TUKO',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontSize: 17 * textScale,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'KADI',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.red,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontSize: 17 * textScale,
              ),
            ),
          ],
        ),
        if (showSubTitle)
          Text(
            'IEBC Locator',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
      ],
    );
  }
}
