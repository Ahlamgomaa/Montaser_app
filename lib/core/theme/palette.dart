import 'package:flutter/material.dart';

/// Every colour the application is allowed to use.
///
/// Held in one place and reached through the theme rather than written at the
/// point of use, because a colour typed into a widget is a colour that cannot
/// follow the app into dark mode — and the day somebody adds one screen with a
/// hard-coded white card is the day dark mode has a hole in it.
///
/// The set is deliberately bright. A shop selling cooling and refrigeration
/// parts could easily be drawn in industrial greys, and it would look like a
/// spare-parts catalogue from 1998; turquoise and coral cost nothing and make
/// the same catalogue feel like somewhere worth spending money. What keeps it
/// from being loud is that the brightness is spent on small areas — a price, a
/// badge, one button — over a great deal of white.
abstract final class Palette {
  /// Turquoise. Fresh, cold, and the colour of the trade itself.
  static const brand = Color(0xFF10B5A8);
  static const brandDeep = Color(0xFF058C82);
  static const brandLift = Color(0xFF2AD6C6);
  static const brandWash = Color(0xFFDFF7F4);

  /// Coral, for prices and for the one thing on a screen worth looking at
  /// first. Warm against the turquoise rather than beside it — the pair is what
  /// makes the design read as cheerful instead of merely clean.
  static const coral = Color(0xFFFF7A45);
  static const coralDeep = Color(0xFFE85E2A);
  static const coralWash = Color(0xFFFFEDE4);

  /// The four supporting colours, for artwork tints, aisle tiles and anywhere
  /// a run of things should not all be one colour.
  static const amber = Color(0xFFFFB020);
  static const violet = Color(0xFF7C5CFF);
  static const rose = Color(0xFFFF5C8A);
  static const sky = Color(0xFF3B9DFF);

  static const ink = Color(0xFF0F1E22);
  static const inkSoft = Color(0xFF48606A);
  static const inkFaint = Color(0xFF8AA0A8);

  static const canvas = Color(0xFFF3F8F9);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFE3EDEF);

  static const success = Color(0xFF16B364);
  static const successWash = Color(0xFFE3F8EE);
  static const warn = Color(0xFFE59500);
  static const warnWash = Color(0xFFFFF3DC);
  static const danger = Color(0xFFF04438);
  static const dangerWash = Color(0xFFFEEBE9);

  // ---- the same roles again, for the dark theme ----

  static const darkCanvas = Color(0xFF071316);
  static const darkSurface = Color(0xFF0E2027);
  static const darkSurfaceLift = Color(0xFF152D35);
  static const darkLine = Color(0xFF23414A);
  static const darkInk = Color(0xFFEAF6F7);
  static const darkInkSoft = Color(0xFFA9C3C9);
  static const darkInkFaint = Color(0xFF7793A0);
  static const brandOnDark = Color(0xFF3FE0D0);
  static const coralOnDark = Color(0xFFFF9466);
}

/// The handful of colours Material has no slot for.
///
/// A [ColorScheme] knows about primary and error and surface. It does not know
/// that a price is coral, that stock has three states, or that a row of aisle
/// tiles should cycle through four hues — so those live here and travel with
/// the theme instead of being looked up per widget.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.price,
    required this.priceWash,
    required this.canvas,
    required this.line,
    required this.inkSoft,
    required this.inkFaint,
    required this.success,
    required this.successWash,
    required this.warn,
    required this.warnWash,
    required this.danger,
    required this.dangerWash,
    required this.confetti,
    required this.artworkBed,
  });

  final Color price;
  final Color priceWash;
  final Color canvas;
  final Color line;
  final Color inkSoft;
  final Color inkFaint;
  final Color success;
  final Color successWash;
  final Color warn;
  final Color warnWash;
  final Color danger;
  final Color dangerWash;

  /// The cheerful set, in a fixed order.
  ///
  /// Anything that comes in a run — aisle tiles, artwork tints — steps through
  /// these by index, so neighbours never match and the same thing is always the
  /// same colour. Picking a hue by arithmetic instead would eventually land on
  /// something that fights the coral.
  final List<Color> confetti;

  /// The paper a part is drawn on, before its own tint is laid over it.
  final Color artworkBed;

  static const light = AppColors(
    price: Palette.coral,
    priceWash: Palette.coralWash,
    canvas: Palette.canvas,
    line: Palette.line,
    inkSoft: Palette.inkSoft,
    inkFaint: Palette.inkFaint,
    success: Palette.success,
    successWash: Palette.successWash,
    warn: Palette.warn,
    warnWash: Palette.warnWash,
    danger: Palette.danger,
    dangerWash: Palette.dangerWash,
    confetti: [
      Palette.brand,
      Palette.violet,
      Palette.coral,
      Palette.sky,
      Palette.amber,
      Palette.rose,
      Palette.success,
      Palette.brandDeep,
    ],
    artworkBed: Color(0xFFF7FBFB),
  );

  static const dark = AppColors(
    price: Palette.coralOnDark,
    priceWash: Color(0xFF33201A),
    canvas: Palette.darkCanvas,
    line: Palette.darkLine,
    inkSoft: Palette.darkInkSoft,
    inkFaint: Palette.darkInkFaint,
    success: Color(0xFF3FD98B),
    successWash: Color(0xFF0E2B1E),
    warn: Color(0xFFFFC44D),
    warnWash: Color(0xFF2E2513),
    danger: Color(0xFFFF7A70),
    dangerWash: Color(0xFF331917),
    confetti: [
      Palette.brandOnDark,
      Color(0xFF9E86FF),
      Palette.coralOnDark,
      Color(0xFF69B7FF),
      Color(0xFFFFC44D),
      Color(0xFFFF80A8),
      Color(0xFF3FD98B),
      Color(0xFF2AD6C6),
    ],
    artworkBed: Color(0xFF122730),
  );

  @override
  AppColors copyWith({
    Color? price,
    Color? priceWash,
    Color? canvas,
    Color? line,
    Color? inkSoft,
    Color? inkFaint,
    Color? success,
    Color? successWash,
    Color? warn,
    Color? warnWash,
    Color? danger,
    Color? dangerWash,
    List<Color>? confetti,
    Color? artworkBed,
  }) {
    return AppColors(
      price: price ?? this.price,
      priceWash: priceWash ?? this.priceWash,
      canvas: canvas ?? this.canvas,
      line: line ?? this.line,
      inkSoft: inkSoft ?? this.inkSoft,
      inkFaint: inkFaint ?? this.inkFaint,
      success: success ?? this.success,
      successWash: successWash ?? this.successWash,
      warn: warn ?? this.warn,
      warnWash: warnWash ?? this.warnWash,
      danger: danger ?? this.danger,
      dangerWash: dangerWash ?? this.dangerWash,
      confetti: confetti ?? this.confetti,
      artworkBed: artworkBed ?? this.artworkBed,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) {
      return this;
    }

    return AppColors(
      price: Color.lerp(price, other.price, t)!,
      priceWash: Color.lerp(priceWash, other.priceWash, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      line: Color.lerp(line, other.line, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      success: Color.lerp(success, other.success, t)!,
      successWash: Color.lerp(successWash, other.successWash, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnWash: Color.lerp(warnWash, other.warnWash, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerWash: Color.lerp(dangerWash, other.dangerWash, t)!,
      /*
       * The confetti does not blend. It is a set of identities, not a
       * measurement, and cross-fading turquoise into violet halfway through a
       * theme change would put a colour on screen that belongs to neither.
       */
      confetti: t < 0.5 ? confetti : other.confetti,
      artworkBed: Color.lerp(artworkBed, other.artworkBed, t)!,
    );
  }

  /// The cheerful colour that belongs to a given thing, by its id.
  Color confettiFor(int seed) => confetti[seed.abs() % confetti.length];
}

/// Reaching the theme without writing `Theme.of(context).extension<...>()!` at
/// forty call sites.
extension AppColorsOf on BuildContext {
  AppColors get palette => Theme.of(this).extension<AppColors>()!;

  ColorScheme get scheme => Theme.of(this).colorScheme;

  TextTheme get type => Theme.of(this).textTheme;
}
