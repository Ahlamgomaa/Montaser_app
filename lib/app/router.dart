import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_page.dart';
import '../features/account/place_form_page.dart';
import '../features/account/places_page.dart';
import '../features/account/profile_page.dart';
import '../features/account/wishlist_page.dart';
import '../features/auth/register_page.dart';
import '../features/auth/sign_in_page.dart';
import '../features/basket/basket_page.dart';
import '../features/catalogue/aisles_page.dart';
import '../features/catalogue/browse_page.dart';
import '../features/catalogue/makers_page.dart';
import '../features/catalogue/search_page.dart';
import '../features/checkout/checkout_page.dart';
import '../features/checkout/placed_page.dart';
import '../features/home/home_page.dart';
import '../features/orders/order_page.dart';
import '../features/orders/orders_page.dart';
import '../features/product/part_page.dart';
import '../features/splash/splash_page.dart';
import 'app_scope.dart';
import 'routes.dart';
import 'shell.dart';

/// Every screen, and how to reach it.
///
/// The five tabs are branches of a [StatefulShellRoute], so each keeps its own
/// stack: a customer who browsed three levels into the catalogue, looked at the
/// basket and came back finds the catalogue where they left it.
///
/// Nearly everything lives *inside* a branch, which is what keeps the bar on
/// screen while somebody browses, opens a part, reads their orders or edits an
/// address. All of that is still shopping, and the way to the rest of the shop
/// should not vanish because they went one level in.
///
/// Four screens sit outside, on the root navigator, and cover the bar: the
/// splash, the checkout, the order confirmation and the two auth forms. Each is
/// a single task with one way forward and its own action at the foot of the
/// screen. Leaving the tabs up there would invite somebody to wander off
/// mid-payment, and would stack a second bar under the first.
abstract final class AppRouter {
  static final _root = GlobalKey<NavigatorState>();
  static final _shopTab = GlobalKey<NavigatorState>();
  static final _aisleTab = GlobalKey<NavigatorState>();
  static final _basketTab = GlobalKey<NavigatorState>();
  static final _keptTab = GlobalKey<NavigatorState>();
  static final _accountTab = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _root,
    initialLocation: Path.splash,
    redirect: _guard,
    refreshListenable: AppScope.account,
    routes: [
      /*
       * Outside everything. `go` rather than `push` takes the app off it, so it
       * leaves no route behind for back to land on — nobody should ever see the
       * mark twice.
       */
      GoRoute(
        parentNavigatorKey: _root,
        path: Path.splash,
        builder: (context, state) => const SplashPage(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigation) => Shell(navigation: navigation),
        branches: [
          /* ---- the shop, and everything you can browse into ---- */
          StatefulShellBranch(
            navigatorKey: _shopTab,
            routes: [
              GoRoute(
                path: Path.home,
                builder: (context, state) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'browse',
                    builder: (context, state) => BrowsePage(
                      /* Keys, because that is what the server filters on. */
                      aisleId: int.tryParse(
                        state.uri.queryParameters['aisle'] ?? '',
                      ),
                      makerId: int.tryParse(
                        state.uri.queryParameters['maker'] ?? '',
                      ),
                      /* Carried so the crown can name it without a fetch. */
                      title: state.uri.queryParameters['title'],
                      query: state.uri.queryParameters['q'],
                    ),
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (context, state) => const SearchPage(),
                  ),
                  GoRoute(
                    path: 'part/:slug',
                    builder: (context, state) =>
                        PartPage(slug: state.pathParameters['slug'] ?? ''),
                  ),
                ],
              ),
            ],
          ),

          /* ---- the departments ---- */
          StatefulShellBranch(
            navigatorKey: _aisleTab,
            routes: [
              GoRoute(
                path: Path.aisles,
                builder: (context, state) => const AislesPage(),
                routes: [
                  GoRoute(
                    path: 'makers',
                    builder: (context, state) => const MakersPage(),
                  ),
                ],
              ),
            ],
          ),

          /* ---- the basket ---- */
          StatefulShellBranch(
            navigatorKey: _basketTab,
            routes: [
              GoRoute(
                path: Path.basket,
                builder: (context, state) => const BasketPage(),
              ),
            ],
          ),

          /* ---- what they kept ---- */
          StatefulShellBranch(
            navigatorKey: _keptTab,
            routes: [
              GoRoute(
                path: Path.kept,
                builder: (context, state) => const WishlistPage(),
              ),
            ],
          ),

          /* ---- their own corner ---- */
          StatefulShellBranch(
            navigatorKey: _accountTab,
            routes: [
              GoRoute(
                path: Path.account,
                builder: (context, state) => const AccountPage(),
                routes: [
                  GoRoute(
                    path: 'orders',
                    builder: (context, state) => const OrdersPage(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => OrderPage(
                          id: int.tryParse(
                                state.pathParameters['id'] ?? '',
                              ) ??
                              0,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const ProfilePage(),
                  ),
                  GoRoute(
                    path: 'places',
                    builder: (context, state) => const PlacesPage(),
                    routes: [
                      GoRoute(
                        path: 'form',
                        builder: (context, state) => PlaceFormPage(
                          id: int.tryParse(
                            state.uri.queryParameters['id'] ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      /* ---- the single-task screens, over the bar ---- */
      GoRoute(
        parentNavigatorKey: _root,
        path: Path.checkout,
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        parentNavigatorKey: _root,
        path: Path.placed,
        builder: (context, state) =>
            PlacedPage(
              orderId:
                  int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0,
              reference: state.uri.queryParameters['ref'] ?? '',
            ),
      ),
      GoRoute(
        parentNavigatorKey: _root,
        path: Path.signIn,
        builder: (context, state) =>
            SignInPage(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        parentNavigatorKey: _root,
        path: Path.register,
        builder: (context, state) => const RegisterPage(),
      ),
    ],
  );

  /// The screens that belong to an account.
  ///
  /// Browsing, the basket tab, the wish list tab and the account tab itself
  /// stay open to anybody: each of those already says, in its own place, that
  /// signing in is what it needs. These are the ones that only make sense for
  /// somebody signed in — and that a link, a back button or a lock closing
  /// underneath could otherwise land a guest on.
  static bool _needsAccount(String path) =>
      path == Path.checkout ||
      path == Path.placed ||
      path.startsWith('${Path.account}/');

  /// Sends a guest who reaches one of them to sign in, and back afterwards.
  ///
  /// Not while the session is still waking: the splash has not yet asked the
  /// server who the stored token belongs to, and a guard that answered first
  /// would send a signed-in customer to the sign-in page. [AppScope.account]
  /// runs this again the moment the answer arrives.
  ///
  /// The server still refuses these calls without a token; this is what
  /// stops the screens being shown at all, not what protects the data.
  static String? _guard(BuildContext context, GoRouterState state) {
    final session = AppScope.session(context);

    if (session.isWaking ||
        session.isSignedIn ||
        !_needsAccount(state.uri.path)) {
      return null;
    }

    return Uri(
      path: Path.signIn,
      queryParameters: {'from': state.uri.toString()},
    ).toString();
  }
}
