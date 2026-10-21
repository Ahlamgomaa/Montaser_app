import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/palette.dart';

/// The picture of a part — the shop's own where there is one, and a drawn
/// stand-in where there is not.
///
/// A shop like this has thousands of items and photographs of a few dozen. The
/// usual answer — a grey box with a broken-image glyph — makes the whole
/// catalogue look unfinished, so the missing photograph is designed for
/// directly: a coloured bed, a faint engineering grid, and the part's own icon.
///
/// The colour comes from the part's id, so a given part looks the same every
/// time it appears and two parts side by side never match. That is what makes a
/// grid of these read as a bright catalogue rather than as a wall of
/// placeholders.
///
/// The photograph takes precedence wherever the shop has uploaded one. Every
/// screen that shows a part goes through this one widget, so a part with a
/// picture shows it on the shelf, in the basket, on the order and on its own
/// page — and one without falls back to the drawing in all four rather than to
/// a broken-image glyph in some of them.
class PartArtwork extends StatelessWidget {
  const PartArtwork({
    required this.seed,
    required this.glyph,
    this.imageUrl,
    this.size,
    this.radius = Corner.rLg,
    this.dense = false,
    super.key,
  });

  final int seed;
  final IconData glyph;

  /// The shop's own photograph, where it has uploaded one.
  final String? imageUrl;
  final double? size;
  final BorderRadius radius;

  /// Smaller icon and finer grid, for the artwork inside a basket line.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final photograph = imageUrl?.trim() ?? '';

    if (photograph.isNotEmpty) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            width: size,
            height: size,
            child: Image.network(
              photograph,
              fit: BoxFit.cover,
              /*
               * The drawing while it arrives, and the drawing if it never
               * does. A grey box mid-load makes a fast connection look slow;
               * a broken-image glyph on a dead link makes the shop look
               * broken. Both are already answered by the thing underneath.
               */
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _drawn(context),
              errorBuilder: (context, error, stack) => _drawn(context),
            ),
          ),
        ),
      );
    }

    return _drawn(context);
  }

  /// The stand-in: a coloured bed, a faint grid, and the part's own icon.
  Widget _drawn(BuildContext context) {
    final colors = context.palette;
    final tint = colors.confettiFor(seed);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color.alphaBlend(
                    tint.withValues(alpha: dark ? 0.26 : 0.20),
                    colors.artworkBed,
                  ),
                  Color.alphaBlend(
                    tint.withValues(alpha: dark ? 0.12 : 0.07),
                    colors.artworkBed,
                  ),
                ],
              ),
            ),
            child: CustomPaint(
              painter: _GridPainter(
                colour: tint.withValues(alpha: dark ? 0.20 : 0.16),
                spacing: dense ? 10 : 18,
              ),
              child: Center(
                child: Icon(
                  glyph,
                  size: dense ? 24 : 50,
                  color: dark
                      ? tint
                      : Color.alphaBlend(
                          Colors.black.withValues(alpha: 0.18),
                          tint,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The faint squared paper behind the icon.
///
/// A blueprint grid rather than a decorative pattern: it says workshop without
/// saying anything, and it gives the flat tint enough texture that the card does
/// not look like an area waiting to be filled.
class _GridPainter extends CustomPainter {
  const _GridPainter({required this.colour, required this.spacing});

  final Color colour;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = colour
      ..strokeWidth = 0.7;

    for (var x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), pen);
    }

    for (var y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pen);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.colour != colour || old.spacing != spacing;
}
