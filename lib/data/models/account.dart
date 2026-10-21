import 'package:flutter/foundation.dart';

import 'catalogue.dart' show Governorate, asInt, asText;

/// The person shopping.
@immutable
class Shopper {
  const Shopper({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.company,
    this.code,
    this.governorate,
    this.governorateId,
    this.since,
  });

  factory Shopper.fromJson(Map<String, dynamic> json) {
    return Shopper(
      id: asInt(json['id']),
      name: asText(json['name']),
      phone: asText(json['phone']),
      email: json['email'] as String?,
      company: json['company'] as String?,
      code: json['code'] as String?,
      governorate: json['governorate'] as String?,
      governorateId: json['governorate_id'] is num
          ? asInt(json['governorate_id'])
          : null,
      since: DateTime.tryParse(asText(json['since'])),
    );
  }

  final int id;
  final String name;

  /// The telephone number is the account. Not the email: a workshop in Tanta
  /// has a phone long before it has an inbox, and asking for an address that
  /// half the customers do not check is how an order goes unconfirmed.
  final String phone;

  final String? email;

  /// Most customers here are trades — a workshop, a contractor, a maintenance
  /// company — and they expect their own name on the invoice.
  final String? company;

  /// The shop's own reference for them, when it has issued one.
  final String? code;

  final String? governorate;
  final int? governorateId;

  /// The day they opened the account, where the server said.
  final DateTime? since;

  /// The letters drawn when there is no photograph. There is never a
  /// photograph.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));

    if (words.isEmpty || words.first.isEmpty) {
      return '؟';
    }

    if (words.length < 2) {
      return words.first.substring(0, 1);
    }

    return '${words[0][0]}${words[1][0]}';
  }
}

/// Somewhere to send it.
@immutable
class Place {
  const Place({
    required this.id,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.governorate,
    required this.governorateId,
    required this.city,
    required this.street,
    this.line,
    this.building,
    this.flat,
    this.landmark,
    this.isDefault = false,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: asInt(json['id']),
      label: asText(json['label']),
      /*
       * The server assembles the one-line form itself. Read rather than rebuilt
       * here, so the address printed on the invoice and the address shown in
       * the app are the same string in the same order.
       */
      line: json['line'] as String?,
      recipient: asText(json['recipient']),
      phone: asText(json['phone']),
      governorate: asText(json['governorate']),
      governorateId: asInt(json['governorate_id']),
      city: asText(json['city']),
      street: asText(json['street']),
      building: json['building'] as String?,
      flat: json['flat'] as String?,
      landmark: json['landmark'] as String?,
      isDefault: json['is_default'] == true,
    );
  }

  final int id;

  /// What the customer calls it: `الورشة`, `البيت`, `المخزن`. Their word, not a
  /// type chosen from a list — it is the only part of an address a person
  /// actually recognises at a glance.
  final String label;

  final String? line;
  final String recipient;
  final String phone;
  final String governorate;
  final int governorateId;
  final String city;
  final String street;
  final String? building;
  final String? flat;

  /// A landmark. In much of Egypt this is what actually gets a driver there,
  /// and leaving it out is how a delivery ends in a phone call.
  final String? landmark;

  final bool isDefault;

  /// The address on one line — the server's version when it sent one, and only
  /// otherwise assembled here.
  String get oneLine {
    if (line != null && line!.trim().isNotEmpty) {
      return line!;
    }

    return <String>[
      street,
      if (building != null && building!.isNotEmpty) 'عمارة $building',
      if (flat != null && flat!.isNotEmpty) 'شقة $flat',
      city,
      governorate,
    ].join('، ');
  }

  /// What goes on the wire when adding or editing one.
  Map<String, dynamic> asBody() => {
    'label': label,
    'recipient': recipient,
    'phone': phone,
    'governorate_id': governorateId,
    'city': city,
    'street': street,
    'building': building ?? '',
    'flat': flat ?? '',
    'landmark': landmark ?? '',
    'is_default': isDefault,
  };
}

/// The address book, and the places it may point at.
///
/// Both arrive in one reply, because a form that offers governorates needs them
/// at the same moment it needs the addresses.
@immutable
class AddressBook {
  const AddressBook({required this.places, required this.governorates});

  factory AddressBook.fromJson(Map<String, dynamic> json) {
    return AddressBook(
      places: _rows(json['addresses']).map(Place.fromJson).toList(),
      governorates: _rows(json['governorates'])
          .map(Governorate.fromJson)
          .toList(),
    );
  }

  static const empty = AddressBook(places: [], governorates: []);

  final List<Place> places;
  final List<Governorate> governorates;

  Place? get chosen {
    for (final place in places) {
      if (place.isDefault) {
        return place;
      }
    }

    return places.isEmpty ? null : places.first;
  }

  static List<Map<String, dynamic>> _rows(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw.whereType<Map<String, dynamic>>().toList();
  }
}
