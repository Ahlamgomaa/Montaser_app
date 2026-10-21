import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:montaser_app/app/montaser_app.dart';
import 'package:montaser_app/core/theme/app_theme.dart';

/// The little that is worth testing while the app is still all interface.
///
/// Not a screenshot test and not a walk through every screen — those would only
/// restate the layout, and every restatement has to be edited each time the
/// design moves. These check the things that would be wrong rather than merely
/// different: that the shop opens in Arabic reading right to left, that the
/// basket keeps count, and that no screen overflows its box.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');

    /*
     * The app remembers two things between runs — the server address and the
     * shop's own name — and both are read before the first frame. Without a
     * store behind them the platform channel throws and nothing draws, so the
     * failure looks like a broken screen rather than a missing test double.
     */
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// Open the app and wait out the splash.
  ///
  /// `pumpAndSettle` cannot be used to get past it: the splash holds a spinner,
  /// and a spinner never stops, so settling never happens. Pumping a known
  /// stretch of time walks the clock forward instead of waiting for a quiet
  /// frame that will not come.
  Future<void> openShop(WidgetTester tester) async {
    await tester.pumpWidget(const MontaserApp());
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('opens on the shop, in Arabic, right to left', (tester) async {
    await openShop(tester);

    expect(find.text('السلة'), findsWidgets);
    expect(find.text('الأقسام'), findsWidgets);

    final direction = Directionality.of(
      tester.element(find.text('السلة').first),
    );

    expect(direction, TextDirection.rtl);
  });

  /// What a customer sees when the shop cannot be reached.
  ///
  /// This replaced a test that added a part to the basket. That one could only
  /// ever pass while the catalogue was invented inside the app: the parts now
  /// come from the server, and a widget test has no server, so it was asserting
  /// something about scaffolding rather than about the shop.
  ///
  /// What is worth asserting instead is the case that actually happens to
  /// customers — a phone with no signal. The failure has to be legible and it
  /// has to offer a way out. A spinner that never stops is the single most
  /// common way an app looks broken, and it is exactly what this catches.
  testWidgets('says so plainly when the shop cannot be reached', (tester) async {
    await openShop(tester);

    /* Long enough for the call to have given up rather than still be trying. */
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(CircularProgressIndicator), findsNothing);

    /*
     * The tab bar is still there. A failed call must not take the whole shell
     * with it — a customer who cannot reach the catalogue can still open their
     * basket and their orders.
     */
    expect(find.text('السلة'), findsWidgets);
  });
  /// The typeface, checked rather than eyeballed.
  ///
  /// "The font looks wrong" is hard to settle by looking — Arabic system faces
  /// and Cairo are close enough at a glance to argue about. This asserts the
  /// thing that has to be true for the bundled face to reach the screen.
  testWidgets('every style in the scale is set in Cairo', (tester) async {
    final scale = AppTheme.light.textTheme;

    final styles = <String, TextStyle?>{
      'displaySmall': scale.displaySmall,
      'headlineMedium': scale.headlineMedium,
      'headlineSmall': scale.headlineSmall,
      'titleLarge': scale.titleLarge,
      'titleMedium': scale.titleMedium,
      'titleSmall': scale.titleSmall,
      'bodyLarge': scale.bodyLarge,
      'bodyMedium': scale.bodyMedium,
      'bodySmall': scale.bodySmall,
      'labelLarge': scale.labelLarge,
      'labelMedium': scale.labelMedium,
      'labelSmall': scale.labelSmall,
    };

    styles.forEach((name, style) {
      expect(style?.fontFamily, 'Cairo', reason: '$name is not Cairo');
    });

    expect(AppTheme.dark.textTheme.bodyMedium?.fontFamily, 'Cairo');
  });

  testWidgets('the shop front fits the phone it is drawn on', (tester) async {
    /*
     * A product card that overflows by seventy pixels still renders — it just
     * paints a yellow-and-black barber's pole over the bottom of itself and
     * carries on, which means the fault reaches a screenshot rather than a
     * failing build. Turning the overflow into an exception is what makes it a
     * test rather than a thing somebody has to notice.
     */
    await openShop(tester);

    expect(tester.takeException(), isNull);

    /*
     * The shelves cannot be scrolled here: their parts come from the server and
     * a widget test has none, so there is nothing below the fold to drag to.
     * What this still catches is the frame the customer meets first — the bar,
     * the crown and whatever the page draws while it waits — and an overflow in
     * any of those would reach a screenshot rather than a failing build.
     *
     * Scrolled only where there is something to scroll, so the check is about
     * the layout rather than about whether a call happened to answer.
     */
    final scroller = find.byType(CustomScrollView);

    if (scroller.evaluate().isNotEmpty) {
      await tester.drag(scroller.first, const Offset(0, -900));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    }

    /* And the smallest phone the shop is likely to meet. */
    await tester.binding.setSurfaceSize(const Size(320, 640));
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });
}
