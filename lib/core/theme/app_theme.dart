import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dimens.dart';
import 'palette.dart';

/// The two themes, built once.
///
/// Both are assembled here rather than in `main` so that the light and the dark
/// are written next to each other. Kept apart, one of them quietly falls a
/// version behind the other and nobody notices until a screenshot.
abstract final class AppTheme {
  /// Cairo, in two weights.
  ///
  /// Only 400 and 700 are bundled, so the scale is designed around them. Asking
  /// for `w600` here would not produce a semibold — it would silently pick one
  /// of the two and the intent would be lost in the gap.
  static const _face = 'Cairo';

  static ThemeData get light => _build(
    brightness: Brightness.light,
    colors: AppColors.light,
    scheme: const ColorScheme.light(
      primary: Palette.brand,
      onPrimary: Colors.white,
      primaryContainer: Palette.brandWash,
      onPrimaryContainer: Palette.brandDeep,
      secondary: Palette.coral,
      onSecondary: Colors.white,
      surface: Palette.surface,
      onSurface: Palette.ink,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFFBFDFD),
      surfaceContainer: Palette.canvas,
      surfaceContainerHigh: Color(0xFFEAF4F4),
      outline: Palette.line,
      outlineVariant: Color(0xFFEEF5F6),
      error: Palette.danger,
      onError: Colors.white,
    ),
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colors: AppColors.dark,
    scheme: const ColorScheme.dark(
      primary: Palette.brandOnDark,
      onPrimary: Color(0xFF03211E),
      primaryContainer: Color(0xFF0C3A38),
      onPrimaryContainer: Palette.brandOnDark,
      secondary: Palette.coralOnDark,
      onSecondary: Color(0xFF2A1A0C),
      surface: Palette.darkSurface,
      onSurface: Palette.darkInk,
      surfaceContainerLowest: Color(0xFF0A1315),
      surfaceContainerLow: Palette.darkSurface,
      surfaceContainer: Palette.darkSurfaceLift,
      surfaceContainerHigh: Color(0xFF1D2E33),
      outline: Palette.darkLine,
      outlineVariant: Color(0xFF1C2C31),
      error: Color(0xFFFF7A70),
      onError: Color(0xFF2B0F0C),
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
    required ColorScheme scheme,
  }) {
    /*
     * The family is stamped onto every style rather than left to ThemeData's
     * `fontFamily` to merge in. The merge does work — but it does not reach
     * styles a widget builds itself with `TextStyle(...)`, and one screen that
     * does that is one screen in the system font. Stamping it here means the
     * only way to get a different face is to ask for one.
     */
    final text = _typeScale(
      scheme.onSurface,
      colors.inkSoft,
    ).apply(fontFamily: _face);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: _face,
      textTheme: text,
      scaffoldBackgroundColor: colors.canvas,
      extensions: <ThemeExtension<dynamic>>[colors],

      /*
       * Off, deliberately. Material's default is a lilac wash pulled from the
       * primary colour and laid over every raised surface; on a palette this
       * particular it turns the greys green and the whole app looks tinted by
       * accident rather than by choice.
       */
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: colors.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Corner.rLg,
          side: BorderSide(color: colors.line),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colors.line,
        thickness: 1,
        space: 1,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: Corner.rMd),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: text.labelLarge,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: colors.line),
          shape: const RoundedRectangleBorder(borderRadius: Corner.rMd),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
          minimumSize: const Size(0, Metric.tap),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Gap.lg,
          vertical: Gap.lg,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: colors.inkFaint),
        labelStyle: text.bodyMedium?.copyWith(color: colors.inkSoft),
        floatingLabelStyle: text.labelMedium?.copyWith(color: scheme.primary),
        border: OutlineInputBorder(
          borderRadius: Corner.rMd,
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Corner.rMd,
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Corner.rMd,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Corner.rMd,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Corner.rMd,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        side: BorderSide(color: colors.line),
        labelStyle: text.labelMedium,
        shape: const RoundedRectangleBorder(borderRadius: Corner.pill),
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.md,
          vertical: Gap.sm,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colors.line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Corner.xl)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: Corner.rLg),
        titleTextStyle: text.titleMedium,
        contentTextStyle: text.bodyMedium,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.light
            ? Palette.ink
            : Palette.darkSurfaceLift,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: Corner.rMd),
        insetPadding: const EdgeInsets.all(Gap.lg),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return text.labelSmall?.copyWith(
            color: selected ? scheme.primary : colors.inkFaint,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return IconThemeData(
            size: 24,
            color: selected ? scheme.primary : colors.inkFaint,
          );
        }),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall?.copyWith(color: colors.inkFaint),
        iconColor: colors.inkSoft,
        shape: const RoundedRectangleBorder(borderRadius: Corner.rMd),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: colors.line,
        circularTrackColor: colors.line,
      ),
    );
  }

  /// The type scale.
  ///
  /// Arabic sits lower in its box than Latin does and needs a looser line to
  /// stay readable, so the heights here are deliberately taller than Material's
  /// defaults. Left alone, headings collide with their own descenders.
  static TextTheme _typeScale(Color ink, Color soft) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 32,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.4,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        height: 1.45,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 1.5,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        height: 1.55,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.6,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.6,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.75, color: ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.8, color: ink),
      bodySmall: TextStyle(fontSize: 13, height: 1.7, color: soft),
      labelLarge: const TextStyle(
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      labelSmall: TextStyle(fontSize: 11, height: 1.4, color: soft),
    );
  }
}
