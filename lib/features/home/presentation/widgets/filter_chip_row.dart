import 'package:flutter/material.dart';

class FilterChipRow extends StatelessWidget {
  const FilterChipRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const <Widget>[
          _HomeFilterChip(label: 'Nearest', selected: true, icon: Icons.near_me),
          SizedBox(width: 8),
          _HomeFilterChip(label: 'Open Now', icon: Icons.schedule_rounded),
          SizedBox(width: 8),
          _HomeFilterChip(label: 'Food Nearby', icon: Icons.ramen_dining_rounded),
          SizedBox(width: 8),
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

    return FilterChip(
      selected: selected,
      onSelected: (_) {},
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      avatar: Icon(
        icon,
        size: 15,
        color: selected ? colors.onPrimary : colors.onSurface,
      ),
      label: Text(label),
      selectedColor: colors.primary,
      side: BorderSide(
        color: selected ? colors.primary : colors.outline,
        width: selected ? 1.4 : 1,
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.1,
        color: selected ? colors.onPrimary : colors.onSurface,
      ),
      backgroundColor: colors.surface,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
