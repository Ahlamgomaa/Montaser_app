import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dialogs close themselves, and nothing else.
///
/// This exists because of a bug that shipped: a confirm dialog written as
///
///     showDialog(context: context, builder: (_) => AlertDialog(
///       actions: [TextButton(onPressed: () => Navigator.pop(context))],
///     ))
///
/// discards the builder's context, so `context` inside the button is the
/// *page's*. Tapping either button popped the page rather than the dialog — and
/// on a page at the root of the shell there is nothing underneath, so the app
/// closed and left a black window. The customer pressed "sign out" and the shop
/// vanished.
///
/// It compiles, it analyses clean, and it looks right at a glance. The only
/// thing that catches it is asking what is still on the screen afterwards.
void main() {
  testWidgets('a confirm dialog pops itself and leaves the page', (
    tester,
  ) async {
    bool? answer;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (page) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  answer = await showDialog<bool>(
                    context: page,
                    /*
                     * The shape every dialog in this app must use: the
                     * builder's own context, popped through `Navigator.of`.
                     */
                    builder: (dialog) => AlertDialog(
                      title: const Text('تسجيل الخروج؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialog).pop(false),
                          child: const Text('تراجع'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(dialog).pop(true),
                          child: const Text('خروج'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الخروج؟'), findsOneWidget);

    await tester.tap(find.text('خروج'));
    await tester.pumpAndSettle();

    /* The dialog is gone, the answer came back… */
    expect(find.text('تسجيل الخروج؟'), findsNothing);
    expect(answer, isTrue);

    /* …and the page underneath is still there, which is the whole point. */
    expect(find.text('افتح'), findsOneWidget);
  });
}
