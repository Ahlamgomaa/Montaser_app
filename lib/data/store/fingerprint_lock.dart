import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opening the app with a fingerprint.
///
/// What this is, and what it is not. It is a lock on the app, not a second way
/// of proving who somebody is to the shop: the token in storage is what the
/// server trusts, and it stays exactly as trustworthy as it was. What the
/// fingerprint decides is whether this handset hands that token to the screen
/// — so a phone left on a counter does not show somebody else the customer's
/// addresses and their orders.
///
/// That distinction is why nothing here talks to the server. A fingerprint
/// cannot be sent anywhere and is never seen by this application: the platform
/// answers yes or no, and the answer is all there is.
///
/// Off until the customer turns it on, and turning it off is not protected by
/// it. A lock that cannot be removed without the thing that is failing is a
/// customer locked out of their own account by a scanner that stopped reading
/// a wet finger.
class FingerprintLock extends ChangeNotifier {
  FingerprintLock._();

  static final FingerprintLock instance = FingerprintLock._();

  static const _key = 'auth.fingerprint';

  final _platform = LocalAuthentication();

  SharedPreferences? _store;
  bool _on = false;

  /// Whether the customer has asked for it.
  bool get isOn => _on;

  /// Read the setting. Called once, before the first frame.
  Future<void> wake() async {
    _store = await SharedPreferences.getInstance();
    _on = _store?.getBool(_key) ?? false;
    notifyListeners();
  }

  /// Whether this handset can do it at all.
  ///
  /// Two questions, and both have to be yes: the phone has the hardware, and
  /// somebody has actually enrolled a finger on it. A phone with a sensor and
  /// no fingerprint registered answers the first and fails the second, and
  /// offering the switch there is offering something that cannot work.
  Future<bool> isPossible() async {
    try {
      return await _platform.isDeviceSupported() &&
          await _platform.canCheckBiometrics;
    } on Exception {
      /* An old phone, or a platform that will not say. Treated as no. */
      return false;
    }
  }

  /// Ask for a fingerprint, and say whether it was given.
  Future<bool> prove(String reason) async {
    try {
      return await _platform.authenticate(
        localizedReason: reason,
        /*
         * The device's own PIN or pattern is allowed as well. A customer with a
         * cut finger, or gloves on in a cold store, still has to be able to
         * open the app — and what they reach for otherwise is turning the lock
         * off altogether.
         */
        biometricOnly: false,
        /*
         * Survives the prompt sending the app to the background, which is what
         * the system does while the sensor is up.
         */
        persistAcrossBackgrounding: true,
      );
    } on Exception {
      /*
       * A cancelled prompt, a sensor that is not there, a platform refusing.
       * All of them mean the same thing to the caller: it was not proved.
       */
      return false;
    }
  }

  /// Turn it on, but only after it has been proved once.
  ///
  /// Asked for here rather than trusted later: a customer who switches this on
  /// without the scanner ever answering would find out it does not work on
  /// their phone the next time they opened the app, locked out of it.
  Future<bool> turnOn(String reason) async {
    if (!await isPossible() || !await prove(reason)) {
      return false;
    }

    _on = true;
    await _store?.setBool(_key, true);
    notifyListeners();

    return true;
  }

  /// Turn it off.
  ///
  /// Deliberately not behind a fingerprint. A scanner that has stopped reading
  /// is the reason somebody wants this off, and asking it to agree first would
  /// be locking them out with their own setting.
  Future<void> turnOff() async {
    _on = false;
    await _store?.setBool(_key, false);
    notifyListeners();
  }
}
