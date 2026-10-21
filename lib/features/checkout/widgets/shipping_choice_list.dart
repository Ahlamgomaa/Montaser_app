import 'package:flutter/material.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/basket.dart';

/// Choosing how it travels.
class ShippingChoiceList extends StatelessWidget {
  const ShippingChoiceList({
    required this.choices,
    required this.chosen,
    required this.onChoose,
    this.freeEarned = false,
    super.key,
  });

  final List<ShippingChoice> choices;
  final ShippingChoice? chosen;
  final ValueChanged<ShippingChoice> onChoose;

  /// Whether the basket already earned free delivery. When it has, the charge
  /// is struck through rather than hidden — a customer should see the fifty
  /// pounds they are not paying.
  final bool freeEarned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('طريقة التوصيل', style: context.type.titleSmall),
          Gap.h8,
          for (final choice in choices) ...[
            _ChoiceCard(
              choice: choice,
              chosen: choice.id == chosen?.id,
              freeEarned: freeEarned,
              onTap: () => onChoose(choice),
            ),
            Gap.h8,
          ],
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.choice,
    required this.chosen,
    required this.freeEarned,
    required this.onTap,
  });

  final ShippingChoice choice;
  final bool chosen;
  final bool freeEarned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;
    final nowFree = choice.isFree || freeEarned;

    return Material(
      color: context.scheme.surface,
      borderRadius: Corner.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(Gap.lg),
          decoration: BoxDecoration(
            borderRadius: Corner.rLg,
            border: Border.all(
              color: chosen ? context.scheme.primary : colors.line,
              width: chosen ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                chosen
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: chosen ? context.scheme.primary : colors.inkFaint,
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(choice.name, style: type.titleSmall),
                    /* Shown only where the shop gave one. A blank line under
                       every method is a gap the eye reads as missing. */
                    if (choice.estimate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        choice.estimate!,
                        style: type.bodySmall?.copyWith(color: colors.inkFaint),
                      ),
                    ],
                  ],
                ),
              ),
              Gap.w12,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (nowFree)
                    Text(
                      'مجاني',
                      style: type.labelMedium?.copyWith(color: colors.success),
                    )
                  else
                    Text(
                      Money.of(choice.charge),
                      style: type.labelMedium?.copyWith(color: colors.price),
                    ),
                  if (freeEarned && !choice.isFree)
                    Text(
                      Money.of(choice.charge),
                      style: type.labelSmall?.copyWith(
                        color: colors.inkFaint,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: colors.inkFaint,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
