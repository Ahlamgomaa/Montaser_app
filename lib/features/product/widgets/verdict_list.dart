import 'package:flutter/material.dart';

import '../../../core/format/dates.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/pills.dart';
import '../../../data/models/catalogue.dart';
import 'review_sheet.dart';

/// The reviews, with the score above them.
class VerdictList extends StatelessWidget {
  const VerdictList({
    required this.itemId,
    required this.verdicts,
    required this.rating,
    required this.count,
    super.key,
  });

  /// The part being reviewed, so the sheet knows what it is about.
  final int itemId;

  final List<Verdict> verdicts;

  /// Absent until somebody has actually rated it.
  ///
  /// Nought stars reads as a part the shop marked badly; none reads as one
  /// nobody has rated yet, and those are different sentences.
  final double? rating;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Metric.pagePad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rating != null && (count ?? 0) > 0) ...[
            _Score(rating: rating!, count: count!, verdicts: verdicts),
            Gap.h16,
          ] else ...[
            const _Unrated(),
            Gap.h16,
          ],
          for (final one in verdicts) ...[_VerdictCard(verdict: one), Gap.h12],
          OutlinedButton.icon(
            onPressed: () => _write(context),
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: const Text('اكتب تقييمك'),
          ),
        ],
      ),
    );
  }
}

/// Open the sheet, and pass on whatever the shop said about it.
///
/// The review is not shown here afterwards. Most shops read them before
/// publishing — it is a setting on the website — so adding it to the list would
/// show the customer something nobody else can see, and they would wonder later
/// why it had vanished.
Future<void> _write(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final list = context.findAncestorWidgetOfExactType<VerdictList>();

  if (list == null) {
    return;
  }

  final said = await ReviewSheet.open(context, itemId: list.itemId);

  if (said == null) {
    return;
  }

  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(said)));
}

/// The average, and what it is made of.
///
/// The bars are drawn from the count rather than invented, and they are worth
/// the space: an average of 4.5 built from twos and fives is a different part
/// from one built entirely from fours and fives, and only the spread says so.
class _Score extends StatelessWidget {
  const _Score({
    required this.rating,
    required this.count,
    required this.verdicts,
  });

  final double rating;
  final int count;
  final List<Verdict> verdicts;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    /*
     * Counted off the reviews themselves, five stars first.
     *
     * This used to be a shape derived from the average — sixty-two per cent at
     * five, twenty-four at four, and so on — which drew a plausible chart that
     * was not true of any part. An average of 4.5 built from twos and fives is
     * a different part from one built entirely from fours and fives, and the
     * spread is the only thing that says so. Inventing it said the opposite of
     * what it was there to say.
     */
    final spread = <int>[
      for (var star = 5; star >= 1; star--)
        verdicts.where((one) => one.rating == star).length,
    ];

    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Corner.rLg,
        border: Border.all(color: colors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: type.displaySmall?.copyWith(height: 1.1),
              ),
              Gap.h4,
              StarRow(rating: rating, size: 15),
              Gap.h4,
              Text(
                '$count تقييماً',
                style: type.labelSmall?.copyWith(color: colors.inkFaint),
              ),
            ],
          ),
          Gap.w24,
          Expanded(
            child: Column(
              children: [
                for (var star = 5; star >= 1; star--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          child: Text(
                            '$star',
                            style: type.labelSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Gap.w8,
                        Expanded(
                          child: ClipRRect(
                            borderRadius: Corner.pill,
                            child: LinearProgressIndicator(
                              value: count == 0 ? 0 : spread[5 - star] / count,
                              minHeight: 6,
                              backgroundColor: colors.line,
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFFE0A32E),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.verdict});

  final Verdict verdict;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: context.scheme.primaryContainer,
                child: Text(
                  verdict.author.isEmpty
                      ? '؟'
                      : verdict.author.substring(0, 1),
                  style: type.labelMedium?.copyWith(
                    color: context.scheme.primary,
                  ),
                ),
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verdict.author,
                      style: type.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (verdict.written != null)
                      Text(
                        Dates.ago(verdict.written!),
                        style: type.labelSmall?.copyWith(
                          color: colors.inkFaint,
                        ),
                      ),
                  ],
                ),
              ),
              StarRow(rating: verdict.rating.toDouble(), size: 13),
            ],
          ),
          Gap.h12,
          if (verdict.title != null) ...[
            Text(verdict.title!, style: type.titleSmall),
            Gap.h4,
          ],
          Text(verdict.body, style: type.bodyMedium),
          if (verdict.isBuyer) ...[
            Gap.h12,
            Pill(
              label: 'شراء موثّق',
              ink: colors.success,
              bed: colors.successWash,
              glyph: Icons.verified_rounded,
              tight: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// A part nobody has rated yet.
///
/// Said plainly rather than drawn as an empty chart. A row of zero-length bars
/// looks like a part that was rated badly, which is the opposite of the truth.
class _Unrated extends StatelessWidget {
  const _Unrated();

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Corner.rLg,
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          Icon(Icons.reviews_outlined, size: 26, color: colors.inkFaint),
          Gap.h8,
          Text(
            'لا توجد تقييمات بعد',
            style: context.type.titleSmall?.copyWith(color: colors.inkSoft),
          ),
          Gap.h4,
          Text(
            'كن أول من يكتب رأيه في هذه القطعة.',
            textAlign: TextAlign.center,
            style: context.type.bodySmall?.copyWith(color: colors.inkFaint),
          ),
        ],
      ),
    );
  }
}
