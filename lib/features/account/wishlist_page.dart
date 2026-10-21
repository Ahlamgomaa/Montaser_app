import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/routes.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/empty_note.dart';
import '../../core/widgets/loader.dart';
import '../../core/widgets/page_crown.dart';
import '../../data/api/api_failure.dart';
import '../../data/models/catalogue.dart';
import '../catalogue/widgets/part_card.dart';

/// What the customer kept for later.
///
/// Asked of the server rather than worked out here. The list belongs to the
/// account, not to this handset: somebody who keeps a part on their phone and
/// then signs in on a tablet is looking for it there, and a list filtered out
/// of whatever the catalogue happened to load would show them only the parts
/// this screen had already seen.
class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  late Future<List<Part>> _kept;

  @override
  void initState() {
    super.initState();
    _kept = AppScope.shop.account.wishlist();
  }

  void _again() {
    setState(() => _kept = AppScope.shop.account.wishlist());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _again(),
        child: Loader<List<Part>>(
          future: _kept,
          onRetry: _again,
          builder: (context, kept) => _Kept(kept: kept, onChanged: _again),
        ),
      ),
    );
  }
}

/// The saved parts, once they have arrived.
class _Kept extends StatelessWidget {
  const _Kept({required this.kept, required this.onChanged});

  final List<Part> kept;

  /// Called when a part stops being kept, so the list is asked for again.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final session = AppScope.sessionOf(context);
    final basket = AppScope.basketOf(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageCrown(
            title: 'المفضلة',
            lede: kept.isEmpty
                ? 'ما تحفظه للرجوع إليه لاحقاً.'
                : '${kept.length} قطعة محفوظة',
            showBack: false,
          ),
        ),
        if (kept.isEmpty)
          SliverToBoxAdapter(
            child: EmptyNote(
              glyph: Icons.favorite_outline_rounded,
              title: 'مفضلتك فارغة',
              body: 'اضغط على القلب في أي قطعة لتحفظها هنا وتعود إليها لاحقاً.',
              actionLabel: 'تصفّح القطع',
              onAction: () => context.go(Path.home),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Gap.lg,
              Gap.md,
              Gap.lg,
              Metric.bottomRest,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 230,
                mainAxisSpacing: Gap.md,
                crossAxisSpacing: Gap.md,
                mainAxisExtent: PartCard.tall,
              ),
              itemCount: kept.length,
              itemBuilder: (context, at) {
                final part = kept[at];

                return PartCard(
                  part: part,
                  isKept: session.keeps(part.id),
                  inBasket: basket.quantityOf(part.id),
                  onKeep: () async {
                    await session.toggleKept(part.id);

                    /*
                     * Asked for again rather than removed from the list here.
                     * This screen is the kept list itself, so a part that stops
                     * being kept has to leave it — and the server is what
                     * decides what is on it.
                     */
                    onChanged();
                  },
                  onOpen: () => context.push(Path.toPart(part.slug)),
                  onAdd: () => _add(context, part),
                );
              },
            ),
          ),
      ],
    );
  }

  /// Put one in the basket, and say what happened either way.
  Future<void> _add(BuildContext context, Part part) async {
    final messenger = ScaffoldMessenger.of(context);

    String said;

    try {
      await AppScope.basket(context).add(part.id);
      said = 'أُضيفت إلى السلة.';
    } on ApiFailure catch (fault) {
      /*
       * The server's own words. "Only two left" is something a customer can
       * act on; "could not add" is not.
       */
      said = fault.message;
    }

    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(said)));
  }
}
