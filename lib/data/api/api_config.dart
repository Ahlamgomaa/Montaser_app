import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the server is.
///
/// Not a constant anywhere in the app. The address is answered from these
/// places, in order, and the first one that has an answer wins:
///
///   1. What somebody typed into the app and it remembered.
///   2. `--dart-define=API_BASE_URL=...`, given at build time.
///   3. The laptop's own server, in a debug build run with
///      `--dart-define=LOCAL_API=true`.
///   4. The shop itself, [_shipped].
///
/// The order matters. The build-time value is what ships to customers; the
/// stored one exists so a tester can point the same build at staging without a
/// rebuild, and so this project can be finished before anybody has decided what
/// the production address is.
class ApiConfig extends ChangeNotifier {
  ApiConfig._();

  static final ApiConfig instance = ApiConfig._();

  /// Given at build time:
  ///
  ///     flutter build apk --dart-define=API_BASE_URL=https://staging.example/api/v1
  ///
  /// Empty unless somebody passed one, and then [_shipped] is used instead.
  static const _fromBuild = String.fromEnvironment('API_BASE_URL');

  /// Where the shop actually lives.
  ///
  /// The one address in the application, and it is here rather than scattered
  /// because it is the single fact that has to change when the shop moves. It
  /// is the *last* resort, not the first: a build define beats it, and an
  /// address somebody typed into the app beats both — so pointing a build at
  /// staging never means editing this file.
  static const _shipped = 'https://montasereg.com/api/v1';

  /// Where it lives while somebody is building it.
  ///
  /// Asked for, not assumed. A debug build talks to the real shop like any
  /// other unless it is run with
  ///
  ///     flutter run --dart-define=LOCAL_API=true
  ///
  /// It used to be the debug default, and that meant a debug build on a real
  /// phone called an address only an emulator can reach and waited out the
  /// whole timeout before saying the server was slow — a fault that was never
  /// the server's.
  ///
  /// It can never reach a customer: a release build ignores the flag. For any
  /// other machine, `--dart-define=API_BASE_URL=...` says exactly where.
  ///
  /// `10.0.2.2` is how an Android emulator reaches the host it is running on;
  /// `localhost` is the host's own name and means the emulator itself.
  static const _local = 'http://10.0.2.2:8000/api/v1';

  static const _wantsLocal = bool.fromEnvironment('LOCAL_API');

  static const _key = 'api.base_url';

  SharedPreferences? _store;
  String? _saved;

  /// Read the remembered address. Called once, before the first frame.
  Future<void> wake() async {
    _store = await SharedPreferences.getInstance();
    _saved = _store?.getString(_key);
    notifyListeners();
  }

  /// The address to send requests to, or null when there is none.
  ///
  /// Always without a trailing slash, so joining a path is `'$baseUrl/$path'`
  /// everywhere and never `'...//products'` in one place.
  String? get baseUrl {
    final chosen = [
      _saved?.trim() ?? '',
      _fromBuild.trim(),
      /* Only when asked for, and never in a release build. */
      if (kDebugMode && _wantsLocal) _local,
      _shipped,
    ].firstWhere((one) => one.isNotEmpty, orElse: () => '');

    if (chosen.isEmpty) {
      return null;
    }

    return chosen.endsWith('/')
        ? chosen.substring(0, chosen.length - 1)
        : chosen;
  }

  bool get isConfigured => baseUrl != null;

  /// Whether the address came from the build or from somebody typing it.
  bool get isOverridden => _saved?.trim().isNotEmpty ?? false;

  String get buildValue => _fromBuild;

  /// Point the app somewhere else and remember it.
  Future<void> pointAt(String url) async {
    final tidied = url.trim();

    _saved = tidied.isEmpty ? null : tidied;

    if (tidied.isEmpty) {
      await _store?.remove(_key);
    } else {
      await _store?.setString(_key, tidied);
    }

    notifyListeners();
  }

  /// Go back to whatever the build was given.
  Future<void> forgetOverride() => pointAt('');

  /// Whether a string is worth trying as an address.
  ///
  /// Deliberately loose: it checks the shape rather than reachability, because
  /// a wrong-but-well-formed address is a network error the app already knows
  /// how to show, and refusing `http://10.0.2.2:8000` for not being https would
  /// stop the emulator working on the day somebody needs it most.
  static String? faultIn(String url) {
    final tidied = url.trim();

    if (tidied.isEmpty) {
      return 'اكتب عنوان السيرفر.';
    }

    final parsed = Uri.tryParse(tidied);

    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      return 'العنوان غير صحيح. مثال: https://montaser.com/api/v1';
    }

    if (parsed.scheme != 'http' && parsed.scheme != 'https') {
      return 'العنوان لازم يبدأ بـ http أو https.';
    }

    return null;
  }
}
