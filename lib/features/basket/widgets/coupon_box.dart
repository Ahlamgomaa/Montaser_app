import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../data/api/api_failure.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';

/// The discount code.
///
/// Collapsed until asked for. An open field labelled "كود الخصم" tells every
/// customer without one that they are paying more than somebody else, and a
/// good number of them will leave to go looking for a code rather than finish
/// the order.
class CouponBox extends StatefulWidget {
  const CouponBox({super.key});

  @override
  State<CouponBox> createState() => _CouponBoxState();
}

class _CouponBoxState extends State<CouponBox> {
  final _field = TextEditingController();
  bool _open = false;
  String? _refusal;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.basketOf(context);
    final colors = context.palette;
    final applied = store.basket.coupon;

    if (applied != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.lg,
          vertical: Gap.md,
        ),
        decoration: BoxDecoration(
          color: colors.successWash,
          borderRadius: Corner.rMd,
          border: Border.all(color: colors.success),
        ),
        child: Row(
          children: [
            Icon(Icons.local_offer_rounded, size: 18, color: colors.success),
            Gap.w12,
            Expanded(
              child: Text(
                'كود «$applied» مفعّل.',
                style: context.type.labelMedium?.copyWith(
                  color: colors.success,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                AppScope.basket(context).removeCoupon();
                _field.clear();
                setState(() => _refusal = null);
              },
              style: TextButton.styleFrom(foregroundColor: colors.danger),
              child: const Text('إزالة'),
            ),
          ],
        ),
      );
    }

    if (!_open) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: () => setState(() => _open = true),
          icon: const Icon(Icons.local_offer_outlined, size: 18),
          label: const Text('لديك كود خصم؟'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _field,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: context.type.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'WELCOME',
                  isDense: true,
                  errorText: _refusal,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Gap.lg,
                    vertical: Gap.md,
                  ),
                ),
                onSubmitted: (_) => _apply(),
              ),
            ),
            Gap.w8,
            FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
              child: const Text('تفعيل'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _apply() async {
    /*
     * The coupon is checked at the server: whether it exists, whether it has
     * expired, whether this basket qualifies. None of that can be answered
     * here, so the refusal is whatever the server said and not a sentence
     * invented in the app.
     */
    setState(() => _refusal = null);

    try {
      await AppScope.basket(context).applyCoupon(_field.text.trim());
    } on ApiFailure catch (fault) {
      if (mounted) {
        setState(() => _refusal = fault.message);
      }
    }
  }
}
