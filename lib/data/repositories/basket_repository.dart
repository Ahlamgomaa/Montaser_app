import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/basket.dart';

/// The basket, which lives on the server.
///
/// Every method returns the whole basket rather than the thing that changed.
/// That is the server's design and the right one: adding a part can move a
/// total, earn free delivery, or invalidate a coupon, and a reply that said
/// only "added" would leave the app guessing at four other numbers.
class BasketRepository {
  const BasketRepository(this._api);

  final ApiClient _api;

  Future<Basket> read() async {
    final data = await _api.get(Api.cart);

    return Basket.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<Basket> add({required int itemId, int quantity = 1}) async {
    final data = await _api.post(
      Api.cart,
      body: {'item_id': itemId, 'quantity': quantity},
    );

    return Basket.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  /// Set a line to an exact count.
  ///
  /// Zero is not sent here. The server treats a quantity of nothing as a
  /// validation fault, and rightly — "none of this" is a removal, and saying so
  /// plainly is better than a quantity that means something else.
  Future<Basket> setQuantity({
    required int itemId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      return remove(itemId);
    }

    final data = await _api.put(
      Api.cartLine(itemId),
      body: {'quantity': quantity},
    );

    return Basket.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<Basket> remove(int itemId) async {
    final data = await _api.delete(Api.cartLine(itemId));

    return Basket.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<Basket> clear() async {
    final data = await _api.delete(Api.cart);

    return Basket.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<Basket> applyCoupon(String code) async {
    final data = await _api.post(Api.cartCoupon, body: {'code': code});

    return Basket.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<Basket> removeCoupon() async {
    final data = await _api.delete(Api.cartCoupon);

    return Basket.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<Basket> chooseShipping(int methodId) async {
    final data = await _api.put(
      Api.cartShipping,
      body: {'shipping_method_id': methodId},
    );

    return Basket.fromJson(data as Map<String, dynamic>? ?? const {});
  }
}
