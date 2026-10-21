import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/page_crown.dart';
import '../../../data/models/catalogue.dart';

/// The top of the shop.
///
/// A coloured panel with a curved foot, and the search box straddling its edge.
/// The overlap is the whole idea: it ties the header to the page below instead
/// of leaving a hard band across the top, and it puts the one control everybody
/// reaches for first exactly where the thumb already is.
class ShopHeader extends StatelessWidget {
  const ShopHeader({required this.identity, super.key});

  /// Who the shop says it is. Read from `home` rather than written here, so
  /// renaming the shop is a settings change on the website and not a release
  /// on the store.
  final ShopIdentity identity;

  /// How far the search box hangs below the panel. The page above allows for it
  /// so the first section does not start underneath the box.
  static const overhang = 30.0;

  @override
  Widget build(BuildContext context) {
    final session = AppScope.sessionOf(context);
    final shopper = session.shopper;
    final type = context.type;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: const CrownSweep(),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              Gap.lg,
              MediaQuery.viewPaddingOf(context).top + Gap.md,
              Gap.lg,
              overhang + Gap.lg,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Palette.brandLift, Palette.brand, Palette.brandDeep],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const BrandMark(size: 40, plain: true),
                    Gap.w12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            identity.isKnown ? identity.name : 'منتصر',
                            style: type.titleLarge?.copyWith(
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          if (identity.tagline.isNotEmpty)
                            Text(
                              identity.tagline,
                              style: type.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    _Action(
                      glyph: Icons.notifications_none_rounded,
                      onTap: () {
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                            const SnackBar(content: Text('لا إشعارات جديدة.')),
                          );
                      },
                    ),
                    Gap.w8,
                    _Action(
                      glyph: shopper == null
                          ? Icons.login_rounded
                          : Icons.receipt_long_rounded,
                      onTap: () => context.push(
                        shopper == null ? Path.signIn : Path.orders,
                      ),
                    ),
                  ],
                ),
                Gap.h16,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    shopper == null
                        ? 'ابحث عن القطعة التي تحتاجها، أو تصفّح الأقسام.'
                        : 'أهلاً ${shopper.name.split(' ').first} — ماذا تحتاج اليوم؟',
                    style: type.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                /*
                 * Clear of the search field, which is pinned to the foot of
                 * this panel and rides up over the curve. Without this the line
                 * above sat on the field rather than over it.
                 */
                Gap.h24,
              ],
            ),
          ),
        ),

        /*
         * Straddling the curved foot. Given a shadow of its own so it reads as
         * sitting on top of the panel rather than punched into it.
         */
        PositionedDirectional(
          start: Gap.lg,
          end: Gap.lg,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: Corner.pill,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AppSearchField(
              readOnly: true,
              onTap: () => context.push(Path.search),
            ),
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.glyph, required this.onTap});

  final IconData glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
  }
}
