import 'package:flutter/material.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';

/// How far through the checkout the customer is.
///
/// Three dots and two rules. It is worth the strip of screen it costs: without
/// it, a page that reveals its delivery options only after an address is chosen
/// looks like a page that is missing something.
class StepRail extends StatelessWidget {
  const StepRail({
    required this.atAddress,
    required this.atShipping,
    super.key,
  });

  final bool atAddress;
  final bool atShipping;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.sm),
      child: Row(
        children: [
          _Dot(label: 'العنوان', done: atAddress, at: 1),
          _Rule(done: atAddress),
          _Dot(label: 'الشحن', done: atShipping, at: 2),
          _Rule(done: atShipping),
          _Dot(label: 'الدفع', done: atShipping, at: 3),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.label, required this.done, required this.at});

  final String label;
  final bool done;
  final int at;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? context.scheme.primary : context.scheme.surface,
            border: Border.all(
              color: done ? context.scheme.primary : colors.line,
              width: 1.5,
            ),
          ),
          child: done
              ? Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: context.scheme.onPrimary,
                )
              : Text(
                  '$at',
                  style: context.type.labelSmall?.copyWith(
                    color: colors.inkFaint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        Gap.h4,
        Text(
          label,
          style: context.type.labelSmall?.copyWith(
            color: done ? context.scheme.primary : colors.inkFaint,
            fontWeight: done ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 2,
          color: done ? context.scheme.primary : context.palette.line,
        ),
      ),
    );
  }
}
