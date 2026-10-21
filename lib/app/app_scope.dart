import 'package:flutter/material.dart';

import '../data/api/api_config.dart';
import '../data/api/token_store.dart';
import '../data/repositories/repositories.dart';
import '../data/store/basket_store.dart';
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

  @override
  State<AppScope> createState() => _AppScopeState();
}

class _AppScopeState extends State<AppScope> {
  late final SessionStore _session;
  late final BasketStore _basket;

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
  }

  @override
  void dispose() {
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
