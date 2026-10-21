import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/routes.dart';
import '../../core/theme/dimens.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/app_field.dart';
import '../../data/api/api_failure.dart';
import '../../data/store/fingerprint_lock.dart';
import '../../data/store/identity_store.dart';
import 'widgets/auth_crown.dart';

/// Signing in.
///
/// The form sits on a raised card that rides up over the curve of the panel
/// above it. Two planes instead of one: the coloured half is the shop
/// introducing itself, the white card is the part the customer has to fill in,
/// and keeping them visibly separate means the eye lands on the work rather
/// than on the decoration.
class SignInPage extends StatefulWidget {
  const SignInPage({this.from, super.key});

  /// Where the customer was going when they were sent here to sign in.
  ///
  /// Set by the router's guard. Signing in carries on to it rather than
  /// dropping them on the account tab and leaving them to find the checkout
  /// again.
  final String? from;

  /// Where to go once signed in: [from] when it is one of this app's own
  /// paths, otherwise back, otherwise the account tab.
  static void onwards(GoRouter router, String? from, {required bool canPop}) {
    if (from != null && from.startsWith('/') && !from.startsWith('//')) {
      router.go(from);
    } else if (canPop) {
      router.pop();
    } else {
      router.go(Path.account);
    }
  }

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _working = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Scaffold(
      /*
       * No app bar. The panel is the top of the screen, and a bar over it would
       * put a grey strip across the gradient; the way back is the arrow drawn
       * on the panel itself.
       */
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: Gap.huge),
              child: Column(
                children: [
                  const AuthCrown(
                    title: 'أهلاً بعودتك',
                    lede: 'سجّل الدخول بالرقم الذي أنشأت به حسابك.',
                  ),

                  /*
                   * Pulled up into the sweep. The panel's curve bottoms out
                   * around fifty pixels from its foot, so the card overlaps by
                   * a little less than that and the two shapes interlock.
                   */
                  Transform.translate(
                    offset: const Offset(0, -42),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                      child: Container(
                        padding: const EdgeInsets.all(Gap.xl),
                        decoration: BoxDecoration(
                          color: context.scheme.surface,
                          borderRadius: Corner.rXl,
                          border: Border.all(color: colors.line),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 26,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppField(
                                label: 'رقم الهاتف',
                                hint: '01xxxxxxxxx',
                                controller: _phone,
                                glyph: Icons.phone_outlined,
                                keyboard: TextInputType.phone,
                                formatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    (value ?? '').trim().length < 11
                                    ? 'اكتب رقم الهاتف كاملاً.'
                                    : null,
                              ),
                              Gap.h16,
                              AppField(
                                label: 'كلمة المرور',
                                hint: 'كلمة المرور الخاصة بحسابك',
                                controller: _password,
                                glyph: Icons.lock_outline_rounded,
                                obscure: _hidden,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _signIn(),
                                trailing: IconButton(
                                  onPressed: () =>
                                      setState(() => _hidden = !_hidden),
                                  icon: Icon(
                                    _hidden
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  color: colors.inkFaint,
                                ),
                                validator: (value) => (value ?? '').isEmpty
                                    ? 'اكتب كلمة المرور.'
                                    : null,
                              ),
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: TextButton(
                                  onPressed: _forgot,
                                  child: const Text('نسيت كلمة المرور؟'),
                                ),
                              ),
                              Gap.h8,
                              FilledButton(
                                onPressed: _working ? null : _signIn,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                ),
                                child: _working
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('تسجيل الدخول'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const _OrRule(),
                  Gap.h16,
                  _Alternatives(from: widget.from),
                  Gap.h24,
                  _NewHere(),
                  Gap.h24,
                  const BrandLine(),
                ],
              ),
            ),
          ),

          /*
           * Over the panel rather than in a bar. White on the gradient, with a
           * translucent disc behind it so it stays legible wherever the
           * gradient happens to be light.
           */
          PositionedDirectional(
            top: MediaQuery.viewPaddingOf(context).top + Gap.sm,
            end: Gap.md,
            child: Material(
              color: Colors.white.withValues(alpha: 0.18),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () =>
                    context.canPop() ? context.pop() : context.go(Path.home),
                child: const Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _say(String what) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(what)));
  }

  /// What to do about a forgotten password, said honestly.
  ///
  /// This used to say a reset link had been sent, and sent nothing: the API
  /// this app talks to has no password-reset call. Until it does, the shop
  /// resets it — so this says so, with the number to ring when the shop has
  /// published one.
  void _forgot() {
    final phone = ShopBadge.instance.phone;

    _say(
      phone.isEmpty
          ? 'لاستعادة كلمة المرور تواصل مع المتجر.'
          : 'لاستعادة كلمة المرور تواصل مع المتجر على $phone.',
    );
  }

  Future<void> _signIn() async {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _working = true);

    final session = AppScope.session(context);
    final router = GoRouter.of(context);
    final canPop = context.canPop();

    try {
      await session.signIn(
        phone: _phone.text.trim(),
        password: _password.text,
      );
    } on ApiFailure catch (fault) {
      if (mounted) {
        setState(() => _working = false);
        /*
         * The server's own sentence. It says one thing for a number nobody has
         * and a password that is wrong, on purpose — telling them apart hands
         * whoever is guessing a list of the numbers that exist.
         */
        _say(fault.message);
      }

      return;
    } catch (error, stack) {
      /*
       * Anything else — a reply of the wrong shape, a platform fault. Without
       * this the button stayed spinning for good. Reported, and the customer
       * gets the button back.
       */
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack, library: 'sign in'),
      );

      if (mounted) {
        setState(() => _working = false);
        _say('تعذّر تسجيل الدخول. حاول مرة أخرى.');
      }

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _working = false);

    SignInPage.onwards(router, widget.from, canPop: canPop);
  }
}

class _OrRule extends StatelessWidget {
  const _OrRule();

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            child: Text(
              'أو',
              style: context.type.labelSmall?.copyWith(color: colors.inkFaint),
            ),
          ),
          Expanded(child: Divider(color: colors.line)),
        ],
      ),
    );
  }
}

/// The other ways in.
///
/// Drawn now and wired later. Leaving them out until the day they work would
/// mean redesigning this screen around them; putting them in says what the
/// finished screen is.
/// The fingerprint, for somebody who has already signed in on this handset.
///
/// One way in beside the password, not two. There was a "code by message"
/// button next to it and neither did anything — both showed "coming soon",
/// which is a button that teaches the customer to stop pressing buttons.
///
/// Shown only where it can actually work: this handset has a sensor, somebody
/// has enrolled a finger, and there is a session on it to unlock. Offered on a
/// phone with none of that, it is the same empty promise in a different shape.
class _Alternatives extends StatefulWidget {
  const _Alternatives({this.from});

  final String? from;

  @override
  State<_Alternatives> createState() => _AlternativesState();
}

class _AlternativesState extends State<_Alternatives> {
  bool _possible = false;

  @override
  void initState() {
    super.initState();
    _ask();
  }

  Future<void> _ask() async {
    final possible =
        FingerprintLock.instance.isOn &&
        await FingerprintLock.instance.isPossible();

    if (mounted) {
      setState(() => _possible = possible);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_possible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
      child: _Alternative(
        glyph: Icons.fingerprint_rounded,
        label: 'ادخل بالبصمة',
        onTap: _unlock,
      ),
    );
  }

  /// Open the account this handset already holds.
  ///
  /// Nothing about the fingerprint is sent anywhere: the token never left
  /// storage, and what the fingerprint decides is whether it is sent again.
  Future<void> _unlock() async {
    final proved = await FingerprintLock.instance.prove(
      'افتح حسابك في مؤسسة منتصر',
    );

    if (!proved || !mounted) {
      return;
    }

    final session = AppScope.session(context);
    final router = GoRouter.of(context);
    final canPop = context.canPop();

    await session.unlock();

    if (!mounted) {
      return;
    }

    if (session.isSignedIn) {
      /* The basket that was put away with the account, brought back with it. */
      AppScope.basket(context).load(force: true).catchError((Object _) {});

      SignInPage.onwards(router, widget.from, canPop: canPop);

      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('سجّل بكلمة المرور مرة واحدة أولاً.')),
      );
  }
}

class _Alternative extends StatelessWidget {
  const _Alternative({
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  final IconData glyph;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Material(
      color: context.scheme.surface,
      borderRadius: Corner.rMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: Corner.rMd,
            border: Border.all(color: colors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(glyph, size: 19, color: context.scheme.primary),
              Gap.w8,
              Text(label, style: context.type.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewHere extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ليس لديك حساب؟',
          style: context.type.bodySmall?.copyWith(
            color: context.palette.inkSoft,
          ),
        ),
        TextButton(
          onPressed: () => context.pushReplacement(Path.register),
          child: const Text('أنشئ حساباً'),
        ),
      ],
    );
  }
}
