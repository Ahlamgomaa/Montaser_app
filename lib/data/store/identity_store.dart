import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/catalogue.dart';

/// The last name the shop answered to, kept between runs.
///
/// The shop's name and tagline come from the settings page on the website, and
/// `home` is what carries them. That leaves a gap: the splash screen and both
/// sign-in screens draw the shop's mark and name *before* `home` has been
/// asked, and on a first run with no line there may be no answer at all.
///
/// Writing a name into the application would close the gap and reopen a worse
/// one — renaming the shop would mean a new release on the store, which is
/// exactly what putting it in the settings was meant to avoid.
///
/// So the last answer is kept. The app opens showing what the shop was called
/// the last time it was reached, and corrects itself the moment `home` replies.
/// A first run before any reply shows the mark without a name, which is honest:
/// nothing here knows it yet.
class ShopBadge extends ChangeNotifier {
  ShopBadge._();

  static final ShopBadge instance = ShopBadge._();

  static const _nameKey = 'shop.name';
  static const _taglineKey = 'shop.tagline';
  static const _phoneKey = 'shop.phone';
  static const _returnsKey = 'shop.returns';

  SharedPreferences? _store;
  String _name = '';
  String _tagline = '';
  String _phone = '';
  String _returns = '';

  /// What the shop was called when it was last reached.
  String get name => _name;

  String get tagline => _tagline;

  /// What the shop answers on, and what it promises about returns.
  ///
  /// Kept for the account screen, which shows both and never calls `home`.
  /// Written into the app instead, they were a telephone number and a promise
  /// decided by whoever last edited a Dart file.
  String get phone => _phone;

  String get returnsPolicy => _returns;

  bool get isKnown => _name.isNotEmpty;

  /// Read what was remembered. Called once, before the first frame.
  Future<void> wake() async {
    _store = await SharedPreferences.getInstance();
    _name = _store?.getString(_nameKey) ?? '';
    _tagline = _store?.getString(_taglineKey) ?? '';
    _phone = _store?.getString(_phoneKey) ?? '';
    _returns = _store?.getString(_returnsKey) ?? '';
    notifyListeners();
  }

  /// Take what the server just said.
  ///
  /// Quiet when nothing changed. This is called on every visit to the shop
  /// front, and notifying listeners each time would rebuild the header on every
  /// pull-to-refresh for a name that is the same as it was.
  Future<void> remember(ShopIdentity identity) async {
    final phone = identity.phone ?? '';
    final returns = identity.returnsPolicy ?? '';

    if (!identity.isKnown ||
        (identity.name == _name &&
            identity.tagline == _tagline &&
            phone == _phone &&
            returns == _returns)) {
      return;
    }

    _name = identity.name;
    _tagline = identity.tagline;
    _phone = phone;
    _returns = returns;

    await _store?.setString(_nameKey, _name);
    await _store?.setString(_taglineKey, _tagline);
    await _store?.setString(_phoneKey, _phone);
    await _store?.setString(_returnsKey, _returns);

    notifyListeners();
  }
}
