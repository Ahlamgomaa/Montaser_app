import 'package:flutter/material.dart';

import '../../data/api/api_failure.dart';
import '../theme/dimens.dart';
import '../theme/palette.dart';
import 'empty_note.dart';

/// A screen's worth of waiting, failing or showing.
///
/// Every call the app makes has the same four outcomes — still going, it broke,
/// it worked but there is nothing, it worked — and writing those four states
/// into fifteen screens means fifteen chances to forget one. Forgetting the
/// third gives a blank page; forgetting the second gives a spinner that never
/// stops, which is the single most common way an app looks broken.
///
/// So the four are written once, here, and a screen supplies only the part that
/// is its own: what to draw when there is something to draw.
class Loader<T> extends StatelessWidget {
  const Loader({
    required this.future,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.empty,
    this.waiting,
    this.onMissing,
    super.key,
  });

  final Future<T>? future;
  final Widget Function(BuildContext context, T value) builder;

  /// What to do when the customer asks again. Screens pass the thing that
  /// re-runs the call and rebuilds; without it the error state has nothing to
  /// offer but the news.
  final VoidCallback? onRetry;

  /// Whether a successful answer is nonetheless nothing.
  ///
  /// An empty list is a success as far as the network is concerned, and a
  /// success that draws nothing looks exactly like a failure.
  final bool Function(T value)? isEmpty;

  final Widget? empty;
  final Widget? waiting;

  /// What to draw when the thing asked for is not there.
  ///
  /// A four-oh-four is not a network fault and "try again" is no use against
  /// one — the answer will be the same. It is a link to somebody else's order,
  /// or a part that has been taken off the store, and what the customer needs
  /// is a way onwards rather than a way to repeat themselves.
  ///
  /// Optional: without it a missing thing falls through to the ordinary failure
  /// note, which says the right words and simply offers nothing to do.
  final Widget Function(BuildContext context)? onMissing;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return waiting ?? const LoadingNote();
        }

        if (snapshot.hasError) {
          final fault = snapshot.error;

          if (onMissing != null &&
              fault is ApiFailure &&
              fault.kind == FailureKind.missing) {
            return onMissing!(context);
          }

          return FailureNote(fault: fault, onRetry: onRetry);
        }

        if (!snapshot.hasData) {
          return FailureNote(fault: null, onRetry: onRetry);
        }

        final value = snapshot.data as T;

        if ((isEmpty?.call(value) ?? false) && empty != null) {
          return empty!;
        }

        return builder(context, value);
      },
    );
  }
}

/// Waiting.
class LoadingNote extends StatelessWidget {
  const LoadingNote({this.tall = true, super.key});

  final bool tall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tall ? Gap.huge * 2 : Gap.xl),
      child: Center(
        child: SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: context.scheme.primary,
          ),
        ),
      ),
    );
  }
}

/// It broke, said in a way the customer can act on.
///
/// The wording comes from the server wherever the server had an opinion,
/// because the shop already says these things on the website and a second
/// wording for the same refusal is how an app and a site start contradicting
/// each other. Only the two failures the server cannot describe — no
/// connection, no address configured — are worded here.
class FailureNote extends StatelessWidget {
  const FailureNote({required this.fault, this.onRetry, super.key});

  final Object? fault;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = fault is ApiFailure ? fault! as ApiFailure : null;
    final kind = failure?.kind ?? FailureKind.unknown;

    final (glyph, title) = switch (kind) {
      FailureKind.offline => (
        Icons.wifi_off_rounded,
        'لا يوجد اتصال',
      ),
      FailureKind.timeout => (
        Icons.hourglass_empty_rounded,
        'السيرفر تأخّر',
      ),
      FailureKind.notConfigured => (
        Icons.dns_outlined,
        'التطبيق غير مربوط بالسيرفر',
      ),
      FailureKind.missing => (
        Icons.search_off_rounded,
        'غير موجود',
      ),
      FailureKind.unauthenticated => (
        Icons.lock_outline_rounded,
        'سجّل الدخول أولاً',
      ),
      FailureKind.forbidden => (
        Icons.block_rounded,
        'غير مسموح',
      ),
      FailureKind.throttled => (
        Icons.timer_outlined,
        'محاولات كثيرة',
      ),
      FailureKind.server => (
        Icons.cloud_off_rounded,
        'عطل في السيرفر',
      ),
      _ => (Icons.error_outline_rounded, 'تعذّر تحميل البيانات'),
    };

    return EmptyNote(
      glyph: glyph,
      title: title,
      body: failure?.message ?? 'حدث خطأ غير متوقع. حاول مرة أخرى.',
      actionLabel: onRetry != null && (failure?.isWorthRetrying ?? true)
          ? 'حاول مرة أخرى'
          : null,
      onAction: onRetry,
    );
  }
}

/// Telling somebody what went wrong, in passing.
///
/// For failures that happen under a tap rather than under a screen — adding to
/// the basket, saving an address. The screen stays where it was and the reason
/// arrives at the bottom of it.
void sayFailure(BuildContext context, Object fault) {
  final failure = fault is ApiFailure ? fault : null;

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(failure?.message ?? 'تعذّر إتمام الطلب.'),
        backgroundColor: failure?.isValidation ?? false
            ? null
            : context.palette.danger,
      ),
    );
}
