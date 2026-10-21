import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/widgets/curved_bar.dart';
import '../../app/routes.dart';
import '../../core/format/money.dart';
import '../../core/theme/dimens.dart';
import '../../core/theme/glyphs.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/empty_note.dart';
import '../../core/widgets/part_artwork.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/price_line.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../core/widgets/section_head.dart';
import '../../core/widgets/loader.dart';
import '../../data/api/api_failure.dart';
import '../../data/models/catalogue.dart';
import '../catalogue/widgets/part_card.dart';
import 'widgets/spec_table.dart';
import 'widgets/verdict_list.dart';

/// One part, in full.
class PartPage extends StatefulWidget {
  const PartPage({required this.slug, super.key});

  final String slug;

  @override
  State<PartPage> createState() => _PartPageState();
}

class _PartPageState extends State<PartPage> {
  late Future<PartAndKin> _part;

  @override
  void initState() {
    super.initState();
    _part = AppScope.shop.catalogue.part(widget.slug);
  }

  void _again() {
    setState(() => _part = AppScope.shop.catalogue.part(widget.slug));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Loader<PartAndKin>(
        future: _part,
        onRetry: _again,
        /*
         * A part that is not there is not a network fault: it has been taken
         * off the store, or the link came from somewhere stale. "Try again"
         * would give the same answer, so the way out is the aisle it was in.
         */
        onMissing: (context) => EmptyNote(
          glyph: Icons.help_outline_rounded,
          title: 'لم نجد هذه القطعة',
          body: 'قد تكون سُحبت من العرض. تصفّح القسم لعلّ فيه بديلاً.',
          actionLabel: 'تصفّح القطع',
          onAction: () => context.pushReplacement(Path.browse),
        ),
        builder: (context, found) => _Part(found: found),
      ),
    );
  }
}

/// The part, once it has arrived.
class _Part extends StatefulWidget {
  const _Part({required this.found});

  final PartAndKin found;

  @override
  State<_Part> createState() => _PartState();
}

class _PartState extends State<_Part> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final part = widget.found.part;
    final session = AppScope.sessionOf(context);
    final soldOut = part.availability == Availability.none;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _Cover(part: part, isKept: session.keeps(part.id)),
          SliverToBoxAdapter(child: _Headline(part: part)),
          SliverToBoxAdapter(child: _Summary(part: part)),
          SliverToBoxAdapter(child: SpecTable(specs: part.specs)),

          const SliverToBoxAdapter(
            child: SectionHead(
              title: 'التقييمات',
              lede: 'آراء من اشتروا فعلاً.',
            ),
          ),
          SliverToBoxAdapter(
            child: VerdictList(
              itemId: part.id,
              verdicts: widget.found.reviews,
              rating: part.rating,
              count: part.ratingCount,
            ),
          ),

          const SliverToBoxAdapter(
            child: SectionHead(title: 'قطع ذات صلة', lede: 'من القسم نفسه.'),
          ),
          SliverToBoxAdapter(child: _Related(related: widget.found.related)),

          const SliverToBoxAdapter(child: SizedBox(height: Gap.xxl)),
        ],
      ),
      bottomNavigationBar: _BuyBar(
        part: part,
        quantity: _quantity,
        soldOut: soldOut,
        onQuantity: (next) => setState(() => _quantity = next),
      ),
    );
  }
}

/// The artwork, and the bar that collapses onto it.
class _Cover extends StatelessWidget {
  const _Cover({required this.part, required this.isKept});

  final Part part;
  final bool isKept;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: context.palette.canvas,
      actions: [
        IconButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);

            try {
              final now = await AppScope.session(context).toggleKept(part.id);

              messenger
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      now ? 'أُضيفت إلى مفضلتك.' : 'أُزيلت من مفضلتك.',
                    ),
                  ),
                );
            } on ApiFailure catch (fault) {
              messenger
                ..clearSnackBars()
                ..showSnackBar(SnackBar(content: Text(fault.message)));
            }
          },
          icon: Icon(
            isKept ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            color: isKept ? context.palette.danger : null,
          ),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                const SnackBar(content: Text('نُسخ رابط القطعة.')),
              );
          },
          icon: const Icon(Icons.ios_share_rounded),
        ),
        Gap.w4,
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.huge, Gap.lg, 0),
          child: _Gallery(part: part),
        ),
      ),
    );
  }
}

/// Every picture the shop has of the part, swiped through.
///
/// A part is bought on how it looks from more than one angle — a fitting, a
/// thread, a plate with a model number stamped on it — and the shop already
/// keeps them all. Showing only the first was throwing away the ones that
/// answer the question the customer actually has.
///
/// One picture draws as one picture, without dots underneath: a page indicator
/// over a single image invites a swipe that does nothing.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.part});

  final Part part;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _pages = PageController();
  int _at = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final part = widget.part;

    /*
     * The gallery where the shop sent one, and the single picture otherwise —
     * a list-only page would draw nothing for a part photographed once.
     */
    final pictures = part.images.isNotEmpty
        ? part.images
        : <String>[if (part.imageUrl != null) part.imageUrl!];

    if (pictures.length <= 1) {
      return PartArtwork(
        seed: part.id,
        imageUrl: pictures.isEmpty ? null : pictures.first,
        glyph: Glyphs.aisleNamed(part.aisle),
        radius: Corner.rXl,
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pages,
          itemCount: pictures.length,
          onPageChanged: (at) => setState(() => _at = at),
          itemBuilder: (context, at) => PartArtwork(
            seed: part.id,
            imageUrl: pictures[at],
            glyph: Glyphs.aisleNamed(part.aisle),
            radius: Corner.rXl,
          ),
        ),
        PositionedDirectional(
          bottom: Gap.md,
          start: 0,
          end: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var at = 0; at < pictures.length; at++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: at == _at ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: at == _at
                        ? context.scheme.primary
                        : context.palette.line,
                    borderRadius: Corner.pill,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Name, number, price, stock — the four things read first.
class _Headline extends StatelessWidget {
  const _Headline({required this.part});

  final Part part;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push(
                  Path.toBrowse(makerId: part.brandId, title: part.brand),
                ),
                child: Text(
                  part.brand ?? '',
                  textDirection: TextDirection.ltr,
                  style: type.labelMedium?.copyWith(
                    color: context.scheme.primary,
                  ),
                ),
              ),
              Gap.w8,
              Text('·', style: type.labelMedium?.copyWith(color: colors.line)),
              Gap.w8,
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push(
                    Path.toBrowse(aisleId: part.aisleId, title: part.aisle),
                  ),
                  child: Text(
                    part.aisle,
                    style: type.labelMedium?.copyWith(color: colors.inkSoft),
                  ),
                ),
              ),
            ],
          ),
          Gap.h8,
          Text(part.name, style: type.headlineSmall),
          Gap.h8,
          /*
           * The part number is selectable. It is the one string on this page a
           * customer might want to copy — into a message to a colleague, into a
           * search on another shop — and making them retype it is a small
           * insult with a large chance of a typo.
           */
          Row(
            children: [
              Icon(Icons.tag_rounded, size: 15, color: colors.inkFaint),
              Gap.w4,
              Expanded(
                child: SelectableText(
                  part.code,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: type.labelMedium?.copyWith(color: colors.inkSoft),
                ),
              ),
            ],
          ),
          Gap.h16,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PriceLine(
                price: part.price,
                unit: part.unit,
                wasPrice: part.wasPrice,
                large: true,
              ),
              const Spacer(),
              StockPill(free: part.free),
            ],
          ),
          if (part.rating != null) ...[
            Gap.h12,
            StarRow(
              rating: part.rating!,
              count: part.ratingCount,
              size: 17,
            ),
          ],
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.part});

  final Part part;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الوصف', style: context.type.titleSmall),
          Gap.h8,
          Text(part.summary ?? '', style: context.type.bodyMedium),
        ],
      ),
    );
  }
}

/// Put a related part in the basket, and say what happened.
Future<void> _addRelated(BuildContext context, Part part) async {
  final messenger = ScaffoldMessenger.of(context);

  String said;

  try {
    await AppScope.basket(context).add(part.id);
    said = 'أُضيفت إلى السلة.';
  } on ApiFailure catch (fault) {
    /* The server's own sentence: "only two left" is something to act on. */
    said = fault.message;
  }

  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(said)));
}

class _Related extends StatelessWidget {
  const _Related({required this.related});

  final List<Part> related;

  @override
  Widget build(BuildContext context) {
    final near = related;

    return SizedBox(
      height: PartCard.tall,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: Metric.pagePad,
        itemCount: near.length,
        separatorBuilder: (_, _) => Gap.w12,
        itemBuilder: (context, at) {
          final other = near[at];

          return PartCard(
            part: other,
            width: 196,
            inBasket: AppScope.basketOf(context).quantityOf(other.id),
            onOpen: () => context.pushReplacement(Path.toPart(other.slug)),
            onAdd: () => _addRelated(context, other),
          );
        },
      ),
    );
  }
}

/// The bar that stays put while everything else scrolls.
///
/// The count sits beside the button rather than inside the page, so a customer
/// who has read to the bottom of the reviews does not have to scroll back up to
/// order three of them.
class _BuyBar extends StatelessWidget {
  const _BuyBar({
    required this.part,
    required this.quantity,
    required this.soldOut,
    required this.onQuantity,
  });

  final Part part;
  final int quantity;
  final bool soldOut;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Container(
      padding: EdgeInsets.fromLTRB(
        Gap.lg,
        Gap.md,
        Gap.lg,
        /*
         * Clear of the tab bar underneath. This page keeps its tabs — a
         * customer looking at a compressor is still shopping — so the buy bar
         * has to stand on top of the bar rather than behind it.
         */
        Gap.md + CurvedBar.roomFor(context),
      ),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: soldOut
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('نفدت الكمية', style: context.type.titleSmall),
                      Text(
                        'أخبرنا لنبلغك عند توفّرها.',
                        style: context.type.labelSmall?.copyWith(
                          color: colors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                Gap.w12,
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('سنبلغك فور توفّر القطعة.'),
                        ),
                      );
                  },
                  icon: const Icon(Icons.notifications_none_rounded, size: 18),
                  label: const Text('أبلغني'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                QuantityStepper(
                  quantity: quantity,
                  ceiling: part.free.toInt(),
                  onChanged: onQuantity,
                ),
                Gap.w12,
                Expanded(
                  child: FilledButton(
                    onPressed: () => _addToBasket(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_shopping_cart_rounded, size: 18),
                        Gap.w8,
                        Text('أضف — ${Money.of(part.price * quantity)}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Put this part in the basket, and say what happened either way.
  ///
  /// The refusal is the server's own sentence — "only two left" is something a
  /// customer can act on, and a wording invented here would be a second answer
  /// to a question the shop has already answered on its website.
  Future<void> _addToBasket(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      await AppScope.basket(context).add(part.id, quantity: quantity);
    } on ApiFailure catch (fault) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(fault.message)));

      return;
    }

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('أُضيف $quantity ${part.unit} إلى السلة.'),
          action: SnackBarAction(
            label: 'السلة',
            onPressed: () => router.go(Path.basket),
          ),
        ),
      );
  }
}
