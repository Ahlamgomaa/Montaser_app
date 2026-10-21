import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/dimens.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/brand_mark.dart';

/// Asks before the app closes.
///
/// A customer with a basket half filled who brushes the back gesture should not
/// lose the afternoon's work to a swipe. So the last back — the one that would
/// leave — is caught and turned into a question.
///
/// Only the last one. [armed] is false everywhere except the shop front, so
/// back still means back on every other screen; a confirmation on each of them
/// would be a dialog between the customer and every step they take.
class LeaveGuard extends StatefulWidget {
  const LeaveGuard({required this.child, required this.armed, super.key});

  final Widget child;
  final bool armed;

  @override
  State<LeaveGuard> createState() => _LeaveGuardState();
}

class _LeaveGuardState extends State<LeaveGuard> {
  bool _asking = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      /*
       * `canPop: false` intercepts the gesture rather than blocking it. On
       * Android 14 and later this also stops the predictive-back animation from
       * peeling the app away behind the dialog — the customer would see the
       * home screen sliding in underneath a question about whether they want to
       * go there.
       */
      canPop: !widget.armed,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !widget.armed || _asking) {
          return;
        }

        _asking = true;
        final leaving = await _ask(context);
        _asking = false;

        if (leaving) {
          /*
           * Closed rather than popped. Popping the last route leaves an
           * Android app running with a black screen where its UI was, which
           * looks like a crash; this is the same thing the home button does.
           */
          await SystemNavigator.pop();
        }
      },
      child: widget.child,
    );
  }

  Future<bool> _ask(BuildContext context) async {
    final leaving = await showDialog<bool>(
      context: context,
      builder: (context) => const _LeaveDialog(),
    );

    return leaving ?? false;
  }
}

class _LeaveDialog extends StatelessWidget {
  const _LeaveDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Dialog(
      insetPadding: const EdgeInsets.all(Gap.xl),
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 56),
            Gap.h24,
            Text(
              'تريد الخروج من التطبيق؟',
              style: type.titleMedium,
              textAlign: TextAlign.center,
            ),
            Gap.h8,
            Text(
              'ستبقى سلتك كما هي عند عودتك.',
              style: type.bodySmall?.copyWith(color: colors.inkFaint),
              textAlign: TextAlign.center,
            ),
            Gap.h24,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: colors.danger,
                      side: BorderSide(color: colors.danger),
                    ),
                    child: const Text('خروج'),
                  ),
                ),
                Gap.w12,
                Expanded(
                  /*
                   * Staying is the wider, filled, right-hand button. Whoever
                   * reached this dialog by accident — which is most of them —
                   * should find the way back under their thumb.
                   */
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('البقاء في التطبيق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
