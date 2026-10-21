import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/palette.dart';

/// Minus, a number, plus.
///
/// The ceiling is passed in rather than assumed, and the plus goes dead when
/// the customer reaches it. Letting them press on and refusing afterwards is
/// the same information delivered as a failure — this way the limit is
/// something they can feel instead of something that happens to them.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.quantity,
    required this.onChanged,
    this.ceiling,
    this.dense = false,
    this.onRemoveAtOne,
    super.key,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int? ceiling;
  final bool dense;

  /// What the minus does when the count is already one.
  ///
  /// On a basket line it should offer to remove the line; on a product page it
  /// should simply refuse. Passing it in keeps one widget honest in both places
  /// rather than growing a flag called `isCart`.
  final VoidCallback? onRemoveAtOne;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final atCeiling = ceiling != null && quantity >= ceiling!;
    final side = dense ? 32.0 : 40.0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: Corner.pill,
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Nudge(
            glyph: quantity <= 1 && onRemoveAtOne != null
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            side: side,
            tone: quantity <= 1 && onRemoveAtOne != null ? colors.danger : null,
            onTap: quantity <= 1
                ? onRemoveAtOne
                : () => onChanged(quantity - 1),
          ),
          SizedBox(
            width: dense ? 28 : 36,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: dense ? context.type.labelMedium : context.type.titleSmall,
            ),
          ),
          _Nudge(
            glyph: Icons.add_rounded,
            side: side,
            onTap: atCeiling ? null : () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _Nudge extends StatelessWidget {
  const _Nudge({
    required this.glyph,
    required this.side,
    required this.onTap,
    this.tone,
  });

  final IconData glyph;
  final double side;
  final VoidCallback? onTap;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final off = onTap == null;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: side,
        height: side,
        child: Icon(
          glyph,
          size: side * 0.45,
          color: off ? colors.line : (tone ?? context.scheme.onSurface),
        ),
      ),
    );
  }
}
