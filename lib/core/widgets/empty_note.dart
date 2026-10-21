import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/palette.dart';

/// What a screen says when it has nothing to show.
///
/// Every empty state in the app comes through here, and every one of them takes
/// an action. A screen that says "لا توجد طلبات" and stops has told the
/// customer they are in the wrong place without offering them the right one —
/// an empty basket should point at the shop, an empty address book at the form.
class EmptyNote extends StatelessWidget {
  const EmptyNote({
    required this.glyph,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    super.key,
  });

  final IconData glyph;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Gap.xl,
          vertical: compact ? Gap.xl : Gap.huge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /*
             * A ring rather than a filled circle. A large block of the brand
             * colour on an otherwise empty screen makes the absence look like
             * an error; an outline reads as a resting state.
             */
            Container(
              width: compact ? 64 : 84,
              height: compact ? 64 : 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.scheme.surface,
                border: Border.all(color: colors.line, width: 1.5),
              ),
              child: Icon(
                glyph,
                size: compact ? 28 : 36,
                color: colors.inkFaint,
              ),
            ),
            Gap.h24,
            Text(title, style: type.titleMedium, textAlign: TextAlign.center),
            Gap.h8,
            Text(
              body,
              style: type.bodySmall?.copyWith(color: colors.inkFaint),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              Gap.h24,
              SizedBox(
                width: 220,
                child: FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The same news, small enough to sit inside a strip.
///
/// For the rows on the shop front. A full [EmptyNote] is taller than the strip
/// it would stand in for; a blank strip under a heading reads as something that
/// failed to load. This is one line — a ring, a title and a sentence — that says
/// the shop simply has nothing here yet.
class ShelfNote extends StatelessWidget {
  const ShelfNote({
    required this.glyph,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData glyph;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Padding(
      padding: Metric.pagePad,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            color: context.scheme.surface,
            borderRadius: Corner.rLg,
            border: Border.all(color: colors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.line, width: 1.5),
                ),
                child: Icon(glyph, size: 20, color: colors.inkFaint),
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: type.labelMedium),
                    Gap.h4,
                    Text(
                      body,
                      style: type.labelSmall?.copyWith(color: colors.inkFaint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
