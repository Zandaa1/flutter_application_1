import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seedColor = Color(0xFF0F6E8C);
  static const double _tapTargetHeight = 56;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(16));

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      scaffoldBackgroundColor: isDark
          ? colorScheme.surface
          : colorScheme.surfaceContainerLowest,
      textTheme: Typography.material2021().englishLike.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ).copyWith(
        titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        titleSmall: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.35),
        bodyMedium: const TextStyle(fontSize: 15, height: 1.35),
        bodySmall: const TextStyle(fontSize: 13, height: 1.35),
        labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(size: 24, color: colorScheme.onSurfaceVariant),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: _radius,
          side: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 16,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: _radius,
        ),
        iconColor: colorScheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, _tapTargetHeight),
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, _tapTargetHeight),
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
          ),
          side: BorderSide(color: colorScheme.outline),
          foregroundColor: colorScheme.onSurface,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, _tapTargetHeight),
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: _radius,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: _radius,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: colorScheme.outlineVariant,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
