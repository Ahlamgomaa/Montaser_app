import 'package:flutter/material.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/glyphs.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/basket.dart';

/// Choosing how to pay.
///
/// The methods come from the checkout call, in the shop's own order and with
/// the shop's own words. A list written here would go on offering a way to pay
/// that the shop had switched off — which is discovered at the worst possible
/// moment, by a customer who has already filled in an address.
///
/// One that is not available is shown and not offered, rather than hidden.
/// "Card payment — temporarily unavailable" answers the question; a method that
/// simply is not there leaves somebody looking for it.
class PayChoice extends StatelessWidget {
  const PayChoice({
    required this.methods,
    required this.chosen,
    required this.onChoose,
    super.key,
  });

  final List<PayChoiceOption> methods;

  /// The value of the chosen method, or null before anything is chosen.
  final String? chosen;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('طريقة الدفع', style: context.type.titleSmall),
          Gap.h8,
          for (final how in methods) ...[
            _PayCard(
              how: how,
              chosen: how.value == chosen,
              onTap: how.available ? () => onChoose(how.value) : null,
            ),
            Gap.h8,
          ],
        ],
      ),
    );
  }
}

class _PayCard extends StatelessWidget {
  const _PayCard({
    required this.how,
    required this.chosen,
    required this.onTap,
  });

  final PayChoiceOption how;
  final bool chosen;

  /// Null where the shop has this method switched off.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.canvas,
                  borderRadius: Corner.rSm,
                ),
                child: Icon(
                  Glyphs.payment(how.value),
                  size: 19,
                  color: colors.inkSoft,
                ),
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      how.label,
                      style: type.titleSmall?.copyWith(
                        color: how.available ? null : colors.inkFaint,
                      ),
                    ),
                    if (how.hint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        how.hint!,
                        style: type.bodySmall?.copyWith(color: colors.inkFaint),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
