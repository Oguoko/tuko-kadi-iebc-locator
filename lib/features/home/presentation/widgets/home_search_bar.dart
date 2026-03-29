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
          borderRadius: BorderRadius.circular(8),
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (BuildContext context, TextEditingValue value, _) {
                final bool hasText = value.text.trim().isNotEmpty;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search county, constituency, or office',
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: hasText ? colors.primary : colors.onSurface,
                    ),
                    suffixIcon: hasText
                        ? IconButton(
                            tooltip: 'Clear search',
                            onPressed: onClear,
                            icon: Icon(
                              Icons.close_rounded,
                              color: colors.onSurfaceVariant,
                            ),
                          )
                        : Container(
                            width: 38,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 19,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                  ),
                );
              },
            ),
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
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: suggestions.length,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: colors.outlineVariant,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final String suggestion = suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.history_rounded,
                              size: 20,
                              color: colors.primary,
                            ),
                            title: Text(
                              suggestion,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            onTap: onSuggestionTap == null
                                ? null
                                : () => onSuggestionTap!(suggestion),
                          );
                        },
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
