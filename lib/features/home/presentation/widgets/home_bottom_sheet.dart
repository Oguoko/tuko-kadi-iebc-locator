import 'package:flutter/material.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/models/office_preview.dart';
import 'package:tuko_kadi_iebc_locator/features/home/presentation/widgets/office_preview_card.dart';

class HomeBottomSheet extends StatelessWidget {
  const HomeBottomSheet({
    super.key,
    required this.offices,
    required this.scrollController,
  });

  final List<OfficePreview> offices;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: <Widget>[
                Text(
                  'Nearby IEBC offices',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${offices.length} results',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
              itemBuilder: (BuildContext context, int index) =>
                  OfficePreviewCard(office: offices[index]),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemCount: offices.length,
            ),
          ),
        ],
      ),
    );
  }
}
