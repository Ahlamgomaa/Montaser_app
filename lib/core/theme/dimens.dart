import 'package:flutter/material.dart';

/// Spacing, on a scale rather than by eye.
///
/// Seven values instead of every multiple of two. A scale is what makes
/// unrelated screens written weeks apart look like they belong to the same
/// application, and the restriction is the point: reaching for 13 is how that
/// stops being true.
abstract final class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const huge = 48.0;

  static const h4 = SizedBox(height: xs);
  static const h8 = SizedBox(height: sm);
  static const h12 = SizedBox(height: md);
  static const h16 = SizedBox(height: lg);
  static const h24 = SizedBox(height: xl);
  static const h32 = SizedBox(height: xxl);
  static const h48 = SizedBox(height: huge);

  static const w4 = SizedBox(width: xs);
  static const w8 = SizedBox(width: sm);
  static const w12 = SizedBox(width: md);
  static const w16 = SizedBox(width: lg);
  static const w24 = SizedBox(width: xl);
}

/// Corner radii, likewise on a scale.
abstract final class Corner {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 18.0;
  static const xl = 26.0;

  static const rSm = BorderRadius.all(Radius.circular(sm));
  static const rMd = BorderRadius.all(Radius.circular(md));
  static const rLg = BorderRadius.all(Radius.circular(lg));
  static const rXl = BorderRadius.all(Radius.circular(xl));
  static const pill = BorderRadius.all(Radius.circular(999));
}

/// Sizes the layout leans on in more than one place.
abstract final class Metric {
  /// The page margin. Wide enough that text does not run into the bezel, narrow
  /// enough that a product grid still fits two columns on a small phone.
  static const pagePad = EdgeInsets.symmetric(horizontal: Gap.lg);

  /// How tall a product card's artwork is relative to its width.
  static const artworkRatio = 1.02;

  /// A tap target is never smaller than this, whatever it looks like.
  static const tap = 44.0;

  /// Room left under a scrolling page so the last row clears the bottom bar and
  /// the phone's own gesture strip.
  static const bottomRest = 108.0;
}
