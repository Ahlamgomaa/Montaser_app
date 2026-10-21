import 'package:flutter/material.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/brand_mark.dart';

/// The coloured head of the two auth screens.
///
/// It curves into the form below on a long sweep rather than a straight edge.
/// The curve is the reason the screen reads as designed instead of assembled:
/// a form under a rectangle is a form, and a form under a wave is a place.
class AuthCrown extends StatelessWidget {
  const AuthCrown({
    required this.title,
    required this.lede,
    this.shopName = 'منتصر',
    this.height = 250,
    super.key,
  });

  final String title;
  final String lede;

  /// The shop's own name, when the caller knows it.
  ///
  /// The auth screens can be reached before the shop front has answered, so
  /// there may be no identity to read yet. The default is the mark's own
  /// wordmark rather than a blank: a sign-in panel with no name on it looks
  /// like a page that failed to load.
  final String shopName;

  final double height;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final top = MediaQuery.viewPaddingOf(context).top;

    return ClipPath(
      clipper: const _SweepClipper(),
      child: Container(
        height: height + top,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Palette.brandLift, Palette.brand, Palette.brandDeep],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: -70, right: -50, child: _Halo(size: 200)),
            const Positioned(bottom: -40, left: -30, child: _Halo(size: 150)),
            Padding(
              padding: EdgeInsets.fromLTRB(Gap.xl, top + Gap.sm, Gap.xl, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const BrandMark(size: 42, plain: true),
                      Gap.w12,
                      Text(
                        shopName,
                        style: type.titleLarge?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  Gap.h24,
                  Text(
                    title,
                    style: type.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  Gap.h4,
                  Text(
                    lede,
                    style: type.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sweep along the bottom.
///
/// Two curves rather than one: the edge drops from the right, bottoms out past
/// the middle, and lifts again on the left. A single symmetrical arc looks like
/// a default; an asymmetric sweep looks like somebody drew it.
class _SweepClipper extends CustomClipper<Path> {
  const _SweepClipper();

  @override
  Path getClip(Size size) {
    final drop = size.height;

    return Path()
      ..lineTo(0, drop - 62)
      ..quadraticBezierTo(
        size.width * 0.22,
        drop + 6,
        size.width * 0.55,
        drop - 26,
      )
      ..quadraticBezierTo(size.width * 0.84, drop - 54, size.width, drop - 96)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

class _Halo extends StatelessWidget {
  const _Halo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.11),
          width: 26,
        ),
      ),
    );
  }
}

/// The mark and a line of words, for places that want them without the panel.
class BrandLine extends StatelessWidget {
  const BrandLine({this.words, super.key});

  final String? words;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const BrandMark(size: 26),
        Gap.w8,
        Flexible(
          child: Text(
            words ?? 'منتصر',
            style: context.type.labelSmall?.copyWith(
              color: context.palette.inkFaint,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
