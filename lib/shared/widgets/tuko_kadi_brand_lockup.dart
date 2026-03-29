import 'package:flutter/material.dart';
import 'package:tuko_kadi_iebc_locator/app/theme/app_theme.dart';

class TukoKadiBrandLockup extends StatelessWidget {
  const TukoKadiBrandLockup({
    super.key,
    this.textScale = 1,
    this.showSubTitle = true,
    this.compact = false,
  });

  final double textScale;
  final bool showSubTitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

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
                    letterSpacing: 0.7,
                    fontSize: 17 * textScale,
                    height: 1,
                  ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 4 : 5,
                vertical: compact ? 1 : 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'KADI',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      fontSize: 15 * textScale,
                      height: 1,
                    ),
              ),
            ),
          ],
        ),
        if (showSubTitle) ...<Widget>[
          const SizedBox(height: 3),
          Text(
            'IEBC LOCATOR',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
          ),
        ],
      ],
    );
  }
}
