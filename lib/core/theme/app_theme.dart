import 'package:flutter/material.dart';

/// Brand colours. Parent mode derives a full Material 3 scheme from the seed;
/// Kid mode uses its own brighter palette ([KidPalette]).
abstract final class BrandColors {
  static const seed = Color(0xFF5B5BD6); // Clipsy indigo
  static const coral = Color(0xFFFF7A59);
  static const sunshine = Color(0xFFFFC94D);
  static const mint = Color(0xFF3CC8A4);
  static const sky = Color(0xFF4DA8FF);
}

abstract final class AppTheme {
  static ThemeData light() => _parent(Brightness.light);
  static ThemeData dark() => _parent(Brightness.dark);

  static ThemeData _parent(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: BrandColors.seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /// Kid mode: bright but calm, rounded, large type and touch targets.
  /// Always light so thumbnails pop and text contrast stays high.
  static ThemeData kid() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BrandColors.sky,
      brightness: Brightness.light,
      surface: const Color(0xFFFFFBF2),
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFFFFBF2),
      // ThemeData's text theme has no sizes until Theme localizes it, so
      // resolve the geometry first or fontSizeFactor can't apply.
      textTheme: Typography.englishLike2021
          .merge(base.textTheme)
          .apply(
            bodyColor: const Color(0xFF1F2340),
            displayColor: const Color(0xFF1F2340),
            fontSizeFactor: 1.25,
          ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 72),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
