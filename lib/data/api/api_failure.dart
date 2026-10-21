import 'package:flutter/foundation.dart';

/// Why a call did not work, in terms a screen can act on.
///
/// One type for every failure — no network, a refused login, a validation
/// complaint, a server fault — because a screen that has to catch four
/// different exception classes catches three of them and lets the fourth
/// through as a red screen in front of a customer.
///
/// The [kind] is what a screen switches on; the [message] is what it shows.
/// Both come from the server where the server had an opinion, because the shop
/// says these things in its own words on the website and the app should not
/// invent a second wording for the same refusal.
@immutable
class ApiFailure implements Exception {
  const ApiFailure({
    required this.kind,
    required this.message,
    this.status,
    this.errors = const {},
    this.extra = const {},
  });

  final FailureKind kind;
  final String message;
  final int? status;

  /// Field name to the complaints about it, exactly as the server keyed them.
  /// A form walks this to put each message under the right box.
  final Map<String, List<String>> errors;

  /// Anything else the server sent that the app can use — `available` on a
  /// quantity refusal being the one that matters. A screen told only "no" can
  /// do nothing but repeat it; one told "three" can offer three.
  final Map<String, dynamic> extra;

  /// The first complaint about a given field, or null.
  String? faultIn(String field) {
    final complaints = errors[field];

    return (complaints == null || complaints.isEmpty) ? null : complaints.first;
  }

  /// The real quantity, when the refusal was about stock.
  double? get available {
    final value = extra['available'];

    return value is num ? value.toDouble() : null;
  }

  bool get isAuth => kind == FailureKind.unauthenticated;

  bool get isValidation => kind == FailureKind.validation;

  /// Whether trying the same thing again could plausibly work.
  ///
  /// Offering «حاول مرة أخرى» under a validation complaint is offering to
  /// repeat a mistake; under a dropped connection it is the only useful thing
  /// on the screen.
  bool get isWorthRetrying =>
      kind == FailureKind.offline ||
      kind == FailureKind.server ||
      kind == FailureKind.unknown;

  @override
  String toString() => 'ApiFailure(${kind.name}, $status): $message';
}

/// The kinds of failure a screen behaves differently about.
enum FailureKind {
  /// The phone could not reach the server at all.
  offline,

  /// There is no server address configured yet.
  notConfigured,

  /// The server took too long.
  timeout,

  /// No token, or one the server no longer honours. The app signs out.
  unauthenticated,

  /// Signed in, but not allowed — a suspended account.
  forbidden,

  /// Not there, or not theirs.
  missing,

  /// The form was wrong. [ApiFailure.errors] says which fields.
  validation,

  /// The basket changed underneath the customer while they were paying.
  conflict,

  /// Too fast.
  throttled,

  /// The server broke.
  server,

  /// Something else, including a reply that was not the shape we expect.
  unknown,
}
