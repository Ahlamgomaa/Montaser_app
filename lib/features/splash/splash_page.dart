import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/store/fingerprint_lock.dart';
import '../../app/routes.dart';
import '../../core/theme/dimens.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/brand_mark.dart';
import '../../data/api/api_config.dart';

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
     */
    await Future.wait([
      _waken(),
      Future<void>.delayed(SplashPage._atLeast),
    ]);

    if (mounted) {
      context.go(Path.home);
    }
  }

  Future<void> _waken() async {
    final session = AppScope.session(context);

    await session.wake();

    if (!mounted || !session.isSignedIn) {
      return;
    }

    /*
     * The lock on the handset, where the customer asked for one.
     *
     * Asked here rather than on a screen of its own: this is the moment the
     * app is about to show somebody's addresses and their orders, and it is
     * the only moment worth asking at.
     *
     * A refusal signs nobody out. The token is still good and the shop is
     * still open — what the fingerprint decides is whether *this* handset
     * hands over the account, so a wrong finger drops back to browsing rather
     * than to a password prompt for an account that was never in doubt.
     */
    if (FingerprintLock.instance.isOn) {
      final proved = await FingerprintLock.instance.prove(
        'افتح حسابك في مؤسسة منتصر',
      );

      if (!proved) {
        session.lockAway();

        return;
      }
    }

    if (!mounted) {
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

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Palette.brandLift, Palette.brand, Palette.brandDeep],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: -80, right: -60, child: _Halo(size: 260)),
            const Positioned(bottom: -110, left: -70, child: _Halo(size: 320)),
            const Positioned.fill(child: CustomPaint(painter: _FlurryPainter())),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: Tween(begin: 0.72, end: 1.0).animate(_rise),
                    child: FadeTransition(
                      opacity: _rise,
                      child: Container(
                        padding: const EdgeInsets.all(Gap.xl),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                        child: const BrandMark(size: 84, plain: true),
                      ),
                    ),
                  ),
                  Gap.h32,
                  FadeTransition(
                    opacity: _settle,
                    child: Text(
                      'منتصر',
                      style: type.displaySmall?.copyWith(
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
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
                        color: Colors.white.withValues(alpha: 0.9),
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 32,
        ),
      ),
    );
  }
}

/// A scatter of small flakes across the background.
///
/// Fixed positions rather than random ones: this is the first thing anybody
/// sees, and it should look the same every time it is opened. A different
/// arrangement on each launch reads as noise rather than as a design.
class _FlurryPainter extends CustomPainter {
  const _FlurryPainter();

  /// Fractions of the screen, so the scatter follows any size.
  static const _flakes = <(double, double, double)>[
    (0.14, 0.18, 9),
    (0.82, 0.12, 6),
    (0.26, 0.78, 7),
    (0.72, 0.86, 10),
    (0.90, 0.52, 5),
    (0.08, 0.58, 6),
    (0.55, 0.08, 5),
    (0.40, 0.92, 6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (final (x, y, reach) in _flakes) {
      final middle = Offset(size.width * x, size.height * y);

      for (var spoke = 0; spoke < 3; spoke++) {
        final turn = spoke * math.pi / 3;
        final arm = Offset(math.cos(turn), math.sin(turn)) * reach;

        canvas.drawLine(middle - arm, middle + arm, pen);
      }
    }
  }

  @override
  bool shouldRepaint(_FlurryPainter old) => false;
}
