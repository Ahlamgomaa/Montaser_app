import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:montaser_app/app/montaser_app.dart';
import 'package:montaser_app/app/router.dart';
import 'package:montaser_app/core/theme/app_theme.dart';
import 'package:montaser_app/data/api/api_client.dart';
import 'package:montaser_app/data/api/token_store.dart';
import 'package:montaser_app/data/repositories/repositories.dart';
import 'package:montaser_app/data/store/session_store.dart';
import 'package:montaser_app/features/auth/sign_in_page.dart';
import 'package:montaser_app/features/product/widgets/review_sheet.dart';
import 'package:montaser_app/features/product/widgets/verdict_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The fixes from the audit, each held to what it was meant to change.
void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  /// A server that answers every call with an empty success, and `me` with
  /// whatever [me] says. Records the requests it saw.
  MockClient server(List<http.BaseRequest> seen, {Object? me}) {
    return MockClient((request) async {
      seen.add(request);

      final path = request.url.path;
      final Object? data = path.endsWith('/auth/me')
          ? me
          : path.endsWith('/home') || path.endsWith('/addresses')
          ? <String, dynamic>{}
          : <dynamic>[];

      return http.Response(
        jsonEncode({'success': true, 'data': data}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
  }

  Future<void> fresh({
    Map<String, Object> plain = const {},
    Map<String, String> secure = const {},
    required MockClient client,
  }) async {
    SharedPreferences.setMockInitialValues({...plain});
    FlutterSecureStorage.setMockInitialValues({...secure});
    TokenStore.instance.resetForTesting();
    Repositories.useForTesting(ApiClient(over: client));
  }

  group('token storage', () {
    test('an old plain-text token moves to the secure store', () async {
      await fresh(plain: {'auth.token': 'old-token'}, client: server([]));

      expect(await TokenStore.instance.read(), 'old-token');

      final plain = await SharedPreferences.getInstance();
      expect(plain.getString('auth.token'), isNull);
      expect(
        await const FlutterSecureStorage().read(key: 'auth.token'),
        'old-token',
      );
    });

    test('signing out removes the token from both stores', () async {
      await fresh(
        plain: {'auth.token': 'left-behind'},
        secure: {'auth.token': 'current'},
        client: server([]),
      );

      await TokenStore.instance.drop();

      expect(await TokenStore.instance.read(), isNull);
      expect(
        (await SharedPreferences.getInstance()).getString('auth.token'),
        isNull,
      );
      expect(
        await const FlutterSecureStorage().read(key: 'auth.token'),
        isNull,
      );
    });
  });

  group('fingerprint lock', () {
    test(
      'a closed lock sends no token, and opening it sends it again',
      () async {
        final seen = <http.BaseRequest>[];

        await fresh(
          secure: {'auth.token': 'secret'},
          client: server(seen, me: {'id': 7, 'name': 'سامي', 'phone': '0100'}),
        );

        final shop = Repositories.instance;
        final session = SessionStore(
          shop.auth,
          shop.account,
          TokenStore.instance,
        );

        session.lockAway();
        await shop.api.get('wishlist');

        expect(seen.last.headers['Authorization'], isNull);
        expect(session.isSignedIn, isFalse);
        expect(session.isWaking, isFalse);
        /* Kept, not thrown away: nothing was revoked. */
        expect(TokenStore.instance.hasToken, isTrue);

        await session.unlock();

        expect(seen.last.headers['Authorization'], 'Bearer secret');
        expect(session.isSignedIn, isTrue);
      },
    );
  });

  /*
   * The router is one object for the life of the test run, as it is for the
   * life of the app: its location carries from one test to the next. So the
   * splash, which only the first opening shows, is tested first, and the
   * routes are walked in one sequence rather than in tests that would each
   * inherit the last one's page.
   */
  testWidgets('the splash leaves even when waking fails unexpectedly', (
    tester,
  ) async {
    /* `me` answers a list where an account was expected: a TypeError. */
    await fresh(
      secure: {'auth.token': 'secret'},
      client: server([], me: <dynamic>[]),
    );

    await tester.pumpWidget(const MontaserApp());
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump(const Duration(milliseconds: 500));

    /* Reported, not swallowed — and the shop is open behind it. */
    expect(tester.takeException(), isA<TypeError>());
    expect(find.text('السلة'), findsWidgets);
  });

  testWidgets('a guest keeps the shop, is sent to sign in for account '
      'screens, and is told the truth about a forgotten password', (
    tester,
  ) async {
    await fresh(client: server([]));

    await tester.pumpWidget(const MontaserApp());

    /*
     * Launched again, as the app is: through the splash, which is what wakes
     * the session. The router kept the last test's page, not its start.
     */
    AppRouter.router.go('/splash');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump(const Duration(milliseconds: 500));

    Future<void> visit(String path) async {
      AppRouter.router.go(path);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    /* Open to anybody. */
    await visit('/account');
    expect(find.byType(SignInPage), findsNothing);

    /* Not without an account — and the way back is remembered. */
    await visit('/checkout');
    expect(
      tester.widget<SignInPage>(find.byType(SignInPage)).from,
      '/checkout',
    );

    await visit('/account/orders');
    expect(
      tester.widget<SignInPage>(find.byType(SignInPage)).from,
      '/account/orders',
    );

    /* No claim that a reset link was sent; the shop is who resets it. */
    await tester.tap(find.text('نسيت كلمة المرور؟'));
    await tester.pump();

    expect(find.textContaining('أرسلنا'), findsNothing);
    expect(find.textContaining('لاستعادة كلمة المرور'), findsOneWidget);
  });

  testWidgets('the review button opens the review sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: VerdictList(
              itemId: 12,
              verdicts: [],
              rating: null,
              count: null,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('اكتب تقييمك'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewSheet), findsOneWidget);
  });
}
