import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/catalogue.dart';
import '../store/identity_store.dart';

/// How the app asks a list to be narrowed.
///
/// The names here are the app's; [asQuery] turns them into the ones the server
/// wants. Keeping the translation in one place means a screen never has to know
/// that the server calls the department `category` and the search `q`.
class PartQuery {
  const PartQuery({
    this.text,
    this.aisleId,
    this.makerId,
    this.sort,
    this.page = 1,
    this.perPage = 20,
  });

  final String? text;
  final int? aisleId;
  final int? makerId;

  /// One of what the server accepts — `featured`, `newest`, `cheapest`,
  /// `dearest`. Sent as given; the server decides what it does not recognise,
  /// and it answers with the sort it actually used so the app can show it.
  final String? sort;

  final int page;
  final int perPage;

  Map<String, dynamic> asQuery() => {
    if (text != null && text!.trim().isNotEmpty) 'q': text!.trim(),
    if (aisleId != null) 'category': aisleId,
    if (makerId != null) 'brand': makerId,
    if (sort != null) 'sort': sort,
    'page': page,
    'per_page': perPage,
  };

  PartQuery atPage(int next) => PartQuery(
    text: text,
    aisleId: aisleId,
    makerId: makerId,
    sort: sort,
    page: next,
    perPage: perPage,
  );
}

/// A page of parts, and whether there are more.
class PartPage {
  const PartPage({
    required this.parts,
    required this.total,
    required this.hasMore,
    required this.page,
    this.sort,
  });

  static const empty = PartPage(
    parts: [],
    total: 0,
    hasMore: false,
    page: 1,
  );

  final List<Part> parts;
  final int total;
  final bool hasMore;
  final int page;

  /// The order the server actually used, which may not be the one asked for.
  final String? sort;
}

/// What the shop sells.
class CatalogueRepository {
  const CatalogueRepository(this._api);

  final ApiClient _api;

  /// The shop front: who the shop is, what it is promoting, three rows of
  /// parts. One call, because it is one screen.
  Future<ShopFront> front() async {
    final data = await _api.get(Api.home);

    final front = ShopFront.fromJson(data as Map<String, dynamic>? ?? const {});

    /*
     * Kept for the screens that draw the shop's name before this has been
     * asked — the splash and both sign-in pages. See [ShopBadge].
     */
    await ShopBadge.instance.remember(front.identity);

    return front;
  }

  Future<List<Aisle>> aisles() async {
    final data = await _api.get(Api.categories);

    return _rows(data).map(Aisle.fromJson).toList(growable: false);
  }

  Future<List<Maker>> makers() async {
    final data = await _api.get(Api.brands);

    return _rows(data).map(Maker.fromJson).toList(growable: false);
  }

  /// Where the shop delivers.
  ///
  /// Open, so the registration form can ask for one before anybody has an
  /// account. It is what delivery is priced by, which is why the app never
  /// carries its own copy.
  Future<List<Governorate>> governorates() async {
    final data = await _api.get(Api.governorates);

    return _rows(data).map(Governorate.fromJson).toList(growable: false);
  }

  Future<PartPage> search(PartQuery query) async {
    final paged = await _api.page(Api.products, query: query.asQuery());

    return PartPage(
      parts: _rows(paged.rows).map(Part.fromJson).toList(growable: false),
      total: paged.total,
      hasMore: paged.hasMore,
      page: paged.currentPage,
      sort: paged.meta['sort'] as String?,
    );
  }

  Future<PartAndKin> part(String slug) async {
    final data = await _api.get(Api.product(slug));

    return PartAndKin.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  static List<Map<String, dynamic>> _rows(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}
