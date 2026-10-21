import 'package:flutter/foundation.dart';

import '../api/api_failure.dart';
import '../models/basket.dart';
import '../repositories/basket_repository.dart';

/// The basket, which lives on the server.
///
/// This class holds no arithmetic at all. Every total, every discount, every
/// delivery charge arrives already worked out, because the shop works them out
/// once for the website, the invoice and the app alike — and the moment the app
/// starts adding things up itself is the moment it can disagree with the bill
/// the customer is asked to pay.
///
/// What it does hold is the last answer, so that four screens showing the
/// basket count do not make four calls.
class BasketStore extends ChangeNotifier {
  BasketStore(this._parts);

  final BasketRepository _parts;

  Basket _basket = Basket.empty;
  bool _busy = false;
  bool _loaded = false;
  ApiFailure? _fault;

  Basket get basket => _basket;

  /// Whether a call is in flight. Screens disable the plus and minus while it
  /// is: two taps in quick succession would otherwise send two quantities and
  /// leave the shown number depending on which reply landed last.
  bool get isBusy => _busy;

  bool get isLoaded => _loaded;

  ApiFailure? get fault => _fault;

  int get pieces => _basket.pieces;

  int quantityOf(int itemId) => _basket.quantityOf(itemId);

  bool holds(int itemId) => _basket.holds(itemId);

  /// How far off free delivery the basket is, when the shop offers it at all.
  double? get shortOfFreeShipping => _basket.shortOfFreeShipping;

  /// Read the basket from the server.
  ///
  /// Called on waking with a token, and again whenever the basket screen is
  /// opened. Cheap enough to repeat, and repeating it is what catches a basket
  /// changed on the website while the app was closed.
  Future<void> load({bool force = false}) async {
    if (_loaded && !force) {
      return;
    }

    await _run(() => _parts.read());
  }

  /// Forget everything without calling anybody.
  ///
  /// For signing out: the basket belongs to the account that has just gone, and
  /// asking the server about it with a dropped token would only produce a 401.
  void forget() {
    _basket = Basket.empty;
    _loaded = false;
    _fault = null;
    notifyListeners();
  }

  Future<void> add(int itemId, {int quantity = 1}) =>
      _run(() => _parts.add(itemId: itemId, quantity: quantity));

  Future<void> setQuantity(int itemId, int quantity) =>
      _run(() => _parts.setQuantity(itemId: itemId, quantity: quantity));

  Future<void> remove(int itemId) => _run(() => _parts.remove(itemId));

  Future<void> clear() => _run(() => _parts.clear());

  Future<void> applyCoupon(String code) =>
      _run(() => _parts.applyCoupon(code.trim().toUpperCase()));

  Future<void> removeCoupon() => _run(() => _parts.removeCoupon());

  Future<void> chooseShipping(int methodId) =>
      _run(() => _parts.chooseShipping(methodId));

  /// Every call goes through here.
  ///
  /// It keeps the busy flag honest, replaces the whole basket with whatever
  /// came back, and rethrows so the screen that asked can say what went wrong.
  /// Swallowing the failure here would leave the customer looking at an
  /// unchanged screen with no idea their tap did nothing.
  Future<void> _run(Future<Basket> Function() call) async {
    _busy = true;
    _fault = null;
    notifyListeners();

    try {
      _basket = await call();
      _loaded = true;
    } on ApiFailure catch (fault) {
      _fault = fault;

      /*
       * A rejected token means this basket belongs to nobody now. Held on to,
       * it would show a signed-out customer somebody else's parts.
       */
      if (fault.isAuth) {
        _basket = Basket.empty;
        _loaded = false;
      }

      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
