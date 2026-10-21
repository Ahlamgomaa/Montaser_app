import 'package:flutter/foundation.dart';

import 'catalogue.dart' show asDouble, asInt, asText;

/// One part, and how many of it.
@immutable
class BasketLine {
  const BasketLine({
    required this.itemId,
    required this.name,
    required this.code,
    required this.unit,
    this.aisle = '',
    this.brand,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.free,
    this.slug,
    this.imageUrl,
  });

  factory BasketLine.fromJson(Map<String, dynamic> json) {
    return BasketLine(
      itemId: asInt(json['item_id']),
      slug: json['slug'] as String?,
      name: asText(json['name']),
      code: asText(json['code']),
      imageUrl: json['image'] as String?,
      unit: asText(json['unit']),
      aisle: asText(json['category']),
      brand: json['brand'] as String?,
      quantity: asDouble(json['quantity']).round(),
      unitPrice: asDouble(json['unit_price']),
      lineTotal: asDouble(json['line_total']),
      free: asDouble(json['available']),
    );
  }

  final int itemId;
  final String? slug;
  final String name;
  final String code;
  final String? imageUrl;
  final String unit;

  /// The aisle it came from and who makes it.
  ///
  /// Not decoration: a basket of six part numbers is unreadable without them,
  /// and somebody checking an order before paying is checking exactly this.
  final String aisle;
  final String? brand;

  final int quantity;
  final double unitPrice;

  /// Sent by the server rather than multiplied here. The app never becomes the
  /// second place a total is worked out — that is how a basket and an invoice
  /// end up disagreeing over a rounded piastre.
  final double lineTotal;

  /// What could be ordered of this part right now, so the stepper knows its
  /// ceiling without asking again.
  final double free;
}

/// What the basket costs, broken down.
@immutable
class Totals {
  const Totals({
    required this.goods,
    required this.discount,
    required this.shipping,
    required this.total,
    this.shippingDiscount = 0,
    this.currency = '',
  });

  factory Totals.fromJson(Map<String, dynamic> json) {
    return Totals(
      goods: asDouble(json['goods']),
      discount: asDouble(json['discount']),
      shipping: asDouble(json['shipping']),
      shippingDiscount: asDouble(json['shipping_discount']),
      total: asDouble(json['total']),
      currency: asText(json['currency']),
    );
  }

  static const zero = Totals(goods: 0, discount: 0, shipping: 0, total: 0);

  final double goods;
  final double discount;
  final double shipping;

  /// What came off the delivery charge, when the shop took something off it.
  final double shippingDiscount;

  final double total;
  final String currency;

  bool get hasDiscount => discount > 0;
}

/// The coupon that is on, if one is.
@immutable
class Coupon {
  const Coupon({required this.code, required this.discount});

  factory Coupon.fromJson(Map<String, dynamic> json) =>
      Coupon(code: asText(json['code']), discount: asDouble(json['discount']));

  final String code;
  final double discount;
}

/// A way of getting the parts there.
@immutable
class ShippingChoice {
  const ShippingChoice({
    required this.id,
    required this.name,
    required this.charge,
    this.estimate,
    this.isFree = false,
    this.chosen = false,
  });

  factory ShippingChoice.fromJson(Map<String, dynamic> json) {
    return ShippingChoice(
      id: asInt(json['id']),
      name: asText(json['name']),
      /* How long it takes, in the shop's own words rather than a number. */
      estimate: json['estimate'] as String?,
      charge: asDouble(json['charge']),
      isFree: json['is_free'] == true || asDouble(json['charge']) <= 0,
      chosen: json['chosen'] == true,
    );
  }

  final int id;
  final String name;
  final String? estimate;
  final double charge;
  final bool isFree;
  final bool chosen;
}

/// A way of paying, as the shop offers it.
///
/// Read from the server, not an enum here. Which methods are on is a decision
/// the shop makes and changes — a card gateway goes down, cash on delivery is
/// suspended for a governorate — and an app with the list compiled in shows
/// options that do not work.
@immutable
class PayChoiceOption {
  const PayChoiceOption({
    required this.value,
    required this.label,
    this.hint,
    this.available = true,
  });

  factory PayChoiceOption.fromJson(Map<String, dynamic> json) {
    return PayChoiceOption(
      value: asText(json['value']),
      label: asText(json['label']),
      hint: json['hint'] as String? ?? json['note'] as String?,
      available: json['available'] != false && json['enabled'] != false,
    );
  }

  final String value;
  final String label;
  final String? hint;
  final bool available;
}

/// The basket, as the server holds it.
@immutable
class Basket {
  const Basket({
    required this.id,
    required this.lines,
    required this.totals,
    this.coupon,
    this.shipping,
    this.shortOfFreeShipping,
  });

  factory Basket.fromJson(Map<String, dynamic> json) {
    return Basket(
      id: asInt(json['id']),
      lines: _rows(json['lines']).map(BasketLine.fromJson).toList(),
      totals: Totals.fromJson(
        json['totals'] as Map<String, dynamic>? ?? const {},
      ),
      coupon: json['coupon'] is Map<String, dynamic>
          ? Coupon.fromJson(json['coupon'] as Map<String, dynamic>)
          : null,
      shipping: json['shipping_method'] is Map<String, dynamic>
          ? ShippingChoice.fromJson(
              json['shipping_method'] as Map<String, dynamic>,
            )
          : null,
      shortOfFreeShipping: json['short_of_free_shipping'] is num
          ? asDouble(json['short_of_free_shipping'])
          : null,
    );
  }

  static const empty = Basket(id: 0, lines: [], totals: Totals.zero);

  final int id;
  final List<BasketLine> lines;
  final Totals totals;
  final Coupon? coupon;
  final ShippingChoice? shipping;

  /// How much more is needed for free delivery, when the shop offers it.
  ///
  /// Null means the shop has no such offer, which is different from zero —
  /// zero means it has been earned.
  final double? shortOfFreeShipping;

  bool get isEmpty => lines.isEmpty;

  /// How many pieces, not how many lines. Three of one part is three things in
  /// a bag, and the badge on the tab bar should say so.
  int get pieces => lines.fold(0, (sum, line) => sum + line.quantity);

  int quantityOf(int itemId) {
    for (final line in lines) {
      if (line.itemId == itemId) {
        return line.quantity;
      }
    }

    return 0;
  }

  bool holds(int itemId) => quantityOf(itemId) > 0;

  static List<Map<String, dynamic>> _rows(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw.whereType<Map<String, dynamic>>().toList();
  }
}

/// What the checkout screen needs, in one reply.
@immutable
class CheckoutView {
  const CheckoutView({
    required this.places,
    required this.shippingOptions,
    required this.paymentMethods,
    this.chosenPlaceId,
    this.changed = const [],
  });

  factory CheckoutView.fromJson(Map<String, dynamic> json) {
    return CheckoutView(
      places: Basket._rows(json['addresses']),
      chosenPlaceId: json['chosen_address_id'] is num
          ? asInt(json['chosen_address_id'])
          : null,
      shippingOptions: Basket._rows(json['shipping_options'])
          .map(ShippingChoice.fromJson)
          .toList(),
      paymentMethods: Basket._rows(json['payment_methods'])
          .map(PayChoiceOption.fromJson)
          .toList(),
      /*
       * What moved while the customer was away — a part that sold out, one
       * whose price changed. The checkout must say so before they pay, not
       * after.
       */
      changed: Basket._rows(json['changed'])
          .map((one) => asText(one['message'] ?? one['name']))
          .where((one) => one.isNotEmpty)
          .toList(),
    );
  }

  /// Left as raw rows so the address list is parsed by the one `Place.fromJson`
  /// rather than by a second copy of it living here.
  final List<Map<String, dynamic>> places;

  final int? chosenPlaceId;
  final List<ShippingChoice> shippingOptions;
  final List<PayChoiceOption> paymentMethods;
  final List<String> changed;
}
