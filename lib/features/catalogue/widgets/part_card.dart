import 'package:flutter/material.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/glyphs.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/part_artwork.dart';
import '../../../core/widgets/pills.dart';
import '../../../core/widgets/price_line.dart';
import '../../../data/models/catalogue.dart';

/// One part, as it appears in a grid or a shelf.
///
/// A separate widget class rather than a method that returns one. A grid of
/// these is the busiest thing in the app, and a widget class is what lets
/// Flutter skip rebuilding the ones that did not change — a `_buildCard()`
/// helper rebuilds every card in the row whenever anything above it does.
class PartCard extends StatelessWidget {
  const PartCard({
    required this.part,
    required this.onOpen,
    required this.onAdd,
    this.onKeep,
    this.isKept = false,
    this.inBasket = 0,
    this.width,
    super.key,
  });

  /// How tall one of these is, wherever it appears.
  ///
  /// A horizontal shelf and a grid both have to be told the height of their
  /// children, and they have to be told the same one. Two hard-coded numbers in
  /// two files is how a card ends up fitting on the home page and overflowing
  /// by seventy pixels on the browse page.
  static const tall = 368.0;

  /// The bed the part is drawn on, above the words.
  static const artwork = 150.0;

  final Part part;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  final VoidCallback? onKeep;
  final bool isKept;

  /// How many are already in the basket. Shown on the button, because a
  /// customer scrolling a long grid loses track, and re-adding something they
  /// already have is the most common way an order goes wrong.
  final int inBasket;

  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;
    final soldOut = part.availability == Availability.none;

    return SizedBox(
      width: width,
      child: Material(
        color: context.scheme.surface,
        borderRadius: Corner.rLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: Corner.rLg,
              border: Border.all(color: colors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: artwork,
                  child: _Head(
                    part: part,
                    isKept: isKept,
                    onKeep: onKeep,
                    soldOut: soldOut,
                  ),
                ),
                /*
                 * The words take whatever is left rather than adding up to a
                 * number that has to match. The title is the flexible one, so
                 * when somebody's phone is set to large text the name gives up
                 * a line and the price and the button — the two things that
                 * must be readable — keep their room.
                 */
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Gap.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          part.brand ?? part.aisle,
                          textDirection: part.brand == null
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: type.labelSmall?.copyWith(
                            color: colors.inkFaint,
                            letterSpacing: 0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(
                            part.name,
                            style: type.titleSmall?.copyWith(height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Gap.h4,
                        /*
                         * Only when there is one. A zero-star row under every
                         * product in the shop says something untrue; an empty
                         * space says nothing, which is correct.
                         */
                        if (part.hasRating)
                          StarRow(
                            rating: part.rating!,
                            count: part.ratingCount,
                          )
                        else
                          const SizedBox(height: 14),
                        Gap.h8,
                        PriceLine(
                          price: part.price,
                          unit: part.unit,
                          wasPrice: part.wasPrice,
                        ),
                        Gap.h8,
                        _AddButton(
                          soldOut: soldOut,
                          inBasket: inBasket,
                          onAdd: onAdd,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({
    required this.part,
    required this.isKept,
    required this.onKeep,
    required this.soldOut,
  });

  final Part part;
  final bool isKept;
  final VoidCallback? onKeep;
  final bool soldOut;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PartArtwork(
          seed: part.id,
          imageUrl: part.imageUrl,
          glyph: Glyphs.aisleNamed(part.aisle),
          radius: const BorderRadius.vertical(top: Radius.circular(Corner.lg)),
        ),
        /*
         * Sold-out is drawn over the artwork rather than beside the price. A
         * customer scanning a grid reads the pictures first, and a part they
         * cannot have should stop them there instead of after they have priced
         * it.
         */
        if (soldOut)
          Positioned.fill(
            child: ColoredBox(
              color: context.scheme.surface.withValues(alpha: 0.55),
            ),
          ),
        PositionedDirectional(
          top: Gap.sm,
          start: Gap.sm,
          child: _Flag(part: part, soldOut: soldOut),
        ),
        if (onKeep != null)
          PositionedDirectional(
            top: Gap.xs,
            end: Gap.xs,
            child: _KeepButton(isKept: isKept, onKeep: onKeep!),
          ),
      ],
    );
  }
}

/// The one badge worth showing, out of the four that might apply.
///
/// In order of what a customer needs to know: that they cannot have it, that it
/// is cheaper than usual, that it is nearly gone, that it is new. Showing all
/// four would fill the artwork with labels and say nothing.
class _Flag extends StatelessWidget {
  const _Flag({required this.part, required this.soldOut});

  final Part part;
  final bool soldOut;

  @override
  Widget build(BuildContext context) {
    if (soldOut) {
      return StockPill(free: part.free, tight: true);
    }

    if (part.isOnOffer) {
      return Pill(
        label: 'عرض',
        ink: context.palette.danger,
        bed: context.palette.dangerWash,
        tight: true,
      );
    }

    if (part.availability == Availability.few) {
      return StockPill(free: part.free, tight: true);
    }

    return const SizedBox.shrink();
  }
}

class _KeepButton extends StatelessWidget {
  const _KeepButton({required this.isKept, required this.onKeep});

  final bool isKept;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.scheme.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onKeep,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isKept ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            size: 18,
            color: isKept ? context.palette.danger : context.palette.inkFaint,
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.soldOut,
    required this.inBasket,
    required this.onAdd,
  });

  final bool soldOut;
  final int inBasket;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    if (soldOut) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(38),
            padding: EdgeInsets.zero,
            textStyle: context.type.labelMedium,
          ),
          child: const Text('غير متاح'),
        ),
      );
    }

    final held = inBasket > 0;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onAdd,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(38),
          padding: EdgeInsets.zero,
          textStyle: context.type.labelMedium,
          backgroundColor: held ? colors.successWash : null,
          foregroundColor: held ? colors.success : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              held ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
              size: 16,
            ),
            Gap.w8,
            Flexible(
              child: Text(
                held ? 'في السلة ($inBasket)' : 'أضف',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
