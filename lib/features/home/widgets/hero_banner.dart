import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/catalogue.dart';

/// The banner at the top of the shop front.
///
/// One offer, said plainly, with somewhere to go. The carousel that usually
/// sits here shows five things and gets read as none: it moves while people are
/// reading, and the ones who wait for the offer they glimpsed have to watch it
/// come round again.
class HeroBanner extends StatelessWidget {
  const HeroBanner({required this.slide, super.key});

  /// What the shop is promoting, in the shop's own words. Nothing about this
  /// offer is written into the app — change it on the website and the app says
  /// the new thing on its next launch.
  final Slide slide;

  @override
  Widget build(BuildContext context) {
    final type = context.type;

    return Padding(
      padding: Metric.pagePad,
      child: Material(
        borderRadius: Corner.rXl,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              /*
               * Coral, not turquoise. The header above it is already the brand
               * colour, and two gradients of the same hue stacked read as one
               * very tall header with a seam in it. Warm against cool is what
               * makes the page look composed rather than merely coloured.
               */
              colors: [Palette.amber, Palette.coral, Palette.coralDeep],
            ),
          ),
          child: InkWell(
            onTap: () => context.push(Path.toBrowse(title: slide.title)),
            child: Stack(
              children: [
                /*
                 * The decoration is painted, not an asset. Two soft rings and a
                 * grid weigh nothing, scale to any screen, and cannot arrive
                 * late on a slow connection the way a background image can.
                 */
                Positioned(
                  top: -70,
                  left: -50,
                  child: _Ring(size: 210, alpha: 0.10),
                ),
                Positioned(
                  bottom: -90,
                  left: 40,
                  child: _Ring(size: 170, alpha: 0.07),
                ),
                Padding(
                  padding: const EdgeInsets.all(Gap.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Gap.md,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: Corner.pill,
                        ),
                        child: Text(
                          slide.actionLabel ?? 'عرض',
                          style: type.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Gap.h16,
                      /*
                       * The shop's own words, from the banner it set up in the
                       * panel. These two lines used to be written here — so the
                       * app promised free delivery over ten thousand pounds
                       * whatever the shop's shipping rules actually said, and
                       * the promise could not be corrected without a release.
                       */
                      Text(
                        slide.title,
                        style: type.headlineSmall?.copyWith(
                          color: Colors.white,
                          height: 1.55,
                        ),
                      ),
                      if ((slide.lede ?? '').isNotEmpty) ...[
                        Gap.h8,
                        Text(
                          slide.lede!,
                          style: type.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                      Gap.h24,
                      Row(
                        children: [
                          FilledButton(
                            onPressed: () =>
                                context.push(Path.toBrowse(title: slide.title)),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Palette.coralDeep,
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: Gap.xl,
                              ),
                            ),
                            child: const Text('تسوّق الآن'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: alpha),
          width: 28,
        ),
      ),
    );
  }
}
