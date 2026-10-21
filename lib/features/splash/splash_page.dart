import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/store/fingerprint_lock.dart';
import '../../app/routes.dart';
import '../../core/theme/dimens.dart';
import '../../core/theme/palette.dart';
import '../../data/api/api_config.dart';
import '../../data/api/token_store.dart';

/// The first screen, and the only one that does real work before the shop.
///
/// It is not a delay dressed up as a brand moment. While it is up the app reads
/// the saved server address, reads the saved token, asks the server who that
/// token speaks for, and fetches the basket — so the shop front behind it opens
/// already knowing whether somebody is signed in and how many things are in
/// their bag, instead of assembling itself in front of them.
///
/// It leaves on its own. Nothing here can be tapped and nothing can go wrong
/// that it should stop for: an unreachable server is the shop's problem to show
/// on the shop screen, not a wall to hold a customer behind.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// The shortest the mark stays up.
  ///
  /// The waking usually finishes sooner than this on a good connection, and a
  /// splash that flashes past in 200ms reads as a glitch. On a slow one the
  /// waking takes longer and the splash simply waits for it.
  static const _atLeast = Duration(milliseconds: 1400);

  /// The logo, transparent, shared with the system splash in front of this.
  static const _mark = 'assets/brand/splash.png';

  /// The same, with the navy lettering in orange: on the dark page the navy
  /// all but disappeared.
  static const _markDark = 'assets/brand/splash_dark.png';

  /// Wide enough to read the name under the mark on a small phone.
  static const _markSize = 200.0;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final _rise = CurvedAnimation(parent: _run, curve: Curves.easeOutCubic);

  late final _settle = CurvedAnimation(
    parent: _run,
    /*
     * The words arrive after the mark rather than with it. A tenth of a second
     * of stagger is the difference between a screen that appears and a screen
     * that assembles itself.
     */
    curve: const Interval(0.35, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    /*
     * Both at once. The waking is network-bound and the wait is not, so running
     * them in parallel costs whichever is longer rather than their sum.
     *
     * And the shop opens whatever the waking did. It used to wait on it with
     * nothing to catch a fault it did not expect — a reply of the wrong shape,
     * a platform refusing — and the splash then stayed up for good. The fault
     * is reported rather than swallowed; the customer is not held behind it.
     */
    try {
      await Future.wait([_waken(), Future<void>.delayed(SplashPage._atLeast)]);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack, library: 'splash'),
      );
    }

    if (mounted) {
      context.go(Path.home);
    }
  }

  Future<void> _waken() async {
    final session = AppScope.session(context);

    /*
     * The lock on the handset, where the customer asked for one.
     *
     * Asked before the account is woken rather than after it. Asked after,
     * the app had already fetched this person's addresses and wish list with
     * their token by the time the fingerprint was refused.
     *
     * A refusal signs nobody out. The token is kept but not sent, and the shop
     * is still open — what the fingerprint decides is whether *this* handset
     * hands over the account, so a wrong finger drops back to browsing rather
     * than to a password prompt for an account that was never in doubt.
     */
    if (FingerprintLock.instance.isOn && TokenStore.instance.hasToken) {
      final proved = await FingerprintLock.instance.prove(
        'افتح حسابك في مؤسسة منتصر',
      );

      if (!proved) {
        session.lockAway();

        return;
      }
    }

    await session.wake();

    if (!mounted || !session.isSignedIn) {
      return;
    }

    /*
     * Only with an account. The basket lives behind the token, and asking for
     * it while signed out would spend a round trip to be told 401.
     */
    final basket = AppScope.basket(context);

    try {
      await basket.load(force: true);
    } catch (_) {
      /* The basket screen will say so. The shop front should still open. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = context.type;

    /*
     * The shop's own mark, on the page colour of whichever theme the phone is
     * in. The picture is transparent, so it sits on light and dark alike, and
     * the colours here are the ones the system splash in front of this uses —
     * opening the app is one picture that settles, not two that swap.
     */
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: ScaleTransition(
              scale: Tween(begin: 0.72, end: 1.0).animate(_rise),
              child: FadeTransition(
                opacity: _rise,
                child: Image.asset(
                  Theme.of(context).brightness == Brightness.dark
                      ? SplashPage._markDark
                      : SplashPage._mark,
                  width: SplashPage._markSize,
                  semanticLabel: 'مؤسسة منتصر',
                ),
              ),
            ),
          ),

          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: Gap.huge,
            child: FadeTransition(
              opacity: _settle,
              child: Column(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: context.scheme.primary,
                    ),
                  ),
                  Gap.h16,
                  /*
                   * Said only when it is true. An app that has not been given
                   * a server address will fail on its first call, and saying
                   * so here — where somebody is already looking — is better
                   * than four screens each reporting the same thing as their
                   * own failure.
                   */
                  if (!ApiConfig.instance.isConfigured)
                    Text(
                      'لم يُضبط عنوان السيرفر بعد',
                      style: type.labelSmall?.copyWith(
                        color: context.palette.inkFaint,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
