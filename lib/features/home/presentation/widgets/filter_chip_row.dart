import 'package:flutter/material.dart';

class FilterChipRow extends StatelessWidget {
  const FilterChipRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const <Widget>[
          _HomeFilterChip(label: 'Nearest', selected: true, icon: Icons.near_me),
          SizedBox(width: 10),
          _HomeFilterChip(label: 'Open Now', icon: Icons.schedule_rounded),
          SizedBox(width: 10),
          _HomeFilterChip(label: 'Food Nearby', icon: Icons.ramen_dining_rounded),
          SizedBox(width: 10),
          _HomeFilterChip(label: 'Chill Spots', icon: Icons.park_rounded),
        ],
      ),
    );
  }
}

class _HomeFilterChip extends StatelessWidget {
  const _HomeFilterChip({
    required this.label,
    required this.icon,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: FilterChip(
        selected: selected,
        onSelected: (_) {},
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        avatar: Icon(
          icon,
          size: 17,
          color: selected ? colors.onPrimary : colors.onSurfaceVariant,
        ),
        label: Text(label),
        selectedColor: colors.primary,
        side: BorderSide(color: selected ? colors.primary : colors.outlineVariant),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? colors.onPrimary : colors.onSurface,
        ),
        backgroundColor: colors.surface,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
