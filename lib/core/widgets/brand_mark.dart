import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/store/identity_store.dart';
import '../theme/dimens.dart';
import '../theme/palette.dart';

/// The shop's mark.
///
/// Drawn rather than loaded, because there is no logo file and waiting for one
/// would leave a hole in every screen that needs a brand on it. A snowflake in
/// a rounded square says what this shop sells before a word is read, and being
/// a path rather than a picture it is sharp at any size, weighs nothing, and
/// follows the theme into dark mode without a second asset.
///
/// The day a real logo arrives, it replaces the [CustomPaint] inside here and
/// nothing above this file changes.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 44, this.plain = false, super.key});

  final double size;

  /// Draws the flake in the current text colour on nothing, for places that
  /// already have a coloured bed underneath — a gradient square on a gradient
  /// header is a square nobody can see the edge of.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final flake = CustomPaint(
      size: Size.square(size),
      painter: _FlakePainter(
        colour: plain ? Colors.white : Colors.white,
        stroke: size * 0.075,
      ),
    );

    if (plain) {
      return SizedBox.square(dimension: size, child: flake);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Palette.brandLift, Palette.brand],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.24),
        child: CustomPaint(
          painter: _FlakePainter(colour: Colors.white, stroke: size * 0.075),
        ),
      ),
    );
  }
}

/// The mark with the name beside it.
///
/// The name is the shop's own, from its settings page, by way of [ShopBadge] —
/// which is what lets this be drawn on the splash and the sign-in screens,
/// before `home` has been asked. Watched rather than read once, so a shop that
/// is renamed corrects itself the moment the shop front answers.
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    this.size = 42,
    this.onDark = false,
    this.showTagline = true,
    super.key,
  });

  final double size;
  final bool onDark;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final ink = onDark ? Colors.white : context.scheme.onSurface;
    final faint = onDark
        ? Colors.white.withValues(alpha: 0.72)
        : context.palette.inkFaint;

    /*
     * Listened to rather than read once. The shop front answers after this has
     * already been drawn — on the splash, and on both sign-in screens — and a
     * name that arrives a second later has to replace the blank rather than
     * wait for the next screen.
     */
    return ListenableBuilder(
      listenable: ShopBadge.instance,
      builder: (context, _) => _row(type, ink, faint),
    );
  }

  Widget _row(TextTheme type, Color ink, Color faint) {
    final badge = ShopBadge.instance;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: size),
        Gap.w12,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              badge.name,
              style: type.titleLarge?.copyWith(color: ink, height: 1.2),
            ),
            if (showTagline && badge.tagline.isNotEmpty)
              Text(
                badge.tagline,
                style: type.labelSmall?.copyWith(color: faint, height: 1.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ],
    );
  }
}

/// Six spokes and a ring.
///
/// A snowflake reduced to what survives at sixteen pixels: the spokes, one pair
/// of barbs on each, and a small open centre. The detailed version — three
/// barbs a side, fractal tips — turns into a grey smudge in a tab bar, which is
/// the size this mark is seen at most often.
class _FlakePainter extends CustomPainter {
  const _FlakePainter({required this.colour, required this.stroke});

  final Color colour;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = Offset(size.width / 2, size.height / 2);
    final reach = size.width / 2;

    final pen = Paint()
      ..color = colour
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var spoke = 0; spoke < 6; spoke++) {
      final turn = spoke * math.pi / 3;
      final tip = middle + Offset(math.cos(turn), math.sin(turn)) * reach;

      canvas.drawLine(middle, tip, pen);

      /*
       * The barbs sit two thirds along and lean out at thirty degrees. Any
       * further out and they clip the edge; any further in and the flake reads
       * as a plain asterisk.
       */
      final joint = middle + (tip - middle) * 0.62;
      final barb = reach * 0.28;

      for (final lean in const [0.52, -0.52]) {
        canvas.drawLine(
          joint,
          joint + Offset(math.cos(turn + lean), math.sin(turn + lean)) * barb,
          pen,
        );
      }
    }

    canvas.drawCircle(
      middle,
      reach * 0.16,
      Paint()
        ..color = colour
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_FlakePainter old) =>
      old.colour != colour || old.stroke != stroke;
}
