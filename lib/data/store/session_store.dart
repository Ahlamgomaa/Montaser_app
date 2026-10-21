import 'package:flutter/foundation.dart';

import '../api/api_failure.dart';
import '../api/token_store.dart';
import '../models/account.dart';
import '../models/catalogue.dart';
import '../repositories/auth_repository.dart';
import '../repositories/shop_repository.dart';

/// Who is signed in, and their own things.
///
/// The app needs an account to buy: an order carries an address and a telephone
/// number, and both have to belong to somebody the shop can name. Browsing does
/// not — a customer should be able to look through the whole catalogue and see
/// prices before being asked for anything.
class SessionStore extends ChangeNotifier {
  SessionStore(this._auth, this._account, this._tokens);

  final AuthRepository _auth;
  final AccountRepository _account;
  final TokenStore _tokens;

  Shopper? _shopper;
  AddressBook _book = AddressBook.empty;
  Set<int> _kept = <int>{};
  bool _waking = true;
  bool _refused = false;

  Shopper? get shopper => _shopper;

  bool get isSignedIn => _shopper != null;

  /// True until the stored token has been checked. The account screen shows
  /// nothing rather than the signed-out pitch while this is on — flashing
  /// "create an account" at somebody who has one is a poor greeting.
  bool get isWaking => _waking;

  List<Place> get places => _book.places;

  List<Governorate> get governorates => _book.governorates;

  Place? get defaultPlace => _book.chosen;

  Set<int> get kept => Set.unmodifiable(_kept);

  bool keeps(int itemId) => _kept.contains(itemId);

  int get keptCount => _kept.length;

  /// Called when [ApiClient] sees a 401.
  ///
  /// Noted rather than acted on. Being signed out is something the customer
  /// does, not something that happens to them while they are looking at a
  /// basket — and one refused call is a thin reason to throw a session away.
  ///
  /// The screen that made the call still says so: the failure carries through
  /// to it and it shows "sign in first". What does not happen is the whole app
  /// quietly forgetting who it is speaking for.
  ///
  /// The one place a session really does end is [wake], where the server is
  /// asked directly and answers about the token itself.
  void tokenRejected() {
    if (_shopper == null) {
      return;
    }

    _refused = true;
    notifyListeners();
  }

  /// Whether the last call was refused, so a screen can offer to sign in again.
  bool get wasRefused => _refused;

  /// Called after somebody signs in or creates an account, and after they sign
  /// out.
  ///
  /// Set once by [AppScope], for the things that belong to the account but are
  /// not kept here — the basket, chiefly. Without them a basket fetched for
  /// nobody stays empty after signing in, and one fetched for the last person
  /// stays on screen after they sign out, until the app is restarted.
  ///
  /// Not called on waking or on [lockAway]: the splash decides those, after the
  /// fingerprint has had its say.
  VoidCallback? onSignedIn;
  VoidCallback? onSignedOut;

  /// Put the account away without ending it.
  ///
  /// For a handset whose fingerprint was not given. The token is untouched and
  /// the shop is still open to browse — what is withheld is this person's own
  /// corner of it, which is the whole of what the lock was asked to protect.
  ///
  /// Different from signing out in the one way that matters: nothing is
  /// revoked, so putting a finger on the sensor next launch is all it takes.
  void lockAway() {
    if (_shopper == null) {
      return;
    }

    _shopper = null;
    _book = AddressBook.empty;
    _kept.clear();

    notifyListeners();
  }

  /// Find out whether the stored token still means anything.
  ///
  /// Runs while the splash is up. A token that is no longer honoured ends the
  /// session here, before the customer taps something and is refused.
  Future<void> wake() async {
    _waking = true;

    final token = await _tokens.read();

    if (token == null || token.isEmpty) {
      _waking = false;
      notifyListeners();

      return;
    }

    try {
      _shopper = await _auth.whoAmI();
      await _loadOwn();
    } on ApiFailure catch (fault) {
      /*
       * Only a token the server actually refused ends a session.
       *
       * This used to forget on any failure at all, which meant a customer
       * opening the app on a train with no signal was signed out — and had to
       * find their password to get back to a basket that was still sitting on
       * the server. A dead line is not a dead token, and the two must not be
       * answered the same way.
       *
       * So a refusal ends it and everything else is left alone: the session
       * stands, the screens say what went wrong, and the next launch with a
       * line simply works.
       */
      if (fault.kind == FailureKind.unauthenticated) {
        _forget();
      }
    } finally {
      _waking = false;
      notifyListeners();
    }
  }

  Future<Shopper> signIn({
    required String phone,
    required String password,
  }) async {
    _shopper = await _auth.signIn(phone: phone, password: password);
    _refused = false;
    await _loadOwn();
    notifyListeners();
    onSignedIn?.call();

    return _shopper!;
  }

  Future<Shopper> register({
    required String name,
    required String phone,
    required String password,
    int? governorateId,
    String? email,
    String? company,
  }) async {
    _shopper = await _auth.register(
      name: name,
      phone: phone,
      password: password,
      governorateId: governorateId,
      email: email,
      company: company,
    );

    await _loadOwn();
    notifyListeners();
    onSignedIn?.call();

    return _shopper!;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } finally {
      _forget();
      notifyListeners();
      onSignedOut?.call();
    }
  }

  /// End every session this account has, on every handset.
  ///
  /// For a phone that was lost or lent. This one included: a token that stayed
  /// alive here would mean "everywhere" was not true, and the customer asked
  /// for everywhere.
  Future<void> signOutEverywhere() async {
    try {
      await _auth.signOutEverywhere();
    } finally {
      _forget();
      notifyListeners();
      onSignedOut?.call();
    }
  }

  Future<void> updateProfile({
    required String name,
    String? email,
    String? company,
  }) async {
    _shopper = await _auth.updateProfile(
      name: name,
      email: email,
      company: company,
    );

    notifyListeners();
  }

  Future<void> changePassword({
    required String current,
    required String next,
  }) => _auth.changePassword(current: current, next: next);

  // ------------------------------------------------------------- the places

  /// Re-read the address book from the server.
  Future<void> loadPlaces() async {
    _book = await _account.addresses();
    notifyListeners();
  }

  Future<void> addPlace(Place place) async {
    await _account.addAddress(place);
    await loadPlaces();
  }

  Future<void> updatePlace(Place place) async {
    await _account.updateAddress(place);
    await loadPlaces();
  }

  Future<void> makeDefault(int placeId) async {
    await _account.makeDefault(placeId);
    await loadPlaces();
  }

  Future<void> removePlace(int placeId) async {
    await _account.removeAddress(placeId);
    await loadPlaces();
  }

  // ----------------------------------------------------------- the wishlist

  Future<void> loadKept() async {
    final parts = await _account.wishlist();

    _kept = parts.map((part) => part.id).toSet();
    notifyListeners();
  }

  /// Returns whether the part is now kept.
  ///
  /// The set is changed before the call and put back if the call fails. A heart
  /// that waits for the network to fill in feels broken on a slow connection,
  /// and this is the one action in the app where being optimistic costs
  /// nothing: the worst case is a heart that un-fills a moment later.
  Future<bool> toggleKept(int itemId) async {
    final wasKept = _kept.contains(itemId);

    wasKept ? _kept.remove(itemId) : _kept.add(itemId);
    notifyListeners();

    try {
      final nowKept = await _account.toggleKept(itemId);

      if (nowKept != !wasKept) {
        nowKept ? _kept.add(itemId) : _kept.remove(itemId);
        notifyListeners();
      }

      return nowKept;
    } on ApiFailure {
      wasKept ? _kept.add(itemId) : _kept.remove(itemId);
      notifyListeners();

      rethrow;
    }
  }

  /// The address book and the wish list, together.
  ///
  /// Both are wanted the moment somebody signs in — the checkout needs an
  /// address and every product card needs to know whether its heart is filled —
  /// and asking for them at once rather than in sequence saves a round trip on
  /// the slowest screen in the app.
  Future<void> _loadOwn() async {
    await Future.wait([
      _account.addresses().then((book) => _book = book),
      _account.wishlist().then(
        (parts) => _kept = parts.map((part) => part.id).toSet(),
      ),
    ]);
  }

  void _forget() {
    _shopper = null;
    _book = AddressBook.empty;
    _kept = <int>{};
  }
}
