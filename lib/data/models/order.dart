import 'package:flutter/foundation.dart';

import 'basket.dart' show Totals;
import 'catalogue.dart' show asDouble, asInt, asText;

/// Where an order has got to.
///
/// Read from the server rather than named by an enum here. The shop owns the
/// journey — how many stops it has, what each is called, and whether this
/// particular order left the road — and an app with four hard-coded stages is
/// an app that lies the day a fifth is added.
@immutable
class OrderStanding {
  const OrderStanding({
    required this.value,
    required this.label,
    required this.step,
    required this.steps,
    this.tone,
    this.wentWrong = false,
  });

  factory OrderStanding.fromJson(Map<String, dynamic> json) {
    return OrderStanding(
      value: asText(json['value']),
      label: asText(json['label']),
      /* How far along the road, and how long the road is. */
      step: asInt(json['step']),
      steps: asInt(json['steps'], 1),
      tone: json['tone'] as String?,
      wentWrong: json['went_wrong'] == true,
    );
  }

  static const unknown = OrderStanding(
    value: '',
    label: '',
    step: 0,
    steps: 1,
  );

  final String value;
  final String label;
  final int step;
  final int steps;

  /// The shop's own word for how this reads — `success`, `warning`, `danger`.
  /// The app maps it to a colour; it does not decide which statuses are good.
  final String? tone;

  final bool wentWrong;

  /// Whether a given stop is behind the order.
  bool reached(int at) => at <= step;

  double get howFar => steps <= 0 ? 0 : (step / steps).clamp(0.0, 1.0);
}

/// What was paid, and what is still owed.
@immutable
class OrderPayment {
  const OrderPayment({
    required this.method,
    required this.status,
    required this.paid,
    required this.due,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      method: asText(json['method']),
      status: asText(json['status']),
      paid: asDouble(json['paid']),
      due: asDouble(json['due']),
    );
  }

  static const unknown = OrderPayment(
    method: '',
    status: '',
    paid: 0,
    due: 0,
  );

  final String method;
  final String status;
  final double paid;
  final double due;

  bool get isSettled => due <= 0;
}

/// Where it went.
@immutable
class Recipient {
  const Recipient({
    required this.name,
    required this.phone,
    required this.address,
    this.governorate,
  });

  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
      name: asText(json['name']),
      phone: asText(json['phone']),
      address: asText(json['address']),
      governorate: json['governorate'] as String?,
    );
  }

  final String name;
  final String phone;
  final String address;
  final String? governorate;

  String get oneLine =>
      governorate == null ? address : '$address، $governorate';
}

/// A line on an order.
///
/// Holds its own name and price rather than pointing at a part. An order is a
/// record of what was agreed on a particular day; if it read today's catalogue
/// then last month's invoice would quietly change when a price did.
@immutable
class OrderLine {
  const OrderLine({
    required this.name,
    required this.code,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.imageUrl,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      name: asText(json['name']),
      code: asText(json['code']),
      quantity: asDouble(json['quantity']).round(),
      unitPrice: asDouble(json['unit_price']),
      lineTotal: asDouble(json['line_total']),
      imageUrl: json['image'] as String?,
    );
  }

  final String name;
  final String code;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? imageUrl;
}

/// Something that happened to the order, with the date it happened.
@immutable
class OrderMoment {
  const OrderMoment({required this.status, required this.label, this.at});

  factory OrderMoment.fromJson(Map<String, dynamic> json) {
    return OrderMoment(
      status: asText(json['status']),
      label: asText(json['label']),
      at: DateTime.tryParse(asText(json['at'])),
    );
  }

  final String status;
  final String label;
  final DateTime? at;
}

/// One stop on the road an order travels.
///
/// Named by the shop and sent with the order, rather than listed here. The shop
/// owns the journey — how many stops it has and what each is called — and an
/// app with four of them written in is an app that lies the day a fifth is
/// added.
@immutable
class OrderStop {
  const OrderStop({required this.value, required this.label});

  factory OrderStop.fromJson(Map<String, dynamic> json) {
    return OrderStop(
      value: asText(json['value']),
      label: asText(json['label']),
    );
  }

  final String value;
  final String label;
}

/// An order.
///
/// The list and the detail screen are served by the same shape: the server
/// sends the extra parts only on the detail call, so [lines] and [recipient]
/// are empty on a card and full on a page. One class rather than two means a
/// card and a page can never disagree about what an order is.
@immutable
class Order {
  const Order({
    required this.id,
    required this.reference,
    required this.placedAt,
    required this.standing,
    required this.payment,
    required this.totals,
    required this.itemsCount,
    this.journey = const [],
    this.lines = const [],
    this.progress = const [],
    this.recipient,
    this.shippingMethod,
    this.expectedFrom,
    this.expectedTo,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: asInt(json['id']),
      reference: asText(json['reference']),
      placedAt: DateTime.tryParse(asText(json['placed_at'])),
      standing: OrderStanding.fromJson(
        json['status'] as Map<String, dynamic>? ?? const {},
      ),
      payment: json['payment'] is Map<String, dynamic>
          ? OrderPayment.fromJson(json['payment'] as Map<String, dynamic>)
          : OrderPayment.unknown,
      totals: Totals.fromJson(
        json['totals'] as Map<String, dynamic>? ?? const {},
      ),
      itemsCount: asInt(json['items_count']),
      journey: _rows(json['journey']).map(OrderStop.fromJson).toList(),
      lines: _rows(json['lines']).map(OrderLine.fromJson).toList(),
      progress: _rows(json['progress']).map(OrderMoment.fromJson).toList(),
      recipient: json['recipient'] is Map<String, dynamic>
          ? Recipient.fromJson(json['recipient'] as Map<String, dynamic>)
          : null,
      shippingMethod: json['shipping_method'] as String?,
      expectedFrom: _expected(json['expected'], 'from'),
      expectedTo: _expected(json['expected'], 'to'),
    );
  }

  final int id;
  final String reference;
  final DateTime? placedAt;
  final OrderStanding standing;
  final OrderPayment payment;
  final Totals totals;
  final int itemsCount;

  /// Every stop on the road, the ones ahead included.
  final List<OrderStop> journey;

  /// Sent on the detail call only.
  final List<OrderLine> lines;
  final List<OrderMoment> progress;
  final Recipient? recipient;
  final String? shippingMethod;

  /// The window the shop expects to deliver in, from the method chosen.
  ///
  /// Absent on an order that went wrong, and absent where the shop has not
  /// said — a date invented here would be a promise nobody made.
  final DateTime? expectedFrom;
  final DateTime? expectedTo;

  bool get wentWrong => standing.wentWrong;

  /// One end of the delivery window, where the shop gave one.
  static DateTime? _expected(Object? block, String end) {
    if (block is! Map<String, dynamic>) {
      return null;
    }

    return DateTime.tryParse(asText(block[end]));
  }

  /// When a stop was reached, or null if the order has not got there.
  ///
  /// Read off the milestones the server sent rather than guessed from the
  /// order's date: the gap between confirmed and shipped is the shop's to
  /// report, and an app that invented it would be inventing a delivery date.
  DateTime? reachedAt(String stop) {
    for (final moment in progress) {
      if (moment.status == stop) {
        return moment.at;
      }
    }

    return null;
  }

  bool get isDetailed => lines.isNotEmpty || recipient != null;

  int get pieces => lines.isEmpty
      ? itemsCount
      : lines.fold(0, (sum, line) => sum + line.quantity);

  static List<Map<String, dynamic>> _rows(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw.whereType<Map<String, dynamic>>().toList();
  }
}
