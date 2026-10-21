import 'package:flutter/material.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/basket.dart';

/// The bill.
///
/// Every figure comes from [Totals] rather than being added up here. The app is
/// never the second place a total is computed: when the API is wired in, these
/// numbers arrive from the server already agreed with the invoice, and a screen
/// that had been doing its own arithmetic would start disagreeing with it over
/// a rounded piastre.
class TotalsCard extends StatelessWidget {
  const TotalsCard({
    required this.totals,
    this.coupon,
    this.shippingKnown = true,
    super.key,
  });

  final Totals totals;
  final String? coupon;

  /// Before an address is chosen there is no delivery charge to show, and
  /// showing zero would be a promise the shop has not made.
  final bool shippingKnown;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Corner.rLg,
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          _Row(label: 'إجمالي القطع', value: Money.of(totals.goods)),
          if (totals.hasDiscount) ...[
            Gap.h12,
            _Row(
              label: coupon == null ? 'الخصم' : 'الخصم ($coupon)',
              value: '- ${Money.of(totals.discount)}',
              tone: colors.success,
            ),
          ],
          Gap.h12,
          _Row(
            label: 'الشحن',
            value: !shippingKnown
                ? 'يُحدَّد بعد اختيار العنوان'
                : (totals.shipping <= 0 ? 'مجاني' : Money.of(totals.shipping)),
            tone: shippingKnown && totals.shipping <= 0 ? colors.success : null,
            faint: !shippingKnown,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.md),
            child: Divider(height: 1, color: colors.line),
          ),
          Row(
            children: [
              Text('الإجمالي', style: type.titleMedium),
              const Spacer(),
              Text(
                Money.of(totals.total),
                style: type.titleLarge?.copyWith(color: colors.price),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.tone,
    this.faint = false,
  });

  final String label;
  final String value;
  final Color? tone;
  final bool faint;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Row(
      children: [
        Text(label, style: type.bodyMedium?.copyWith(color: colors.inkSoft)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: (faint ? type.labelSmall : type.labelMedium)?.copyWith(
              color: tone ?? (faint ? colors.inkFaint : null),
            ),
          ),
        ),
      ],
    );
  }
}
