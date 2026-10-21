import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/token_store.dart';
import 'auth_repository.dart';
import 'basket_repository.dart';
import 'catalogue_repository.dart';
import 'shop_repository.dart';

/// The one client, and the repositories that share it.
///
/// A plain holder rather than a dependency-injection package. There is one of
/// each of these for the life of the app, they are created in a fixed order,
/// and nothing about that needs a container to describe it — a locator would be
/// a layer of indirection standing in front of six lines.
///
/// It exists at all so that no widget ever constructs an [ApiClient]. One
/// client means one place holding the connection pool and one place that knows
/// what a rejected token means.
class Repositories {
  Repositories._(this.api)
    : catalogue = CatalogueRepository(api),
      auth = AuthRepository(api, TokenStore.instance),
      basket = BasketRepository(api),
      checkout = CheckoutRepository(api),
      orders = OrderRepository(api),
      account = AccountRepository(api);

  static Repositories? _made;

  static Repositories get instance {
    return _made ??= Repositories._(ApiClient());
  }

  final ApiClient api;
  final CatalogueRepository catalogue;
  final AuthRepository auth;
  final BasketRepository basket;
  final CheckoutRepository checkout;
  final OrderRepository orders;
  final AccountRepository account;

  /// Everything that must happen before the first frame.
  ///
  /// Both reads are from disk and both are needed by the first screen — the
  /// address to call and the token to call it with — so they happen together
  /// while the splash is showing rather than as a stutter afterwards.
  static Future<void> wake() async {
    await Future.wait([
      ApiConfig.instance.wake(),
      TokenStore.instance.wake(),
    ]);
  }

  /// Swap the client, for tests.
  static void useForTesting(ApiClient client) {
    _made = Repositories._(client);
  }
}
