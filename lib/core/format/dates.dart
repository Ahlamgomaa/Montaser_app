import 'package:intl/intl.dart';

/// Dates, in Arabic, and in the shape the reader actually needs.
///
/// A customer looking at an order does not want a timestamp — they want to know
/// whether it was today, and if not, roughly when. So the near past is written
/// in words and only the distant past falls back to a calendar date.
abstract final class Dates {
  static final _day = DateFormat('d MMMM y', 'ar');
  static final _dayShort = DateFormat('d MMM', 'ar');
  static final _clock = DateFormat('h:mm a', 'ar');

  /// `١٢ أغسطس ٢٠٢٦`
  static String full(DateTime moment) => _day.format(moment);

  /// `١٢ أغسطس ٢٠٢٦ — ٣:٤٠ م`
  static String fullWithClock(DateTime moment) =>
      '${_day.format(moment)} — ${_clock.format(moment)}';

  /// `١٢ أغسطس`
  static String short(DateTime moment) => _dayShort.format(moment);

  /// How long ago, said the way a person would say it.
  static String ago(DateTime moment, {DateTime? now}) {
    final since = (now ?? DateTime.now()).difference(moment);

    if (since.inMinutes < 1) {
      return 'الآن';
    }

    if (since.inMinutes < 60) {
      return 'منذ ${since.inMinutes} دقيقة';
    }

    if (since.inHours < 24) {
      return 'منذ ${since.inHours} ساعة';
    }

    if (since.inDays == 1) {
      return 'أمس';
    }

    if (since.inDays < 7) {
      return 'منذ ${since.inDays} أيام';
    }

    /*
     * Past a week, "منذ ٣٤ يوماً" stops being useful — nobody counts in
     * thirty-fours. A date is easier to place against everything else the
     * reader remembers.
     */
    return short(moment);
  }

  /// A delivery window, as a promise rather than a guess.
  static String window(DateTime from, DateTime to) {
    if (from.month == to.month) {
      return 'بين ${from.day} و${short(to)}';
    }

    return 'بين ${short(from)} و${short(to)}';
  }
}
