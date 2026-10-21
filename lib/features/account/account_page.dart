import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/routes.dart';
import '../../core/format/dates.dart';
import '../../core/theme/dimens.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/page_crown.dart';
import '../../data/store/fingerprint_lock.dart';
import '../../data/store/identity_store.dart';
import '../../data/models/account.dart';
import 'widgets/signed_out_panel.dart';

/// The customer's own corner.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.sessionOf(context);
    final shopper = session.shopper;

    if (shopper == null) {
      return const Scaffold(body: SafeArea(child: SignedOutPanel()));
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: Metric.bottomRest),
        children: [
          PageCrown(
            title: 'حسابي',
            lede: shopper.company ?? shopper.phone,
            showBack: false,
            actions: [
              CrownAction(
                glyph: Icons.edit_outlined,
                onTap: () => context.push(Path.profile),
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -12),
            child: _Card(shopper: shopper),
          ),

          _Group(
            title: 'طلباتي',
            rows: [
              _Row(
                glyph: Icons.receipt_long_outlined,
                label: 'كل الطلبات',
                onTap: () => context.push(Path.orders),
              ),
              _Row(
                glyph: Icons.favorite_outline_rounded,
                label: 'المفضلة',
                note: session.keptCount == 0
                    ? 'لم تحفظ شيئاً بعد'
                    : '${session.keptCount} قطعة',
                onTap: () => context.go(Path.kept),
              ),
            ],
          ),

          _Group(
            title: 'بياناتي',
            rows: [
              _Row(
                glyph: Icons.person_outline_rounded,
                label: 'الملف الشخصي',
                note: 'الاسم والبريد وكلمة المرور',
                onTap: () => context.push(Path.profile),
              ),
              _Row(
                glyph: Icons.place_outlined,
                label: 'عناويني',
                note: session.places.isEmpty
                    ? 'لم تُضِف عنواناً بعد'
                    : '${session.places.length} عناوين',
                onTap: () => context.push(Path.places),
              ),

              /*
               * The lock on this handset, offered only where it can work: a
               * sensor, a finger enrolled on it, and an account to unlock.
               * Offered anywhere else it is a switch that turns nothing on.
               */
              _FingerprintRow(),
            ],
          ),

          _Group(
            title: 'المتجر',
            rows: [
              /*
               * The shop's own number, from its settings page. It used to be
               * a number typed into this file — so the line a customer was
               * told to ring was decided by whoever last edited it, and could
               * not be corrected without an app store review.
               */
              if (ShopBadge.instance.phone.isNotEmpty)
                _Row(
                  glyph: Icons.support_agent_outlined,
                  label: 'تواصل معنا',
                  note: ShopBadge.instance.phone,
                  onTap: () => _say(
                    context,
                    'اتصل بنا على ${ShopBadge.instance.phone}',
                  ),
                ),

              /* And the promise, in the shop's own words rather than the app's. */
              if (ShopBadge.instance.returnsPolicy.isNotEmpty)
                _Row(
                  glyph: Icons.assignment_return_outlined,
                  label: 'سياسة الاستبدال',
                  onTap: () =>
                      _say(context, ShopBadge.instance.returnsPolicy),
                ),
              _Row(
                glyph: Icons.info_outline_rounded,
                label: 'عن ${ShopBadge.instance.name}',
                note: ShopBadge.instance.tagline,
                onTap: () => _say(
                  context,
                  '${ShopBadge.instance.name} — ${ShopBadge.instance.tagline}',
                ),
              ),
            ],
          ),

          Gap.h24,
          Padding(
            padding: Metric.pagePad,
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('تسجيل الخروج'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.palette.danger,
                side: BorderSide(color: context.palette.danger),
              ),
            ),
          ),
          Gap.h12,
          Center(
            child: Text(
              'إصدار ١٫٠٫٠',
              style: context.type.labelSmall?.copyWith(
                color: context.palette.inkFaint,
              ),
            ),
          ),
          Gap.h8,
        ],
      ),
    );
  }

  static void _say(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(what)));
  }

  /// Ask before signing out, and sign out if the answer is yes.
  ///
  /// The builder's own context is used to close the dialog, and that is the
  /// whole of a bug this had. Written `builder: (_) =>`, the `context` inside
  /// the buttons was the *page's* — so tapping either one popped the account
  /// screen instead of the dialog. At the root of the shell there is nothing
  /// under it to pop to, so the app closed and left a black window: the
  /// customer pressed "sign out" and the shop vanished.
  Future<void> _confirmSignOut(BuildContext context) async {
    final session = AppScope.session(context);

    final sure = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('تسجيل الخروج؟'),
        content: const Text('ستحتاج إلى تسجيل الدخول مرة أخرى للطلب.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.danger,
            ),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (sure != true) {
      return;
    }

    /*
     * Swallowed. The token is being thrown away here either way — a server that
     * will not take the word for it is not a reason to leave somebody signed
     * in on a handset they asked to be signed out of.
     */
    try {
      await session.signOut();
    } on Exception {
      /* Nothing to say: the session is gone from this phone regardless. */
    }
  }
}

/// The card at the top with the customer's name on it.
class _Card extends StatelessWidget {
  const _Card({required this.shopper});

  final Shopper shopper;

  @override
  Widget build(BuildContext context) {
    final type = context.type;

    return Container(
      margin: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 0),
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        borderRadius: Corner.rXl,
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Palette.brandLift, Palette.brand],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            child: Text(
              shopper.initials,
              style: type.titleLarge?.copyWith(color: Colors.white),
            ),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopper.name,
                  style: type.titleMedium?.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  shopper.phone,
                  style: type.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                if (shopper.company != null)
                  Text(
                    shopper.company!,
                    style: type.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (shopper.since != null) ...[
                  Gap.h8,
                  Text(
                    'عميل منذ ${Dates.full(shopper.since!)}',
                    style: type.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.type.titleSmall),
          Gap.h12,
          Container(
            decoration: BoxDecoration(
              color: context.scheme.surface,
              borderRadius: Corner.rLg,
              border: Border.all(color: colors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var at = 0; at < rows.length; at++) ...[
                  if (at > 0)
                    Divider(height: 1, indent: 56, color: colors.line),
                  rows[at],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.glyph,
    required this.label,
    /* Optional: not every row has a second line worth a call to fetch. */
    this.note,
    required this.onTap,
  });

  final IconData glyph;
  final String label;
  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return ListTile(
      onTap: onTap,
      shape: const RoundedRectangleBorder(),
      leading: Icon(glyph, size: 21, color: context.scheme.primary),
      title: Text(label, style: context.type.bodyMedium),
      /* No second line rather than an empty one: a blank subtitle still
         takes its height and leaves the row looking unfinished. */
      subtitle: note == null
          ? null
          : Text(
              note!,
              style: context.type.labelSmall?.copyWith(color: colors.inkFaint),
            ),
      trailing: Icon(
        Icons.chevron_left_rounded,
        size: 20,
        color: colors.inkFaint,
      ),
    );
  }
}

/// The switch that puts a fingerprint in front of this account.
///
/// A row rather than a page: it is one decision with one answer, and it belongs
/// beside the other things about this account rather than behind a tap.
///
/// Turning it on asks for the finger first. A customer who switched this on
/// without the scanner ever answering would discover it does not work on their
/// phone at the moment they were locked out by it.
class _FingerprintRow extends StatefulWidget {
  const _FingerprintRow();

  @override
  State<_FingerprintRow> createState() => _FingerprintRowState();
}

class _FingerprintRowState extends State<_FingerprintRow> {
  bool _possible = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ask();
  }

  Future<void> _ask() async {
    final possible = await FingerprintLock.instance.isPossible();

    if (mounted) {
      setState(() => _possible = possible);
    }
  }

  @override
  Widget build(BuildContext context) {
    /* Nothing at all on a phone that cannot do it. */
    if (!_possible) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: FingerprintLock.instance,
      builder: (context, _) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(
          Icons.fingerprint_rounded,
          size: 21,
          color: context.scheme.primary,
        ),
        title: Text('الدخول بالبصمة', style: context.type.bodyMedium),
        subtitle: Text(
          'اطلب بصمتك قبل فتح حسابك على هذا الجهاز',
          style: context.type.labelSmall?.copyWith(
            color: context.palette.inkFaint,
          ),
        ),
        value: FingerprintLock.instance.isOn,
        onChanged: _busy ? null : _flip,
      ),
    );
  }

  Future<void> _flip(bool wanted) async {
    setState(() => _busy = true);

    final messenger = ScaffoldMessenger.of(context);

    if (!wanted) {
      /*
       * Turning it off is not itself protected by it. A scanner that has
       * stopped reading is the usual reason somebody wants it off, and asking
       * that scanner to agree first would lock them out with their own setting.
       */
      await FingerprintLock.instance.turnOff();
    } else {
      final on = await FingerprintLock.instance.turnOn(
        'أكّد بصمتك لتشغيل الدخول بالبصمة',
      );

      if (!on) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text('لم تُقرأ البصمة. لم يتغيّر شيء.')),
          );
      }
    }

    if (mounted) {
      setState(() => _busy = false);
    }
  }
}