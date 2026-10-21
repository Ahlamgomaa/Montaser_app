import 'package:flutter/material.dart';

import '../../data/models/catalogue.dart';
import '../theme/dimens.dart';
import '../theme/palette.dart';

/// A small coloured label.
///
/// One widget for every badge in the app, so a status somewhere new cannot
/// arrive in a shape nothing else uses.
class Pill extends StatelessWidget {
  const Pill({
    required this.label,
    required this.ink,
    required this.bed,
    this.glyph,
    this.tight = false,
    super.key,
  });

  final String label;
  final Color ink;
  final Color bed;
  final IconData? glyph;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tight ? 8 : Gap.md,
        vertical: tight ? 3 : 5,
      ),
      decoration: BoxDecoration(color: bed, borderRadius: Corner.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            Icon(glyph, size: tight ? 12 : 14, color: ink),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: context.type.labelSmall?.copyWith(
              color: ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// What the customer may order, said in words.
///
/// Three states rather than a raw count. "٤ متاح" beside a compressor is
/// useful; "٤١ متاح" beside a bag of nuts is noise, and "٠ متاح" should not
/// look like a number at all — it should look like a closed door.
class StockPill extends StatelessWidget {
  const StockPill({required this.free, this.tight = false, super.key});

  final double free;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return switch (Availability.of(free)) {
      Availability.none => Pill(
        label: 'نفدت الكمية',
        ink: colors.danger,
        bed: colors.dangerWash,
        glyph: Icons.remove_shopping_cart_outlined,
        tight: tight,
      ),
      Availability.few => Pill(
        label: 'باقي ${free.toInt()} فقط',
        ink: colors.warn,
        bed: colors.warnWash,
        glyph: Icons.bolt_outlined,
        tight: tight,
      ),
      Availability.plenty => Pill(
        label: 'متوفر',
        ink: colors.success,
        bed: colors.successWash,
        glyph: Icons.check_circle_outline,
        tight: tight,
      ),
    };
  }
}

/// A rating, drawn.
///
/// Half stars are shown because a 4.6 rounded to 5 flatters the shop, and a
/// customer who orders on the strength of five stars and receives a four-star
/// part learns not to trust the number again.
class StarRow extends StatelessWidget {
  const StarRow({required this.rating, this.count, this.size = 14, super.key});

  final double rating;
  final int? count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : (rating >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
            size: size,
            color: rating >= i - 0.5 ? const Color(0xFFE0A32E) : colors.line,
          ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: context.type.labelSmall?.copyWith(color: colors.inkFaint),
          ),
        ],
      ],
    );
  }
}
