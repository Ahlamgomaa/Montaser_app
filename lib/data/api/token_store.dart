import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
///
/// Kept in the platform's secure store — the Keychain on iOS, a Keystore-backed
/// cipher on Android — rather than in plain preferences. Preferences are a file
/// any backup, rooted handset or debugging bridge can read, and this one string
/// is the whole of the customer's account.
class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  static const _key = 'auth.token';

  static const _secure = FlutterSecureStorage();

  String? _held;
  bool _read = false;
  Future<String?>? _waking;

  /// Whether the token is being kept back from requests.
  ///
  /// Set while the fingerprint lock is closed. The token is not thrown away —
  /// the server still honours it, and opening the lock should not mean
  /// signing in again — but nothing the app sends carries it until the lock
  /// is opened.
  bool _withheld = false;

  /// Load it once, before the first request.
  ///
  /// Also moves a token left in plain preferences by an earlier version of the
  /// app into the secure store, so an update does not sign anybody out. The
  /// plain copy is removed only once the secure one is written.
  Future<String?> wake() => _waking ??= _wake();

  Future<String?> _wake() async {
    final plain = await SharedPreferences.getInstance();
    var held = await _readSecure();
    final legacy = plain.getString(_key);

    if (held == null && legacy != null && legacy.isNotEmpty) {
      if (await _writeSecure(legacy)) {
        held = legacy;
      }
    }

    if (held != null || legacy == null || legacy.isEmpty) {
      await plain.remove(_key);
    }

    /* Signed in or out while this was reading: that answer is newer. */
    if (!_read) {
      /*
       * The plain copy is still used if the secure write failed, so a store
       * that will not take the token costs the customer nothing this launch;
       * the move is tried again on the next one.
       */
      _held = held ?? ((legacy?.isNotEmpty ?? false) ? legacy : null);
      _read = true;
    }

    return _held;
  }

  /// The token to send, or null.
  ///
  /// Kept in memory after the first read: this is called on every request, and
  /// going to disk each time would put a file read in front of every tap.
  Future<String?> read() async {
    if (!_read) {
      await wake();
    }

    return _withheld ? null : _held;
  }

  String? get held => _held;

  /// Whether this handset holds a token at all, withheld or not.
  bool get hasToken => (_held?.isNotEmpty ?? false);

  bool get isWithheld => _withheld;

  /// Stop sending the token, without forgetting it.
  void withhold() => _withheld = true;

  /// Start sending it again — the lock was opened.
  void release() => _withheld = false;

  Future<void> keep(String token) async {
    _held = token;
    _read = true;
    _withheld = false;

    await _writeSecure(token);
    await (await SharedPreferences.getInstance()).remove(_key);
  }

  Future<void> drop() async {
    _held = null;
    _read = true;
    _withheld = false;

    try {
      await _secure.delete(key: _key);
    } on PlatformException catch (error, stack) {
      _report(error, stack);
    }

    /* And the plain copy an older version may have left behind. */
    await (await SharedPreferences.getInstance()).remove(_key);
  }

  /// Forget what was read, so a test can start from the store again.
  @visibleForTesting
  void resetForTesting() {
    _held = null;
    _read = false;
    _waking = null;
    _withheld = false;
  }

  /// The secure copy, or null when there is none or it cannot be read.
  ///
  /// Unreadable is answered as absent. On Android a store restored onto a new
  /// handset cannot be decrypted there — its key never leaves the old one — and
  /// the honest outcome is signing in again, not a crash on launch.
  static Future<String?> _readSecure() async {
    try {
      final value = await _secure.read(key: _key);

      return (value == null || value.isEmpty) ? null : value;
    } on PlatformException catch (error, stack) {
      _report(error, stack);

      return null;
    }
  }

  static Future<bool> _writeSecure(String token) async {
    try {
      await _secure.write(key: _key, value: token);

      return true;
    } on PlatformException catch (error, stack) {
      _report(error, stack);

      return false;
    }
  }

  /// Said to the error handler, never with the token: a platform exception
  /// carries the store's complaint, not the value it was asked to hold.
  static void _report(Object error, StackTrace stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'token store',
        silent: true,
      ),
    );
  }
}
