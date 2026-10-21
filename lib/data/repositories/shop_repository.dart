import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/account.dart';
import '../models/basket.dart';
import '../models/catalogue.dart';
import '../models/order.dart';

/// Turning a basket into an order.
class CheckoutRepository {
  const CheckoutRepository(this._api);

  final ApiClient _api;

  /// What the checkout screen needs: the addresses, which one is chosen, the
  /// delivery options for it, and how the shop will take payment.
  Future<CheckoutView> view() async {
    final data = await _api.get(Api.checkout);

    return CheckoutView.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  /// Say where it goes.
  ///
  /// The delivery options come back with the answer, because they depend on the
  /// governorate — quoting a charge before an address is chosen would be
  /// quoting for a place nobody named.
  Future<CheckoutView> chooseAddress(int placeId) async {
    final data = await _api.put(
      Api.checkoutAddress,
      body: {'address_id': placeId},
    );

    return CheckoutView.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<Order> place({
    required int placeId,
    required String paymentMethod,
    String? note,
  }) async {
    final data = await _api.post(
      Api.checkout,
      body: {
        'address_id': placeId,
        'payment_method': paymentMethod,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );

    return Order.fromJson(data as Map<String, dynamic>? ?? const {});
  }
}

/// What became of the orders.
class OrderRepository {
  const OrderRepository(this._api);

  final ApiClient _api;

  Future<List<Order>> mine({int page = 1}) async {
    final paged = await _api.page(Api.orders, query: {'page': page});

    return paged.rows
        .whereType<Map<String, dynamic>>()
        .map(Order.fromJson)
        .toList(growable: false);
  }

  Future<Order> one(int id) async {
    final data = await _api.get(Api.order(id));

    return Order.fromJson(data as Map<String, dynamic>? ?? const {});
  }
}

/// The customer's own corner: addresses, wish list, reviews.
class AccountRepository {
  const AccountRepository(this._api);

  final ApiClient _api;

  /// The address book, with the governorates it may point at.
  Future<AddressBook> addresses() async {
    final data = await _api.get(Api.addresses);

    return AddressBook.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<Place> addAddress(Place place) async {
    final data = await _api.post(Api.addresses, body: place.asBody());

    return Place.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<Place> updateAddress(Place place) async {
    final data = await _api.put(Api.address(place.id), body: place.asBody());

    return Place.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<Place> makeDefault(int placeId) async {
    final data = await _api.put(Api.addressDefault(placeId));

    return Place.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<void> removeAddress(int placeId) =>
      _api.delete(Api.address(placeId));

  Future<List<Part>> wishlist() async {
    final data = await _api.get(Api.wishlist);

    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Part.fromJson)
        .toList(growable: false);
  }

  /// Returns whether the part is now kept.
  Future<bool> toggleKept(int itemId) async {
    final data = await _api.post(Api.wishlistItem(itemId));

    if (data is Map<String, dynamic>) {
      return data['kept'] == true;
    }

    return false;
  }

  /// Leave a review. It is held for moderation, so nothing appears at once.
  Future<String?> review({
    required int itemId,
    required int rating,
    String? title,
    required String body,
  }) async {
    final envelope = await _api.envelope(
      'POST',
      Api.review(itemId),
      body: {
        'rating': rating,
        if (title != null && title.isNotEmpty) 'title': title,
        'body': body,
      },
    );

    return envelope['message'] as String?;
  }
}
