import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/widgets/loader.dart';
import '../../../data/models/catalogue.dart';
import 'part_card.dart';

/// A horizontal run of product cards.
///
/// `ListView.builder` inside a fixed height rather than a `Row` of everything:
/// a shelf of twelve builds three and stops until the customer scrolls, and the
/// height is fixed because a horizontal list has no other way to know how tall
/// it should be.
class PartShelf extends StatelessWidget {
  const PartShelf({required this.parts, super.key});

  final List<Part> parts;

  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: PartCard.tall,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: Metric.pagePad,
        itemCount: parts.length,
        cacheExtent: 600,
        separatorBuilder: (_, _) => Gap.w12,
        itemBuilder: (context, at) =>
            LivePartCard(part: parts[at], width: 196),
      ),
    );
  }
}

/// A product card wired to the stores.
///
/// Every place that shows a part — the shop front, the grid, the wish list, the
/// related row on a product page — uses this rather than assembling the same
/// four callbacks again. Four copies of "what happens when somebody taps add"
/// is four places to fix the day it should also do something else.
class LivePartCard extends StatelessWidget {
  const LivePartCard({required this.part, this.width, super.key});

  final Part part;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final basket = AppScope.basketOf(context);
    final session = AppScope.sessionOf(context);

    return PartCard(
      part: part,
      width: width,
      inBasket: basket.quantityOf(part.id),
      isKept: session.keeps(part.id),
      /*
       * Only offered to somebody signed in. The wish list lives on the server
       * against an account, so a heart on a signed-out screen would be a button
       * that cannot do anything — better to leave it off and let the sign-in
       * screen make the case.
       */
      onKeep: session.isSignedIn ? () => _keep(context) : null,
      onOpen: () => context.push(Path.toPart(part.slug)),
      onAdd: () => _add(context),
    );
  }

  Future<void> _keep(BuildContext context) async {
    try {
      final kept = await AppScope.session(context).toggleKept(part.id);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(kept ? 'أُضيفت إلى مفضلتك.' : 'أُزيلت من مفضلتك.'),
          ),
        );
    } catch (fault) {
      if (context.mounted) {
        sayFailure(context, fault);
      }
    }
  }

  Future<void> _add(BuildContext context) async {
    /*
     * Buying needs an account: an order carries an address and a telephone
     * number, and both have to belong to somebody the shop can name. Said here,
     * at the tap, rather than at the checkout — being sent to sign in after
     * filling a basket is the rudest moment an app has.
     */
    if (!AppScope.session(context).isSignedIn) {
      final signedIn = await context.push<bool>(Path.signIn);

      if (signedIn != true || !context.mounted) {
        return;
      }
    }

    try {
      await AppScope.basket(context).add(part.id);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('أُضيفت ${part.name} إلى السلة.'),
            action: SnackBarAction(
              label: 'السلة',
              onPressed: () => context.go(Path.basket),
            ),
          ),
        );
    } catch (fault) {
      if (context.mounted) {
        sayFailure(context, fault);
      }
    }
  }
}
