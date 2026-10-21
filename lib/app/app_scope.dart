import 'package:flutter/material.dart';

import '../data/api/api_config.dart';
import '../data/api/token_store.dart';
import '../data/repositories/repositories.dart';
import '../data/store/basket_store.dart';
import '../data/store/fingerprint_lock.dart';
import '../data/store/session_store.dart';

/// The stores, and the repositories under them, reachable from anywhere below.
///
/// An [InheritedNotifier] per store rather than one for both. Sharing a single
/// notifier would mean every screen watching the basket also rebuilds when the
/// wish list changes, and the product grid — the one screen where rebuilds
/// actually cost something — watches the basket.
class AppScope extends StatefulWidget {
  const AppScope({required this.child, super.key});

  final Widget child;

  /// Watching. The widget rebuilds when the store changes.
  static BasketStore basketOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BasketScope>()!.notifier!;

  static SessionStore sessionOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SessionScope>()!.notifier!;

  /// The same two, without subscribing.
  ///
  /// For callbacks — a tap handler that adds to the basket wants to *call* the
  /// store, not be rebuilt when it changes. Reading with a dependency inside an
  /// event handler is how a widget ends up rebuilding for a change it caused
  /// and does not display.
  static BasketStore basket(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_BasketScope>()!.notifier!;

  static SessionStore session(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SessionScope>()!.notifier!;

  /// The repositories. Screens read from these directly for anything the app
  /// does not hold on to — a page of the catalogue, one order, one part.
  static Repositories get shop => Repositories.instance;

  /// Whether the session is still waking, and whose it is.
  ///
  /// For the router, which decides who may open which screen and has to hear
  /// when that answer changes — a sign-in, a sign-out, the fingerprint lock.
  /// A value rather than the session itself, so it speaks only when one of
  /// those two things moves and not on every heart that is tapped.
  static final account = ValueNotifier<(bool, int?)>((true, null));

  @override
  State<AppScope> createState() => _AppScopeState();
}

class _AppScopeState extends State<AppScope> with WidgetsBindingObserver {
  late final SessionStore _session;
  late final BasketStore _basket;

  /// How long the app may sit in the background before the lock asks again.
  ///
  /// Long enough that answering a call or checking a message does not mean a
  /// fingerprint every time; short enough that a phone left on a counter does
  /// not stay open on somebody's account.
  static const _grace = Duration(minutes: 5);

  DateTime? _away;
  bool _asking = false;

  @override
  void initState() {
    super.initState();

    final shop = Repositories.instance;

    _session = SessionStore(shop.auth, shop.account, TokenStore.instance);
    _basket = BasketStore(shop.basket);

    /*
     * The client sees the 401 and the session decides what it means. Wired here
     * because this is the first place that knows about both, and because the
     * client must not import a session it has no business understanding.
     */
    shop.api.onTokenRejected = () {
      _session.tokenRejected();
      _basket.forget();
    };

    /*
     * The basket belongs to whoever is signed in, so it is fetched for the new
     * account and dropped for the old one. A failed fetch is left on the store
     * for the basket screen to show; nobody here is waiting on it.
     */
    _session.onSignedIn = () {
      _basket.load(force: true).catchError((Object _) {});
    };
    _session.onSignedOut = _basket.forget;

    _session.addListener(_tellRouter);
    WidgetsBinding.instance.addObserver(this);
  }

  void _tellRouter() {
    AppScope.account.value = (_session.isWaking, _session.shopper?.id);
  }

  /*
   * The lock asked only when the app was launched, so a phone left open in
   * the background stayed open for as long as the system kept the app alive —
   * days, on most handsets. Coming back after [_grace] asks again.
   */
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _away ??= DateTime.now();

      return;
    }

    if (state == AppLifecycleState.resumed) {
      final away = _away;
      _away = null;

      if (away != null && DateTime.now().difference(away) >= _grace) {
        _askAgain();
      }
    }
  }

  Future<void> _askAgain() async {
    final lock = FingerprintLock.instance;

    if (_asking || !lock.isOn || !_session.isSignedIn) {
      return;
    }

    _asking = true;

    try {
      final proved = await lock.prove('افتح حسابك في مؤسسة منتصر');

      if (!proved) {
        _session.lockAway();
        _basket.forget();
      }
    } finally {
      _asking = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_tellRouter);
    _basket.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ConfigScope(
      notifier: ApiConfig.instance,
      child: _SessionScope(
        notifier: _session,
        child: _BasketScope(notifier: _basket, child: widget.child),
      ),
    );
  }
}

class _BasketScope extends InheritedNotifier<BasketStore> {
  const _BasketScope({required super.notifier, required super.child});
}

class _SessionScope extends InheritedNotifier<SessionStore> {
  const _SessionScope({required super.notifier, required super.child});
}

/// The server address, above the stores.
///
/// Watched rather than read once, so that pointing the app somewhere else
/// rebuilds every screen underneath instead of leaving them showing the last
/// server's answers.
class _ConfigScope extends InheritedNotifier<ApiConfig> {
  const _ConfigScope({required super.notifier, required super.child});
}
