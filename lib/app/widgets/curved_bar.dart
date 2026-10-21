import 'package:flutter/material.dart';

import '../../core/theme/dimens.dart';
import '../../core/theme/palette.dart';

/// One stop on the bar.
@immutable
class BarStop {
  const BarStop({
    required this.label,
    required this.glyph,
    required this.chosenGlyph,
    this.badge = 0,
  });

  final String label;
  final IconData glyph;
  final IconData chosenGlyph;

  /// A number to show on the icon, or zero for none.
  final int badge;
}

/// The bottom bar: curved at both ends, notched in the middle.
///
/// The shop itself sits in the notch as a raised circle. It is the one
/// destination a customer returns to more than all the others put together, and
/// giving it a shape none of the rest have means it can be found without
/// reading — which is what a bottom bar is for.
///
/// The notch is cut rather than drawn. A hand-plotted arc has to be re-derived
/// every time the circle changes size, and it goes subtly wrong at the joins;
/// subtracting the circle's own path from the bar's gives an opening that
/// matches it exactly, by construction.
class CurvedBar extends StatelessWidget {
  const CurvedBar({
    required this.stops,
    required this.centre,
    required this.chosen,
    required this.onTap,
    required this.onCentre,
    required this.centreChosen,
    super.key,
  });

  /// The four stops around the circle — two before it, two after.
  final List<BarStop> stops;

  /// What sits in the notch.
  final BarStop centre;

  /// Which of [stops] is current, or null when the circle is.
  final int? chosen;

  final ValueChanged<int> onTap;
  final VoidCallback onCentre;
  final bool centreChosen;

  /// How tall the bar is, not counting the part of the circle above it.
  static const bar = 66.0;

  /// The raised circle.
  static const disc = 62.0;

  /// The gap between the circle and the edge of the notch, so the bar reads as
  /// a shape the circle sits inside rather than one it is stuck to.
  static const moat = 6.0;

  /// How far the circle rises above the bar.
  static const lift = 26.0;

  /// How much of the bottom of the screen this bar covers.
  ///
  /// Asked for rather than guessed at. A page inside a tab that has an action
  /// bar of its own — the buy button, the checkout button — sits behind this
  /// one unless it moves up by exactly this much, and a number copied into
  /// three files is a number that will be right in two of them.
  static double roomFor(BuildContext context) =>
      bar + MediaQuery.viewPaddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return SizedBox(
      height: bar + lift + bottom,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            top: lift,
            child: CustomPaint(
              painter: _BarPainter(
                bed: context.scheme.surface,
                edge: colors.line,
                notchRadius: disc / 2 + moat,
                shade: Theme.of(context).brightness == Brightness.light
                    ? Colors.black.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),

          Positioned(
            top: lift,
            left: 0,
            right: 0,
            height: bar,
            child: Row(
              children: [
                Expanded(
                  child: _Stop(
                    stop: stops[0],
                    on: chosen == 0,
                    onTap: () => onTap(0),
                  ),
                ),
                Expanded(
                  child: _Stop(
                    stop: stops[1],
                    on: chosen == 1,
                    onTap: () => onTap(1),
                  ),
                ),
                /*
                 * The hole the circle lives in. It takes part in the row so the
                 * four stops divide what is left evenly — spacing them by hand
                 * around a fixed centre goes wrong on the first screen that is
                 * a different width.
                 */
                SizedBox(width: disc + moat * 2 + Gap.sm),
                Expanded(
                  child: _Stop(
                    stop: stops[2],
                    on: chosen == 2,
                    onTap: () => onTap(2),
                  ),
                ),
                Expanded(
                  child: _Stop(
                    stop: stops[3],
                    on: chosen == 3,
                    onTap: () => onTap(3),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 0,
            child: _Disc(stop: centre, on: centreChosen, onTap: onCentre),
          ),
        ],
      ),
    );
  }
}

/// The bar's shape.
class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.bed,
    required this.edge,
    required this.notchRadius,
    required this.shade,
  });

  final Color bed;
  final Color edge;
  final double notchRadius;
  final Color shade;

  /// How much the two ends curve. Large enough to read as a curve rather than a
  /// rounded rectangle, small enough that the outer stops still have room.
  static const _corner = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    final slab = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, size.width, size.height),
          topLeft: const Radius.circular(_corner),
          topRight: const Radius.circular(_corner),
        ),
      );

    final hole = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(size.width / 2, 0), radius: notchRadius),
      );

    final shape = Path.combine(PathOperation.difference, slab, hole);

    canvas
      ..drawShadow(shape, shade, 12, false)
      ..drawPath(shape, Paint()..color = bed)
      ..drawPath(
        shape,
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.bed != bed ||
      old.edge != edge ||
      old.notchRadius != notchRadius ||
      old.shade != shade;
}

/// The raised circle in the notch.
class _Disc extends StatelessWidget {
  const _Disc({required this.stop, required this.on, required this.onTap});

  final BarStop stop;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: stop.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: CurvedBar.disc,
          height: CurvedBar.disc,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            /*
             * Coral when you are somewhere else, turquoise when you are here.
             * Greying it out was the obvious thing and the wrong one: this is
             * the way back to the shop from every corner of the app, and a
             * grey disc reads as a button that has been switched off.
             */
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: on
                  ? const [Palette.brandLift, Palette.brand]
                  : const [Palette.coral, Palette.coralDeep],
            ),
            boxShadow: [
              BoxShadow(
                color: (on ? Palette.brand : Palette.coral).withValues(
                  alpha: 0.42,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            on ? stop.chosenGlyph : stop.glyph,
            size: 27,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.stop, required this.on, required this.onTap});

  final BarStop stop;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final tone = on ? context.scheme.primary : colors.inkFaint;

    final glyph = Icon(
      on ? stop.chosenGlyph : stop.glyph,
      size: 23,
      color: tone,
    );

    return Semantics(
      button: true,
      selected: on,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: SizedBox(
          height: CurvedBar.bar,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /*
               * A dot rather than a filled pill behind the icon. The bar has a
               * circle and two curves in it already; another filled shape makes
               * it busy, and a four-pixel dot says "this one" just as clearly.
               */
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                width: on ? 16 : 0,
                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(
                  color: context.scheme.primary,
                  borderRadius: Corner.pill,
                ),
              ),
              stop.badge > 0
                  ? Badge.count(
                      count: stop.badge,
                      backgroundColor: colors.price,
                      textColor: Colors.white,
                      child: glyph,
                    )
                  : glyph,
              const SizedBox(height: 3),
              Text(
                stop.label,
                style: context.type.labelSmall?.copyWith(
                  color: tone,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
