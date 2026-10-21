/// Every address in the application, written once.
///
/// Paths as constants rather than strings typed at each call site. A push to
/// `/oreders/12` compiles perfectly and fails at run time in front of a
/// customer; a reference to a constant that does not exist fails here, now,
/// while somebody is looking at it.
///
/// The nested ones are spelled out in full rather than assembled from their
/// parents. `go_router` matches on the whole path, and a constant that has to
/// be concatenated at the call site is a constant that will be concatenated
/// wrongly somewhere.
abstract final class Path {
  /// Where the app opens. It shows the mark for a moment and then goes to
  /// [home], so nothing ever navigates back to it.
  static const splash = '/splash';

  // ---- the five tabs ----

  static const home = '/';
  static const aisles = '/aisles';
  static const basket = '/basket';
  static const kept = '/kept';
  static const account = '/account';

  // ---- inside the shop tab ----

  static const browse = '/browse';
  static const search = '/search';
  static const part = '/part';

  // ---- inside the departments tab ----

  static const makers = '/aisles/makers';

  // ---- inside the account tab ----

  static const orders = '/account/orders';
  static const order = '/account/orders';
  static const profile = '/account/profile';
  static const places = '/account/places';
  static const placeForm = '/account/places/form';

  // ---- over the bar ----

  static const checkout = '/checkout';
  static const placed = '/placed';
  static const signIn = '/sign-in';
  static const register = '/register';

  /// The addresses that take a value, built rather than interpolated at the
  /// call site so the shape of the path lives in one file.
  static String toPart(String slug) => '$part/$slug';

  /// Addressed by the id the server knows it by.
  ///
  /// The reference is what a customer reads and quotes on the telephone; the id
  /// is what `orders/{id}` answers to. Using the reference here would mean the
  /// screen could not fetch the order it was opened for.
  static String toOrder(int id) => '$order/$id';

  /// The catalogue, narrowed.
  ///
  /// By id rather than by name, because that is what the server filters on —
  /// a name would have to be matched back to a department somewhere, and the
  /// place it would be matched is the place two spellings start disagreeing.
  static String toBrowse({
    int? aisleId,
    int? makerId,
    String? title,
    String? query,
  }) {
    final terms = <String, String>{
      if (aisleId != null) 'aisle': '$aisleId',
      if (makerId != null) 'maker': '$makerId',
      /* What to put in the crown, so the page need not fetch a name to show. */
      'title': ?title,
      'q': ?query,
    };

    if (terms.isEmpty) {
      return browse;
    }

    final tail = terms.entries
        .map((one) => '${one.key}=${Uri.encodeComponent(one.value)}')
        .join('&');

    return '$browse?$tail';
  }

  static String toPlaceForm({int? id}) =>
      id == null ? placeForm : '$placeForm?id=$id';
}
