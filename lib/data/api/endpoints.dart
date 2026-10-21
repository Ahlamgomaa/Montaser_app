/// Every path the app calls, written once.
///
/// These mirror `routes/api/v1/store.php` on the server and nothing else. Kept
/// as constants so a rename on the server is a compile error here rather than a
/// 404 a customer finds — and so the whole surface of what this app talks to
/// can be read in one screenful.
///
/// None of them carry the version or the host. Both live in [ApiConfig], which
/// is what lets the same build point at production, staging or a laptop.
abstract final class Api {
  // ---- open to anybody ----

  static const home = 'home';
  static const categories = 'categories';
  static const brands = 'brands';
  static const governorates = 'governorates';
  static const products = 'products';

  static String product(String slug) => 'products/$slug';

  // ---- the door ----

  static const register = 'auth/register';
  static const login = 'auth/login';
  static const me = 'auth/me';
  static const password = 'auth/password';
  static const logout = 'auth/logout';
  static const logoutAll = 'auth/logout-all';

  // ---- the basket ----

  static const cart = 'cart';
  static const cartCoupon = 'cart/coupon';
  static const cartShipping = 'cart/shipping';

  static String cartLine(int itemId) => 'cart/$itemId';

  // ---- turning it into an order ----

  static const checkout = 'checkout';
  static const checkoutAddress = 'checkout/address';

  // ---- and what became of it ----

  static const orders = 'orders';

  static String order(int id) => 'orders/$id';

  // ---- their own corner ----

  static const addresses = 'addresses';

  static String address(int id) => 'addresses/$id';

  static String addressDefault(int id) => 'addresses/$id/default';

  static const wishlist = 'wishlist';

  static String wishlistItem(int itemId) => 'wishlist/$itemId';

  static String review(int itemId) => 'products/$itemId/review';
}
