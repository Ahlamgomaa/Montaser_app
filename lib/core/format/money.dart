import 'package:intl/intl.dart';

/// Money, written the same way everywhere.
///
/// One formatter, created once and reused. Building a [NumberFormat] inside a
/// `build` method means building one per price per frame, and a scrolling grid
/// of products makes that a few hundred a second for no reason at all.
abstract final class Money {
  static final _whole = NumberFormat('#,##0', 'ar_EG');
  static final _withPiastres = NumberFormat('#,##0.00', 'ar_EG');

  /// The currency, spelled rather than symbolised.
  ///
  /// `ج.م` reads correctly beside Arabic digits where a bare `£` does not, and
  /// the shop only ever sells in one currency, so there is nothing to
  /// disambiguate.
  static const unit = 'ج.م';

  /// A price, as a customer should see it.
  ///
  /// Piastres are shown only when there are any. A parts shop prices in whole
  /// pounds nearly always, and `٤٥٠٫٠٠` everywhere is noise that makes the two
  /// prices that genuinely have halves harder to notice.
  static String of(num value) {
    final rounded = (value * 100).round() / 100;
    final body = rounded % 1 == 0
        ? _whole.format(rounded)
        : _withPiastres.format(rounded);

    return '$body $unit';
  }

  /// A price with no currency after it, for places that say the unit once for a
  /// whole column.
  static String bare(num value) {
    final rounded = (value * 100).round() / 100;

    return rounded % 1 == 0
        ? _whole.format(rounded)
        : _withPiastres.format(rounded);
  }

  /// A saving, as a share rather than an amount.
  static String discountShare({required num was, required num now}) {
    if (was <= 0 || now >= was) {
      return '';
    }

    return '${(((was - now) / was) * 100).round()}٪-';
  }
}
