import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_scope.dart';
import 'widgets/curved_bar.dart';
import 'widgets/leave_guard.dart';

/// The five tabs, and the bar under them.
///
/// A [StatefulShellRoute] keeps each tab's own history, so a customer who
/// browsed three levels into the catalogue, checked the basket and came back
/// finds the catalogue where they left it. Rebuilding a tab from its root
/// instead is the small rudeness that makes an app feel like a website.
class Shell extends StatelessWidget {
  const Shell({required this.navigation, super.key});

  final StatefulNavigationShell navigation;

  /// Where the shop sits among the branches.
  ///
  /// It is branch zero because it is the first thing the app opens, but it is
  /// drawn in the middle of the bar. The two orders are different on purpose,
  /// and [_barToBranch] is the only place that knows it.
  static const _shopBranch = 0;

  /// The four stops either side of the circle, in the order they are drawn.
  static const _barToBranch = <int>[1, 2, 3, 4];

  @override
  Widget build(BuildContext context) {
    final basket = AppScope.basketOf(context);
    final session = AppScope.sessionOf(context);
    final atShop = navigation.currentIndex == _shopBranch;
    final atStop = _barToBranch.indexOf(navigation.currentIndex);

    return LeaveGuard(
      /*
       * Always armed, and it does not ask more often for it.
       *
       * This sits on the shell, outside the branch navigators, so a back press
       * four screens deep is handled by the branch and never reaches here. What
       * does reach here is the press that would close the application — and
       * that is exactly the one worth a question.
       *
       * Armed only on the shop tab before, which meant back on any other tab
       * shut the app without asking. A customer halfway through a basket losing
       * it to a stray gesture is the thing this exists to prevent.
       */
      armed: true,
      child: Scaffold(
        /*
         * The circle rises above the bar, so the body has to run underneath it.
         * Every scrolling page already leaves `Metric.bottomRest` clear at the
         * end for exactly this.
         */
        extendBody: true,
        body: navigation,
        bottomNavigationBar: CurvedBar(
          centre: const BarStop(
            label: 'المتجر',
            glyph: Icons.storefront_outlined,
            chosenGlyph: Icons.storefront_rounded,
          ),
          centreChosen: atShop,
          onCentre: () => _go(_shopBranch),
          chosen: atStop == -1 ? null : atStop,
          onTap: (at) => _go(_barToBranch[at]),
          stops: [
            const BarStop(
              label: 'الأقسام',
              glyph: Icons.grid_view_outlined,
              chosenGlyph: Icons.grid_view_rounded,
            ),
            BarStop(
              label: 'السلة',
              glyph: Icons.shopping_bag_outlined,
              chosenGlyph: Icons.shopping_bag_rounded,
              badge: basket.basket.pieces,
            ),
            BarStop(
              label: 'المفضلة',
              glyph: Icons.favorite_outline_rounded,
              chosenGlyph: Icons.favorite_rounded,
              badge: session.keptCount,
            ),
            const BarStop(
              label: 'حسابي',
              glyph: Icons.person_outline_rounded,
              chosenGlyph: Icons.person_rounded,
            ),
          ],
        ),
      ),
    );
  }

  void _go(int branch) {
    navigation.goBranch(
      branch,
      /*
       * Tapping the tab you are already on returns it to its root. It is the
       * one gesture every customer already knows, and without this it silently
       * does nothing.
       */
      initialLocation: branch == navigation.currentIndex,
    );
  }
}
