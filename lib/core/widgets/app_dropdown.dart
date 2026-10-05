import 'package:flutter/material.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/core/theme/app_theme.dart';

/// One selectable row inside [AppDropdownField].
class AppDropdownOption<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;

  const AppDropdownOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.leadingIcon,
  });
}

/// App-wide dropdown matching the Role Permissions picker.
///
/// The raw `DropdownButton` menu is cramped, has no room for a second line,
/// and overflows on long labels. This opens a searchable bottom sheet with
/// roomy, light/dark-aware rows and reuses the roles-screen visual language.
class AppDropdownField<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<AppDropdownOption<T>> options;
  final ValueChanged<T?> onChanged;
  final IconData? icon;
  final bool searchable;
  final bool enabled;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.hint,
    this.value,
    this.icon,
    this.searchable = true,
    this.enabled = true,
  });

  String? _titleFor(T? v) {
    if (v == null) return null;
    for (final o in options) {
      if (o.value == v) return o.title;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = _titleFor(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: enabled ? () => _open(context) : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: title == null
                      ? (isDark ? AppColors.darkBorder : AppColors.border)
                      : AppColors.primary,
                  width: title == null ? 1 : 1.4,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon ?? Icons.expand_circle_down_rounded,
                    size: 20,
                    color: title == null
                        ? AppColors.textTertiary
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title ?? hint ?? 'Select $label',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: title == null
                          ? theme.textTheme.bodyLarge?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textTertiary,
                            )
                          : theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DropdownSheet<T>(
        label: label,
        options: options,
        selected: value,
        searchable: searchable,
      ),
    );
    if (picked != null) onChanged(picked);
  }
}

/// Searchable option list opened by [AppDropdownField].
class _DropdownSheet<T> extends StatefulWidget {
  final String label;
  final List<AppDropdownOption<T>> options;
  final T? selected;
  final bool searchable;

  const _DropdownSheet({
    required this.label,
    required this.options,
    required this.selected,
    required this.searchable,
  });

  @override
  State<_DropdownSheet<T>> createState() => _DropdownSheetState<T>();
}

class _DropdownSheetState<T> extends State<_DropdownSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final q = _query.trim().toLowerCase();
    final filtered = widget.options
        .where((o) =>
            q.isEmpty ||
            o.title.toLowerCase().contains(q) ||
            (o.subtitle ?? '').toLowerCase().contains(q))
        .toList();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: Text(
                'Select ${widget.label.toLowerCase()}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                ),
              ),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        widget.options.isEmpty
                            ? 'Nothing available'
                            : 'No match for "$_query"',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _DropdownRow<T>(
                        option: filtered[i],
                        isSelected: filtered[i].value == widget.selected,
                        isDark: isDark,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  final AppDropdownOption<T> option;
  final bool isSelected;
  final bool isDark;

  const _DropdownRow({
    required this.option,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected
            ? AppColors.primary.withOpacity(0.08)
            : (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: () => Navigator.of(context).pop(option.value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color:
                      isSelected ? AppColors.primary : AppColors.textTertiary,
                ),
                if (option.leadingIcon != null) ...[
                  const SizedBox(width: 10),
                  Icon(
                    option.leadingIcon,
                    size: 18,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ],
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (option.subtitle != null &&
                          option.subtitle!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            option.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
