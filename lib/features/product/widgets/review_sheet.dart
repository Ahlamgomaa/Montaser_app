import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/app_field.dart';
import '../../../data/api/api_failure.dart';

/// Writing a review.
///
/// A sheet rather than a page: the customer is looking at the part, and taking
/// them away from it to say what they think about it is a screen they have to
/// find their way back from.
///
/// Nothing here decides whether the review is published. The shop reads them
/// first — that is a setting on the website — so what this returns is the
/// server's own sentence about what happens next, and the customer is told it
/// rather than being shown their words appearing instantly and then not.
class ReviewSheet extends StatefulWidget {
  const ReviewSheet({required this.itemId, super.key});

  final int itemId;

  /// Open it, and answer with what the server said if anything was written.
  static Future<String?> open(BuildContext context, {required int itemId}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReviewSheet(itemId: itemId),
    );
  }

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  int _rating = 0;
  bool _sending = false;
  String? _fault;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Padding(
      /* Above the keyboard, which is most of the screen while this is open. */
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اكتب تقييمك', style: context.type.titleMedium),
            Gap.h4,
            Text(
              'رأيك يساعد غيرك على اختيار القطعة الصحيحة.',
              style: context.type.bodySmall?.copyWith(color: colors.inkFaint),
            ),
            Gap.h16,

            /* The stars first: it is the only part that is required. */
            Row(
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    onPressed: () => setState(() => _rating = star),
                    icon: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 32,
                      color: star <= _rating ? colors.warn : colors.inkFaint,
                    ),
                  ),
              ],
            ),

            Gap.h8,
            AppField(
              label: 'عنوان',
              hint: 'مثلاً: مطابقة تماماً للأصلية',
              optional: true,
              controller: _title,
              glyph: Icons.title_rounded,
            ),
            Gap.h12,
            AppField(
              label: 'رأيك في القطعة',
              hint: 'كيف كانت الجودة والتركيب؟',
              controller: _body,
              glyph: Icons.rate_review_outlined,
              lines: 4,
            ),

            if (_fault != null) ...[
              Gap.h12,
              Text(
                _fault!,
                style: context.type.bodySmall?.copyWith(color: colors.danger),
              ),
            ],

            Gap.h16,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sending ? null : _send,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(_sending ? 'جارٍ الإرسال…' : 'أرسل التقييم'),
              ),
            ),
            Gap.h8,
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    /*
     * Checked here as well as at the server. A round trip to be told the stars
     * are missing is a round trip nobody needed.
     */
    if (_rating < 1) {
      setState(() => _fault = 'اختر عدد النجوم أولاً.');

      return;
    }

    if (_body.text.trim().isEmpty) {
      setState(() => _fault = 'اكتب رأيك في القطعة.');

      return;
    }

    setState(() {
      _sending = true;
      _fault = null;
    });

    final navigator = Navigator.of(context);

    try {
      final said = await AppScope.shop.account.review(
        itemId: widget.itemId,
        rating: _rating,
        title: _title.text.trim().isEmpty ? null : _title.text.trim(),
        body: _body.text.trim(),
      );

      navigator.pop(said ?? 'شكراً لك. سيُنشر تقييمك بعد المراجعة.');
    } on ApiFailure catch (fault) {
      if (mounted) {
        setState(() {
          _sending = false;
          /* The server's own words — it knows why, and this does not. */
          _fault = fault.message;
        });
      }
    } catch (error, stack) {
      /* Anything else used to leave the button on "sending" for good. */
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack, library: 'review'),
      );

      if (mounted) {
        setState(() {
          _sending = false;
          _fault = 'تعذّر إرسال تقييمك. حاول مرة أخرى.';
        });
      }
    }
  }
}
