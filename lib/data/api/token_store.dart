import 'package:shared_preferences/shared_preferences.dart';

/// The token this handset was given, kept between launches.
///
/// Without persisting it the customer signs in again every time they open the
/// app, which for a shop whose customers order once a fortnight means signing
/// in every time — and an app you have to sign into every time is an app people
/// stop opening.
///
/// Held in one place and read through here rather than passed around, because
/// the token is needed by the client on every request and by the session store
/// on waking, and two copies of it is one copy that goes stale after a sign-out.
class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  static const _key = 'auth.token';

  SharedPreferences? _store;
  String? _held;
  bool _read = false;

  /// Load it once, before the first request.
  Future<String?> wake() async {
    _store = await SharedPreferences.getInstance();
    _held = _store?.getString(_key);
    _read = true;

    return _held;
  }

  /// The token, or null.
  ///
  /// Kept in memory after the first read: this is called on every request, and
  /// going to disk each time would put a file read in front of every tap.
  Future<String?> read() async {
    if (!_read) {
      await wake();
    }

    return _held;
  }

  String? get held => _held;

  bool get hasToken => (_held?.isNotEmpty ?? false);

  Future<void> keep(String token) async {
    _held = token;
    _read = true;
    _store ??= await SharedPreferences.getInstance();
    await _store?.setString(_key, token);
  }

  Future<void> drop() async {
    _held = null;
    _read = true;
    _store ??= await SharedPreferences.getInstance();
    await _store?.remove(_key);
  }
}
