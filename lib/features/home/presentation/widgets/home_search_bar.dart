import 'package:flutter/material.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    this.onSuggestionTap,
    this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final ValueChanged<String>? onSuggestionTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          elevation: 7,
          shadowColor: colors.shadow.withValues(alpha: 0.22),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (BuildContext context, TextEditingValue value, _) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search county, constituency, or office',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
                  suffixIcon: value.text.trim().isEmpty
                      ? Icon(Icons.tune_rounded, color: colors.onSurfaceVariant)
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: onClear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              );
            },
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: suggestions.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey<int>(suggestions.length),
                  padding: const EdgeInsets.only(top: 8),
                  child: Material(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 5,
                    shadowColor: colors.shadow.withValues(alpha: 0.16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: suggestions.length,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final String suggestion = suggestions[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.history_rounded,
                            size: 20,
                            color: colors.primary,
                          ),
                          title: Text(suggestion),
                          onTap: onSuggestionTap == null
                              ? null
                              : () => onSuggestionTap!(suggestion),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
