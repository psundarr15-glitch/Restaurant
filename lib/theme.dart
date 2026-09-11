import 'package:flutter/material.dart';

/// Jeevi Foodie Restaurant design system.
/// UX direction: professional, calm and operations-first.  Dense information
/// is grouped into clear cards, with red reserved for actions/alerts and green
/// for healthy/active states.
class AppTheme {
  static const primary = Color(0xFFD6291B);
  static const primaryDark = Color(0xFF8E1610);
  static const gold = Color(0xFFF7B500);
  static const success = Color(0xFF159447);
  static const canvas = Color(0xFFF7F7F5);

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1C) : Colors.white;
  static Color scaffoldBg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF20201E);
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : const Color(0xFF70706B);
  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : const Color(0xFFE4E4E0);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      textTheme: _textTheme(Brightness.light),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: Color(0xFF20201E),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF20201E)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: primary, minimumSize: const Size(0, 46), side: const BorderSide(color: Color(0xFFE3B7B2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF92928C)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E4E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E4E0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F0ED),
        selectedColor: primary.withOpacity(.10),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF20201E)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, showDragHandle: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        height: 70,
        elevation: 8,
        indicatorColor: primary.withOpacity(.10),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(fontSize: 10.5, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600, color: states.contains(WidgetState.selected) ? primary : const Color(0xFF70706B))),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(size: 23, color: states.contains(WidgetState.selected) ? primary : const Color(0xFF70706B))),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE8E8E4), thickness: 1, space: 1),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF141413),
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false, surfaceTintColor: Colors.transparent),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      inputDecorationTheme: InputDecorationTheme(filled: true, contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5))),
      cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
      navigationBarTheme: NavigationBarThemeData(height: 70, indicatorColor: primary.withOpacity(.22)),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark ? Colors.white : const Color(0xFF20201E);
    final muted = brightness == Brightness.dark ? Colors.grey.shade400 : const Color(0xFF70706B);
    return TextTheme(
      headlineSmall: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: base),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: base),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: base),
      bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: base, height: 1.4),
      bodyMedium: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: muted, height: 1.35),
      labelLarge: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: base),
    );
  }
}
