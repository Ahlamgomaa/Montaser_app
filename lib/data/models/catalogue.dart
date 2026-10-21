import 'package:flutter/foundation.dart';

/// Reading a number the server sent.
///
/// JSON gives an int where the value happens to be whole and a double where it
/// does not, so `as double` throws on every round price the shop has. These
/// three make that a non-event.
double asDouble(dynamic value, [double fallback = 0]) =>
    value is num ? value.toDouble() : fallback;

int asInt(dynamic value, [int fallback = 0]) =>
    value is num ? value.toInt() : fallback;

String asText(dynamic value, [String fallback = '']) =>
    value is String ? value : fallback;

/// A department of the shop.
@immutable
class Aisle {
  const Aisle({
    required this.id,
    required this.name,
    required this.slug,
    this.count,
  });

  factory Aisle.fromJson(Map<String, dynamic> json) {
    return Aisle(
      id: asInt(json['id']),
      name: asText(json['name']),
      slug: asText(json['slug']),
      count: json['count'] is num ? asInt(json['count']) : null,
    );
  }

  final int id;
  final String name;
  final String slug;

  /// How many parts are in it, when the server says. Null is the ordinary case
  /// today — the categories endpoint sends id, name and slug — and the tile
  /// simply leaves the line out rather than printing a zero that would read as
  /// an empty department.
  final int? count;
}

/// A maker.
@immutable
class Maker {
  const Maker({required this.id, required this.name, this.origin});

  factory Maker.fromJson(Map<String, dynamic> json) {
    return Maker(
      id: asInt(json['id']),
      name: asText(json['name']),
      origin: json['origin'] is String ? json['origin'] as String : null,
    );
  }

  final int id;
  final String name;
  final String? origin;

  /// The two letters drawn in the badge when there is no logo — which is most
  /// of the time, and so is treated as the ordinary case rather than the broken
  /// one.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));

    if (words.isEmpty || words.first.isEmpty) {
      return '؟';
    }

    if (words.length == 1) {
      return words.first.length <= 2 ? words.first : words.first.substring(0, 2);
    }

    return '${words[0][0]}${words[1][0]}';
  }
}

/// Somewhere the shop delivers.
@immutable
class Governorate {
  const Governorate({required this.id, required this.name});

  factory Governorate.fromJson(Map<String, dynamic> json) =>
      Governorate(id: asInt(json['id']), name: asText(json['name']));

  final int id;
  final String name;
}

/// How much of a part the customer may actually order.
///
/// Three states rather than a number, because the number alone does not tell a
/// screen what to say. `plenty` says nothing, `few` creates urgency honestly,
/// and `none` disables the button — three different designs.
enum Availability {
  plenty,
  few,
  none;

  static Availability of(double free) {
    if (free <= 0) {
      return Availability.none;
    }

    return free <= 5 ? Availability.few : Availability.plenty;
  }
}

/// An address the server sent, or null where it sent nothing worth using.
///
/// A blank string is treated as absent rather than passed on: an empty address
/// inside an `Image.network` fails on screen, which looks like a broken picture
/// instead of a shop that has not uploaded one.
String? _url(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }

  return value;
}

/// Every picture address on a part, as sent.
///
/// Anything that is not a string is dropped rather than turned into one: a null
/// in the list would become the word "null" inside an `Image.network`, which
/// fails on screen rather than simply not being there.
List<String> _gallery(Object? raw) {
  if (raw is! List) {
    return const [];
  }

  return raw
      .whereType<String>()
      .where((one) => one.isNotEmpty)
      .toList(growable: false);
}

/// A part, as the shop lists it.
///
/// Every field here maps to something `ProductResource` actually sends. The
/// four that are nullable — the old price, the rating, the review count and the
/// specifications — are ones the server does not send *today*; the app draws
/// them when they arrive and leaves the space empty until then, rather than
/// inventing a star rating nobody gave.
@immutable
class Part {
  const Part({
    required this.id,
    required this.slug,
    required this.name,
    required this.code,
    required this.price,
    required this.currency,
    required this.unit,
    required this.free,
    required this.aisle,
    this.brand,
    this.aisleId,
    this.brandId,
    this.modelNumber,
    this.summary,
    this.description,
    this.imageUrl,
    this.wasPrice,
    this.rating,
    this.ratingCount,
    this.specs = const [],
    this.images = const [],
    this.isFeatured = false,
  });

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(
      id: asInt(json['id']),
      slug: asText(json['slug']),
      name: asText(json['name']),
      code: asText(json['code']),
      modelNumber: json['model_number'] as String?,
      summary: json['short_description'] as String?,
      description: json['description'] as String?,
      price: asDouble(json['price']),
      currency: asText(json['currency'], 'ج.م'),
      unit: asText(json['unit']),
      imageUrl: _url(json['image']),
      images: _gallery(json['images']),
      aisle: asText(json['category']),
      aisleId: json['category_id'] is num ? asInt(json['category_id']) : null,
      brand: json['brand'] as String?,
      brandId: json['brand_id'] is num ? asInt(json['brand_id']) : null,
      free: asDouble(json['available']),
      isFeatured: json['is_featured'] == true,

      /*
       * Read if sent, absent otherwise. Writing `?? 0` here instead would put a
       * zero-star rating on every product in the shop, which is worse than no
       * rating at all — one says nothing, the other says something untrue.
       */
      wasPrice: json['was_price'] is num
          ? asDouble(json['was_price'])
          : null,
      rating: json['rating'] is num ? asDouble(json['rating']) : null,
      ratingCount: json['rating_count'] is num
          ? asInt(json['rating_count'])
          : null,
      specs: _specs(json['specs']),
    );
  }

  final int id;
  final String slug;
  final String name;

  /// The manufacturer's part number. In this trade it is what a customer
  /// actually searches by — a mechanic holding a dead compressor reads the
  /// number off it, not the marketing name.
  final String code;

  final String? modelNumber;
  final String? summary;
  final String? description;
  final double price;
  final String currency;

  /// `قطعة`, `كرتونة`, `متر`. Shown beside every price, because a customer
  /// buying tubing needs to know whether the number is per metre or per roll.
  final String unit;

  final String? imageUrl;

  /// Every picture the shop keeps of it, its own first.
  ///
  /// Sent on the detail call only — a grid draws one thumbnail per tile, and
  /// forty galleries to fill forty thumbnails is a page that loads slowly for
  /// nothing. Empty on a card, which is what [imageUrl] is for.
  final List<String> images;
  final String aisle;
  final String? brand;

  /// The keys behind those two names.
  ///
  /// Kept so the page can offer "more from this brand" without matching a word
  /// back to a row somewhere — which is where two spellings start disagreeing.
  final int? aisleId;
  final int? brandId;

  /// What can be bought right now: what is on the shelf, less what is held in
  /// other people's baskets.
  final double free;

  final bool isFeatured;

  final double? wasPrice;
  final double? rating;
  final int? ratingCount;
  final List<(String, String)> specs;

  Availability get availability => Availability.of(free);

  bool get isOnOffer => wasPrice != null && wasPrice! > price;

  bool get hasRating => rating != null && rating! > 0;

  /// Specifications, if the server ever sends them.
  ///
  /// Accepts either a list of `{label, value}` objects or a plain map, because
  /// both are reasonable things for the server to send and guessing wrong would
  /// mean the feature silently does nothing on the day it is added.
  static List<(String, String)> _specs(dynamic raw) {
    if (raw is Map) {
      return [
        for (final entry in raw.entries)
          (entry.key.toString(), entry.value.toString()),
      ];
    }

    if (raw is List) {
      return [
        for (final one in raw)
          if (one is Map)
            (
              asText(one['label'] ?? one['name']),
              asText(one['value'] ?? one['text']),
            ),
      ];
    }

    return const [];
  }
}

/// Somebody's opinion, once the shop has approved it.
@immutable
class Verdict {
  const Verdict({
    required this.id,
    required this.author,
    required this.rating,
    required this.body,
    this.title,
    this.written,
    this.isBuyer = false,
  });

  factory Verdict.fromJson(Map<String, dynamic> json) {
    return Verdict(
      id: asInt(json['id']),
      author: asText(json['author'] ?? json['name']),
      rating: asInt(json['rating']),
      title: json['title'] as String?,
      body: asText(json['body']),
      written: DateTime.tryParse(asText(json['created_at'] ?? json['at'])),
      isBuyer: json['is_buyer'] == true || json['verified'] == true,
    );
  }

  final int id;
  final String author;
  final int rating;
  final String? title;
  final String body;
  final DateTime? written;

  /// Whether this person actually bought the part here. Worth showing: it is
  /// the difference between a review and a comment.
  final bool isBuyer;
}

/// What the shop calls itself, as the server says it.
///
/// Read from `home` rather than written into the app, so renaming the shop or
/// changing its telephone number is a settings change on the website and not a
/// new release on the store.
@immutable
class ShopIdentity {
  const ShopIdentity({
    required this.name,
    required this.tagline,
    this.phone,
    this.email,
    this.address,
    this.logoUrl,
    this.returnsPolicy,
    this.certificateUrl,
    this.certificateNote,
  });

  factory ShopIdentity.fromJson(Map<String, dynamic> json) {
    final badge = json['certificate'];

    return ShopIdentity(
      name: asText(json['name']),
      tagline: asText(json['tagline']),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      logoUrl: _url(json['logo']),
      returnsPolicy: json['returns_policy'] as String?,
      certificateUrl: badge is Map<String, dynamic>
          ? _url(badge['image'])
          : null,
      certificateNote: badge is Map<String, dynamic>
          ? badge['note'] as String?
          : null,
    );
  }

  /// What to show before the first reply arrives. Empty rather than a guess:
  /// a header that says one name for a second and another afterwards is worse
  /// than one that says nothing for a second.
  static const unknown = ShopIdentity(name: '', tagline: '');

  final String name;
  final String tagline;
  final String? phone;
  final String? email;
  final String? address;

  /// The shop's own mark, uploaded on the settings page.
  ///
  /// The app has a drawn one to fall back on, so a shop that has not uploaded
  /// anything is not a hole on every screen.
  final String? logoUrl;

  /// What the shop promises about bringing something back, in its own words.
  ///
  /// Absent where the shop has not written one, and shown as nothing rather
  /// than as a guess — a promise invented by the app is a promise the shop
  /// never made.
  final String? returnsPolicy;

  /// The certification the shop trades under, and the line under it.
  ///
  /// Absent where the shop has none — and shown as nothing rather than as a
  /// placeholder, because a placeholder here would be the app claiming a
  /// certification on the shop's behalf.
  final String? certificateUrl;
  final String? certificateNote;

  bool get hasCertificate => (certificateUrl ?? '').isNotEmpty;

  bool get isKnown => name.isNotEmpty;
}

/// One panel of whatever the shop is promoting.
@immutable
class Slide {
  const Slide({
    required this.title,
    this.lede,
    this.actionLabel,
    this.imageUrl,
    this.aisle,
    this.maker,
  });

  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      title: asText(json['title'] ?? json['heading']),
      lede: json['lede'] as String? ?? json['subtitle'] as String?,
      actionLabel: json['action'] as String? ?? json['cta'] as String?,
      imageUrl: json['image'] as String?,
      aisle: json['category'] as String?,
      maker: json['brand'] as String?,
    );
  }

  final String title;
  final String? lede;
  final String? actionLabel;
  final String? imageUrl;
  final String? aisle;
  final String? maker;
}

/// The shop front, in one reply.
@immutable
class ShopFront {
  const ShopFront({
    required this.identity,
    required this.slides,
    required this.featured,
    required this.arrivals,
    required this.bestSellers,
  });

  factory ShopFront.fromJson(Map<String, dynamic> json) {
    return ShopFront(
      identity: ShopIdentity.fromJson(
        json['store'] as Map<String, dynamic>? ?? const {},
      ),
      slides: _list(json['slides']).map(Slide.fromJson).toList(),
      featured: _list(json['featured']).map(Part.fromJson).toList(),
      arrivals: _list(json['arrivals']).map(Part.fromJson).toList(),
      bestSellers: _list(json['best_sellers']).map(Part.fromJson).toList(),
    );
  }

  static const empty = ShopFront(
    identity: ShopIdentity.unknown,
    slides: [],
    featured: [],
    arrivals: [],
    bestSellers: [],
  );

  final ShopIdentity identity;
  final List<Slide> slides;
  final List<Part> featured;
  final List<Part> arrivals;
  final List<Part> bestSellers;

  static List<Map<String, dynamic>> _list(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw.whereType<Map<String, dynamic>>().toList();
  }
}

/// One part with what else is in its aisle — what `products/{slug}` answers.
@immutable
class PartAndKin {
  const PartAndKin({
    required this.part,
    required this.related,
    this.reviews = const [],
  });

  factory PartAndKin.fromJson(Map<String, dynamic> json) {
    return PartAndKin(
      part: Part.fromJson(json['product'] as Map<String, dynamic>? ?? const {}),
      related: ShopFront._list(json['related']).map(Part.fromJson).toList(),
      reviews: ShopFront._list(json['reviews']).map(Verdict.fromJson).toList(),
    );
  }

  final Part part;
  final List<Part> related;

  /// What people who bought it said, approved and in the shop's own order.
  ///
  /// Sent with the part rather than fetched separately: a page that shows a
  /// star rating and then has to ask again before it can show a single review
  /// is a page with two spinners on it.
  final List<Verdict> reviews;
}
