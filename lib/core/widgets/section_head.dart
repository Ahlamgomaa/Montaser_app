import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/palette.dart';

/// The heading over a run of content, with a way out of it.
///
/// The rule to the side of the title is what stops a long scrolling page from
/// reading as one undifferentiated column. It is drawn rather than typed as a
/// divider so it stops exactly where the title ends, whatever the title says.
class SectionHead extends StatelessWidget {
  const SectionHead({
    required this.title,
    this.lede,
    this.actionLabel,
    this.onAction,
    this.padded = true,
    super.key,
  });

  final String title;
  final String? lede;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Padding(
      padding: padded
          ? const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, Gap.md)
          : const EdgeInsets.only(bottom: Gap.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: type.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Gap.w12,
                    Expanded(
                      child: Container(
                        height: 1,
                        margin: const EdgeInsets.only(top: 2),
                        color: colors.line,
                      ),
                    ),
                  ],
                ),
                if (lede != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    lede!,
                    style: type.bodySmall?.copyWith(color: colors.inkFaint),
                  ),
                ],
              ],
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            Gap.w8,
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const Icon(Icons.chevron_left_rounded, size: 18),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
