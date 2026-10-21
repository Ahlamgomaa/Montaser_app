import 'package:flutter/material.dart';

import '../../../core/theme/dimens.dart';
import '../../../data/store/identity_store.dart';
import '../../../core/theme/palette.dart';

/// The three things the shop promises.
///
/// Placed directly under the banner because this is where a first-time customer
/// decides whether to trust the place. A parts shop lives or dies on whether
/// the part is genuine and whether it can be sent back — so those are the two
/// said first, and neither is buried in a footer nobody scrolls to.
class PromiseRow extends StatelessWidget {
  const PromiseRow({super.key});

  static const _promises = <(IconData, String, String)>[
    (Icons.verified_outlined, 'قطع أصلية', 'وكلاء معتمدون'),
    (Icons.assignment_return_outlined, 'استبدال', ''),
    (Icons.support_agent_outlined, 'دعم فني', 'يعرف الشغل'),
  ];

  /// The first line of whatever the shop wrote about returns.
  static String get _returnsLine {
    final policy = ShopBadge.instance.returnsPolicy.trim();

    if (policy.isEmpty) {
      return '';
    }

    return policy.split(RegExp(r'[\r\n]')).first.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
      child: Row(
        children: [
          for (final (glyph, title, note) in _promises) ...[
            Expanded(
              child: _Promise(
                glyph: glyph,
                title: title,
                /*
                 * The returns line is the shop's own, not the app's. "Within
                 * fourteen days" was written here, which made a promise on the
                 * customer's phone that nobody at the shop had agreed to and
                 * that could not be corrected without a release.
                 *
                 * Its first line only: this is a tile two fingers wide, and
                 * the whole policy is a paragraph on the account screen.
                 */
                note: note.isNotEmpty ? note : _returnsLine,
              ),
            ),
            if (title != _promises.last.$2) Gap.w8,
          ],
        ],
      ),
    );
  }
}

class _Promise extends StatelessWidget {
  const _Promise({
    required this.glyph,
    required this.title,
    required this.note,
  });

  final IconData glyph;
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: Gap.md, horizontal: Gap.sm),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Corner.rMd,
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          Icon(glyph, size: 22, color: context.scheme.primary),
          Gap.h8,
          Text(
            title,
            style: type.labelMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            note,
            style: type.labelSmall?.copyWith(color: colors.inkFaint),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
