import 'package:flutter/material.dart';
import '../../theme.dart';

/// Rounded search field used at the top of Orders/Menu screens.
class AppSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const AppSearchBar({super.key, required this.hint, required this.onChanged, this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 22),
        isDense: true,
        filled: true,
        fillColor: AppTheme.surface(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

/// Pill-shaped filter tab (e.g. order status filters, menu categories).
/// Horizontally scrollable rows of these are built with [FilterChipRow].
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  const AppFilterChip({super.key, required this.label, required this.selected, required this.onTap, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: selected ? null : Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Text(
            count != null ? '$label ($count)' : label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal scroller of [AppFilterChip]s — the "All / New / Preparing /
/// Ready ..." tab row pattern reused on Orders, Kitchen, and Offers.
class FilterChipRow extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<int>? counts;

  const FilterChipRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        itemBuilder: (context, i) => AppFilterChip(
          label: labels[i],
          selected: i == selectedIndex,
          count: counts != null && i < counts!.length ? counts![i] : null,
          onTap: () => onSelected(i),
        ),
      ),
    );
  }
}
