import 'package:flutter/material.dart';

import '../format/money.dart';
import '../theme/dimens.dart';
import '../theme/palette.dart';

/// A price, with the old one beside it when there is one.
///
/// The unit is part of the price rather than a detail printed elsewhere. In
/// this trade the difference between a price per metre and a price per roll is
/// the difference between an order and a complaint.
///
/// Everything here is wrapped so it can give way. A price line lives inside a
/// product card two of which fit across a small phone, and «١٢٬٤٠٠ ج.م / وحدة»
/// beside a struck-out «١٣٬٩٠٠ ج.م» is wider than that card at any font size
/// worth reading. Left rigid it overflows; given room to shrink, the unit
/// ellipsises and the number — the part nobody may lose — keeps its space.
class PriceLine extends StatelessWidget {
  const PriceLine({
    required this.price,
    required this.unit,
    this.wasPrice,
    this.large = false,
    super.key,
  });

  final double price;
  final String unit;
  final double? wasPrice;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;
    final onOffer = wasPrice != null && wasPrice! > price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                Money.bare(price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (large ? type.headlineSmall : type.titleMedium)
                    ?.copyWith(color: colors.price, letterSpacing: -0.2),
              ),
            ),
            Gap.w4,
            Text(
              Money.unit,
              style: (large ? type.titleSmall : type.labelSmall)?.copyWith(
                color: colors.price,
              ),
            ),
            Gap.w4,
            /*
             * The first thing to give way. A customer who can see the price
             * but not whether it is per metre will ask; one who can see
             * neither has nothing to go on.
             */
            Flexible(
              child: Text(
                '/ $unit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.labelSmall?.copyWith(color: colors.inkFaint),
              ),
            ),
          ],
        ),
        if (onOffer) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  Money.of(wasPrice!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.labelSmall?.copyWith(
                    color: colors.inkFaint,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: colors.inkFaint,
                  ),
                ),
              ),
              Gap.w8,
              _SavingChip(was: wasPrice!, now: price),
            ],
          ),
        ],
      ],
    );
  }
}

/// How much came off, as a share.
class _SavingChip extends StatelessWidget {
  const _SavingChip({required this.was, required this.now});

  final double was;
  final double now;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colors.dangerWash,
        borderRadius: Corner.rSm,
      ),
      child: Text(
        Money.discountShare(was: was, now: now),
        style: context.type.labelSmall?.copyWith(
          color: colors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
