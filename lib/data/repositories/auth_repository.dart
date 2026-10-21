import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../api/token_store.dart';
import '../models/account.dart';

/// The door.
///
/// Every method that ends with somebody signed in keeps the token here before
/// returning, and every method that ends with them signed out drops it. Leaving
/// that to the caller is how an app ends up holding a token for an account it
/// has already forgotten.
class AuthRepository {
  const AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  /// What this handset is called in the customer's list of signed-in devices.
  ///
  /// Sent so somebody can sign out one phone without signing out the other.
  static const _deviceName = 'تطبيق منتصر';

  Future<Shopper> register({
    required String name,
    required String phone,
    required String password,
    int? governorateId,
    String? email,
    String? company,
  }) async {
    final envelope = await _api.envelope(
      'POST',
      Api.register,
      body: {
        'name': name,
        'phone': phone,
        'password': password,
        'device_name': _deviceName,
        'governorate_id': ?governorateId,
        if (email != null && email.isNotEmpty) 'email': email,
        if (company != null && company.isNotEmpty) 'company': company,
      },
    );

    return _admit(envelope);
  }

  Future<Shopper> signIn({
    required String phone,
    required String password,
  }) async {
    final envelope = await _api.envelope(
      'POST',
      Api.login,
      body: {
        'phone': phone,
        'password': password,
        'device_name': _deviceName,
      },
    );

    return _admit(envelope);
  }

  /// Who this token speaks for.
  ///
  /// Called on waking with a stored token, which is also how the app finds out
  /// the token has been revoked: the call comes back 401 and the session ends
  /// quietly, before the customer taps anything.
  Future<Shopper> whoAmI() async {
    final data = await _api.get(Api.me);

    return Shopper.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<Shopper> updateProfile({
    required String name,
    String? email,
    String? company,
  }) async {
    final data = await _api.put(
      Api.me,
      body: {
        'name': name,
        'email': email ?? '',
        'company': company ?? '',
      },
    );

    return Shopper.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<String?> changePassword({
    required String current,
    required String next,
  }) async {
    final envelope = await _api.envelope(
      'PUT',
      Api.password,
      body: {
        'current_password': current,
        'password': next,
        'password_confirmation': next,
      },
    );

    return envelope['message'] as String?;
  }

  /// Sign out this handset.
  ///
  /// The token is dropped whatever the server says. If the call fails because
  /// the phone is offline, the customer still expects to be signed out — and a
  /// token the server will reject anyway is not worth keeping to be tidy.
  Future<void> signOut() async {
    try {
      await _api.post(Api.logout);
    } finally {
      await _tokens.drop();
    }
  }

  Future<void> signOutEverywhere() async {
    try {
      await _api.post(Api.logoutAll);
    } finally {
      await _tokens.drop();
    }
  }

  /// Take the token out of the envelope and remember it, then hand back the
  /// customer it belongs to.
  Future<Shopper> _admit(Map<String, dynamic> envelope) async {
    final token = envelope['token'];

    if (token is String && token.isNotEmpty) {
      await _tokens.keep(token);
    }

    return Shopper.fromJson(
      envelope['data'] as Map<String, dynamic>? ?? const {},
    );
  }
}
