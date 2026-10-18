import 'package:flutter/material.dart';

/// Colour roles. Every screen is built from a ground, one or two surface
/// steps, ink, muted ink and a single accent used sparingly (primary actions
/// and the current item). Surfaces are separated by tone, never by shadows or
/// borders.
@immutable
class Palette {
  const Palette({
    required this.ground,
    required this.surface,
    required this.surfaceHigh,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.danger,
  });

  final Color ground;
  final Color surface;
  final Color surfaceHigh;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final Color danger;

  /// Parent mode, light: cool white and slate with a deep teal accent.
  static const parentLight = Palette(
    ground: Color(0xFFF7F9FA),
    surface: Color(0xFFECF0F2),
    surfaceHigh: Color(0xFFDFE5E8),
    ink: Color(0xFF1F3038),
    muted: Color(0xFF5D6B72),
    accent: Color(0xFF0D7480),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFB3261E),
  );

  /// Parent mode, dark: the same slate family, deepened.
  static const parentDark = Palette(
    ground: Color(0xFF111719),
    surface: Color(0xFF1A2226),
    surfaceHigh: Color(0xFF253036),
    ink: Color(0xFFE4EBED),
    muted: Color(0xFF8E9CA2),
    accent: Color(0xFF5BBAC4),
    onAccent: Color(0xFF062226),
    danger: Color(0xFFF2B8B5),
  );

  /// Kid mode: a soft sky ground with dark ink; orange only for play and the
  /// video that's on.
  static const kid = Palette(
    ground: Color(0xFFCBE4F2),
    surface: Color(0xFFE4F1F8),
    surfaceHigh: Color(0xFFB4D6EA),
    ink: Color(0xFF0E1822),
    muted: Color(0xFF44606E),
    accent: Color(0xFFFF5A1F),
    onAccent: Color(0xFF0E1822),
    danger: Color(0xFFB3261E),
  );

  /// Kid mode at night: full screen and the time-up screen. The sky palette
  /// inverted onto navy.
  static const kidNight = Palette(
    ground: Color(0xFF0E1822),
    surface: Color(0xFF182633),
    surfaceHigh: Color(0xFF233545),
    ink: Color(0xFFCBE4F2),
    muted: Color(0xFF7F9BAB),
    accent: Color(0xFFFF5A1F),
    onAccent: Color(0xFF0E1822),
    danger: Color(0xFFF2B8B5),
  );

  ColorScheme scheme(Brightness brightness) => ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: onAccent,
    primaryContainer: surfaceHigh,
    onPrimaryContainer: ink,
    secondary: ink,
    onSecondary: ground,
    secondaryContainer: surfaceHigh,
    onSecondaryContainer: ink,
    tertiary: accent,
    onTertiary: onAccent,
    tertiaryContainer: surfaceHigh,
    onTertiaryContainer: ink,
    error: danger,
    onError: ground,
    errorContainer: surfaceHigh,
    onErrorContainer: danger,
    surface: ground,
    onSurface: ink,
    onSurfaceVariant: muted,
    surfaceDim: surface,
    surfaceBright: ground,
    surfaceContainerLowest: ground,
    surfaceContainerLow: surface,
    surfaceContainer: surface,
    surfaceContainerHigh: surfaceHigh,
    surfaceContainerHighest: surfaceHigh,
    outline: muted,
    outlineVariant: surfaceHigh,
    shadow: Colors.transparent,
    scrim: const Color(0x99000000),
    inverseSurface: ink,
    onInverseSurface: ground,
    inversePrimary: accent,
    surfaceTint: Colors.transparent,
  );
}

/// Bundled typefaces (no runtime font downloads): League Spartan for
/// headings, Figtree for everything else.
abstract final class AppFonts {
  static const display = 'LeagueSpartan';
  static const text = 'Figtree';

  /// A heading style: heavy, tightly tracked, short leading.
  static TextStyle heading(double size, Color color) => TextStyle(
    fontFamily: display,
    fontSize: size,
    fontWeight: FontWeight.w700,
    letterSpacing: size * -0.03,
    height: 1.05,
    color: color,
  );
}

abstract final class AppTheme {
  static ThemeData light() => _parent(Palette.parentLight, Brightness.light);
  static ThemeData dark() => _parent(Palette.parentDark, Brightness.dark);

  /// Kid mode: sky ground, big type, big targets. Always light.
  static ThemeData kid() => _build(
    Palette.kid,
    Brightness.light,
    scale: 1.25,
    buttonHeight: 72,
    buttonText: 22,
  );

  /// Kid mode's dark rooms: full screen and time up.
  static ThemeData kidNight() => _build(
    Palette.kidNight,
    Brightness.dark,
    scale: 1.25,
    buttonHeight: 72,
    buttonText: 22,
  );

  static ThemeData _parent(Palette p, Brightness b) =>
      _build(p, b, scale: 1, buttonHeight: 52, buttonText: 16);

  static TextTheme _textTheme(Palette p, double scale) {
    TextStyle text(
      double size,
      FontWeight weight, {
      double height = 1.45,
      Color? color,
    }) => TextStyle(
      fontFamily: AppFonts.text,
      fontSize: size * scale,
      fontWeight: weight,
      height: height,
      letterSpacing: 0,
      color: color ?? p.ink,
    );
    TextStyle head(double size) => AppFonts.heading(size * scale, p.ink);
    return TextTheme(
      displayLarge: head(56),
      displayMedium: head(46),
      displaySmall: head(38),
      headlineLarge: head(34),
      headlineMedium: head(30),
      headlineSmall: head(26),
      titleLarge: head(23),
      titleMedium: text(17, FontWeight.w600, height: 1.3),
      titleSmall: text(15, FontWeight.w600, height: 1.3),
      bodyLarge: text(17, FontWeight.w400, height: 1.5),
      bodyMedium: text(15, FontWeight.w400),
      bodySmall: text(13, FontWeight.w400, height: 1.4, color: p.muted),
      labelLarge: text(15, FontWeight.w600, height: 1.2),
      labelMedium: text(13, FontWeight.w600, height: 1.2),
      labelSmall: text(12, FontWeight.w500, height: 1.2, color: p.muted),
    );
  }

  static ThemeData _build(
    Palette p,
    Brightness brightness, {
    required double scale,
    required double buttonHeight,
    required double buttonText,
  }) {
    final scheme = p.scheme(brightness);
    final text = _textTheme(p, scale);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonHeight > 60 ? 28 : 14),
    );
    final buttonTextStyle = TextStyle(
      fontFamily: AppFonts.text,
      fontSize: buttonText,
      fontWeight: FontWeight.w600,
    );
    final fieldRadius = BorderRadius.circular(14);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppFonts.text,
      textTheme: text,
      scaffoldBackgroundColor: p.ground,
      canvasColor: p.ground,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: p.ground,
        foregroundColor: p.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: AppFonts.heading(24 * scale, p.ink),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(64, buttonHeight),
          shape: buttonShape,
          textStyle: buttonTextStyle,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(64, buttonHeight),
          shape: buttonShape,
          textStyle: buttonTextStyle,
          foregroundColor: p.ink,
          backgroundColor: p.surface,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.ink,
          textStyle: buttonTextStyle.copyWith(fontSize: buttonText - 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.ink),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        extendedTextStyle: buttonTextStyle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: p.muted),
        floatingLabelStyle: TextStyle(color: p.ink),
        hintStyle: TextStyle(color: p.muted),
        border: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: p.ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: p.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: p.danger, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.ground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: p.surfaceHigh,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: AppFonts.text,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? p.ink : p.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? p.ink : p.muted,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.ink,
        disabledColor: p.surface,
        checkmarkColor: p.ground,
        side: BorderSide.none,
        labelStyle: TextStyle(
          fontFamily: AppFonts.text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: p.ink,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: AppFonts.text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: p.ground,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: const WidgetStatePropertyAll(BorderSide.none),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.ink : p.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.ground : p.ink,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onAccent : p.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.surfaceHigh,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.muted,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.accent,
        inactiveTrackColor: p.surfaceHigh,
        thumbColor: p.accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceHigh,
        circularTrackColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: p.surfaceHigh,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.ground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppFonts.heading(24 * scale, p.ink),
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.ground,
        modalBackgroundColor: p.ground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: p.surfaceHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.ground),
        actionTextColor: p.ground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: text.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: p.ground, fontSize: 13),
      ),
    );
  }
}

extension PaletteOf on BuildContext {
  /// The [Palette] behind the current theme.
  Palette get palette {
    final scheme = Theme.of(this).colorScheme;
    final p = switch (scheme.surface) {
      final c when c == Palette.kid.ground => Palette.kid,
      final c when c == Palette.kidNight.ground => Palette.kidNight,
      final c when c == Palette.parentDark.ground => Palette.parentDark,
      _ => Palette.parentLight,
    };
    return p;
  }
}
