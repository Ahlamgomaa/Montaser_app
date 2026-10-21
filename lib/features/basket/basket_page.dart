import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/api/api_failure.dart';
import '../../app/widgets/curved_bar.dart';
import '../../app/routes.dart';
import '../../core/format/money.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/page_crown.dart';
import '../../core/theme/glyphs.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/empty_note.dart';
import '../../core/widgets/part_artwork.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../data/models/basket.dart';
import '../../data/store/basket_store.dart';
import 'widgets/coupon_box.dart';
import 'widgets/totals_card.dart';

/// The basket.
class BasketPage extends StatelessWidget {
  const BasketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.basketOf(context);
    final basket = store.basket;

    return Scaffold(
      body: basket.isEmpty
          ? ListView(
              children: [
                const PageCrown(
                  title: 'السلة',
                  lede: 'ما اخترته قبل إتمام الطلب.',
                  showBack: false,
                ),
                EmptyNote(
                  glyph: Icons.shopping_bag_outlined,
                  title: 'سلتك فارغة',
                  body: 'أضف ما تحتاجه من القطع وسنجهّزه لك.',
                  actionLabel: 'تصفّح القطع',
                  onAction: () => context.go(Path.home),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: Metric.bottomRest),
              children: [
                PageCrown(
                  title: 'السلة',
                  lede: '${basket.pieces} قطعة',
                  showBack: false,
                  actions: [
                    CrownAction(
                      glyph: Icons.delete_outline_rounded,
                      onTap: () => _confirmClear(context, store),
                    ),
                  ],
                ),
                _FreeDeliveryBar(store: store),
                for (final line in basket.lines)
                  _Line(line: line, store: store),
                Gap.h16,
                const Padding(padding: Metric.pagePad, child: CouponBox()),
                Gap.h16,
                Padding(
                  padding: Metric.pagePad,
                  child: TotalsCard(
                    totals: basket.totals,
                    coupon: basket.coupon?.code,
                    shippingKnown: basket.shipping != null,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: basket.isEmpty ? null : _CheckoutBar(basket: basket),
    );
  }

  Future<void> _confirmClear(BuildContext context, BasketStore store) async {
    final sure = await showDialog<bool>(
      context: context,
      /* The dialog's own context: `(_)` here popped the page instead. */
      builder: (dialog) => AlertDialog(
        title: const Text('إفراغ السلة؟'),
        content: const Text('ستُحذف كل القطع التي أضفتها. لا يمكن التراجع.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.danger,
            ),
            child: const Text('إفراغ'),
          ),
        ],
      ),
    );

    if (sure ?? false) {
      store.clear();
    }
  }
}

/// How far the basket is from free delivery.
///
/// Shown as a bar rather than a sentence because the distance is the point: a
/// customer 800 pounds short behaves differently from one 8,000 short, and only
/// a bar says which they are at a glance.
class _FreeDeliveryBar extends StatelessWidget {
  const _FreeDeliveryBar({required this.store});

  final BasketStore store;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    /*
     * How far off free delivery, as the server worked it out. Null means the
     * shop makes no such offer — which is different from zero, and drawing a
     * bar for it would invent a promise nobody made.
     */
    final short = store.shortOfFreeShipping;

    if (short == null) {
      return const SizedBox.shrink();
    }

    final earned = short <= 0;
    final goods = store.basket.totals.goods;

    /*
     * Worked back from the two numbers the server did send: what is in the
     * basket, and what is still needed. Their sum is the threshold, so the bar
     * follows a figure set on the shipping page rather than one written here.
     */
    final threshold = goods + short;
    final progress = earned || threshold <= 0
        ? 1.0
        : (goods / threshold).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.sm),
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: earned ? colors.successWash : context.scheme.surface,
        borderRadius: Corner.rMd,
        border: Border.all(color: earned ? colors.success : colors.line),
      ),
      child: Row(
        children: [
          Icon(
            earned
                ? Icons.local_shipping_rounded
                : Icons.local_shipping_outlined,
            size: 20,
            color: earned ? colors.success : colors.inkFaint,
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earned
                      ? 'حصلت على شحن مجاني.'
                      : 'أضف ${Money.of(short)} لتحصل على شحن مجاني.',
                  style: context.type.labelMedium?.copyWith(
                    color: earned ? colors.success : null,
                  ),
                ),
                if (!earned) ...[
                  Gap.h8,
                  ClipRRect(
                    borderRadius: Corner.pill,
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: colors.line,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One line of the basket.
class _Line extends StatelessWidget {
  const _Line({required this.line, required this.store});

  final BasketLine line;
  final BasketStore store;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Container(
      margin: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.sm),
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Corner.rLg,
        border: Border.all(color: colors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push(Path.toPart(line.slug ?? '')),
            child: PartArtwork(
              seed: line.itemId,
              imageUrl: line.imageUrl,
              glyph: Glyphs.aisleNamed(line.aisle),
              size: 72,
              radius: Corner.rMd,
              dense: true,
            ),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  style: type.titleSmall?.copyWith(height: 1.45),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  line.brand == null ? line.code : '${line.brand} · ${line.code}',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: type.labelSmall?.copyWith(color: colors.inkFaint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap.h12,
                Row(
                  children: [
                    QuantityStepper(
                      quantity: line.quantity,
                      ceiling: line.free.toInt(),
                      dense: true,
                      onRemoveAtOne: () => store.remove(line.itemId),
                      onChanged: (next) async {
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          await store.setQuantity(line.itemId, next);
                        } on ApiFailure catch (fault) {
                          messenger
                            ..clearSnackBars()
                            ..showSnackBar(
                              SnackBar(content: Text(fault.message)),
                            );
                        }
                      },
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Money.of(line.lineTotal),
                          style: type.titleSmall?.copyWith(color: colors.price),
                        ),
                        if (line.quantity > 1)
                          Text(
                            '${Money.of(line.unitPrice)} / ${line.unit}',
                            style: type.labelSmall?.copyWith(
                              color: colors.inkFaint,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The bar that carries on to the checkout.
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.basket});

  final Basket basket;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Container(
      padding: EdgeInsets.fromLTRB(
        Gap.lg,
        Gap.md,
        Gap.lg,
        Gap.md + CurvedBar.roomFor(context),
      ),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الإجمالي',
                style: context.type.labelSmall?.copyWith(
                  color: colors.inkFaint,
                ),
              ),
              Text(
                Money.of(basket.totals.total),
                style: context.type.titleLarge?.copyWith(color: colors.price),
              ),
            ],
          ),
          Gap.w16,
          Expanded(
            child: FilledButton(
              onPressed: () => context.push(Path.checkout),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('إتمام الطلب (${basket.pieces})'),
                  Gap.w8,
                  const Icon(Icons.arrow_back_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
