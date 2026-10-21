import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/dimens.dart';
import '../theme/palette.dart';
import 'brand_mark.dart';

/// The coloured head every page wears.
///
/// One widget rather than a plain [AppBar] on each screen, because a shop that
/// changes character between its front and its inside is a shop the customer
/// stops trusting halfway through. The mark, the curve and the gradient are the
/// same everywhere; only the words and the buttons change.
///
/// It is a normal widget rather than a `PreferredSizeWidget`, so it scrolls
/// away with the page instead of pinning. On a screen this colourful a header
/// that stays put takes a third of the display and never gives it back.
class PageCrown extends StatelessWidget {
  const PageCrown({
    required this.title,
    this.lede,
    this.actions = const [],
    this.trailing,
    this.showBack = true,
    super.key,
  });

  final String title;
  final String? lede;

  /// Round buttons on the far side of the title.
  final List<CrownAction> actions;

  /// Anything that should sit under the title, inside the colour — a search
  /// box, a row of filters. It rides the curve rather than starting the white
  /// part of the page.
  final Widget? trailing;

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final top = MediaQuery.viewPaddingOf(context).top;

    return ClipPath(
      clipper: const CrownSweep(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          Gap.lg,
          top + Gap.sm,
          Gap.lg,
          /*
           * Deep enough that the sweep cuts through empty colour rather than
           * through the last line of text.
           */
          trailing == null ? Gap.xxl + Gap.md : Gap.xl,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Palette.brandLift, Palette.brand, Palette.brandDeep],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (showBack && context.canPop()) ...[
                  _Round(
                    glyph: Icons.arrow_forward_rounded,
                    onTap: context.pop,
                  ),
                  Gap.w12,
                ] else ...[
                  const BrandMark(size: 36, plain: true),
                  Gap.w12,
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: type.titleLarge?.copyWith(
                          color: Colors.white,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (lede != null)
                        Text(
                          lede!,
                          style: type.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                            height: 1.35,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                for (final one in actions) ...[
                  Gap.w8,
                  _Round(glyph: one.glyph, onTap: one.onTap, badge: one.badge),
                ],
              ],
            ),
            if (trailing != null) ...[Gap.h16, trailing!],
          ],
        ),
      ),
    );
  }
}

/// A button on the crown.
@immutable
class CrownAction {
  const CrownAction({required this.glyph, required this.onTap, this.badge = 0});

  final IconData glyph;
  final VoidCallback onTap;
  final int badge;
}

/// The sweep along the bottom of the crown.
///
/// Two curves rather than one: the edge drops from the right, bottoms out past
/// the middle and lifts again on the left. A single symmetrical arc looks like
/// a default; an asymmetric sweep looks like somebody drew it.
///
/// Shared by the crown and the auth panel so the same curve appears throughout
/// — two hand-tuned bezier sets would be two slightly different shapes, and the
/// eye notices that long before it can say why.
class CrownSweep extends CustomClipper<Path> {
  const CrownSweep();

  @override
  Path getClip(Size size) {
    final drop = size.height;

    return Path()
      ..lineTo(0, drop - 34)
      ..quadraticBezierTo(
        size.width * 0.22,
        drop + 4,
        size.width * 0.55,
        drop - 14,
      )
      ..quadraticBezierTo(size.width * 0.84, drop - 30, size.width, drop - 54)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

class _Round extends StatelessWidget {
  const _Round({required this.glyph, required this.onTap, this.badge = 0});

  final IconData glyph;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(glyph, size: 20, color: Colors.white),
        ),
      ),
    );

    if (badge == 0) {
      return button;
    }

    return Badge.count(
      count: badge,
      backgroundColor: Palette.coral,
      textColor: Colors.white,
      child: button,
    );
  }
}
