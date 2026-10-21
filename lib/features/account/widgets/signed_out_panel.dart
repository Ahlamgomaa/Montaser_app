import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/page_crown.dart';
import '../../../data/store/identity_store.dart';

/// What the account tab shows before anybody signs in.
///
/// It says what an account is for rather than only demanding one. "سجّل
/// الدخول" on an empty screen is a toll gate; naming the three things behind it
/// is a reason. The reasons are numbered cards on a coloured ground rather than
/// a list of grey rows — this is a sales pitch, and it should look like one.
class SignedOutPanel extends StatelessWidget {
  const SignedOutPanel({super.key});

  static const _reasons = <(IconData, String, String, Color)>[
    (
      Icons.receipt_long_rounded,
      'تابع طلباتك',
      'اعرف أين وصل طلبك، خطوة بخطوة.',
      Palette.brand,
    ),
    (
      Icons.place_rounded,
      'احفظ عناوينك',
      'اطلب في المرة القادمة بضغطة واحدة.',
      Palette.coral,
    ),
    (
      Icons.favorite_rounded,
      'احفظ ما يعجبك',
      'اجمع القطع التي تحتاجها لاحقاً.',
      Palette.violet,
    ),
    (
      Icons.local_offer_rounded,
      'اعرف العروض أولاً',
      'ننبّهك حين ينزل سعر قطعة تتابعها.',
      Palette.amber,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return ListView(
      padding: const EdgeInsets.only(bottom: Metric.bottomRest),
      children: [
        PageCrown(
          title: 'حسابي',
          lede: 'طلباتك وعناوينك ومفضلتك في مكان واحد.',
          showBack: false,
        ),

        /*
         * The card is pulled up into the crown's sweep so the two shapes
         * interlock. Sitting it below the curve would leave a band of page
         * colour between them and undo the point of the curve.
         */
        Transform.translate(
          offset: const Offset(0, -18),
          child: Padding(
            padding: Metric.pagePad,
            child: Container(
              padding: const EdgeInsets.all(Gap.xl),
              decoration: BoxDecoration(
                color: context.scheme.surface,
                borderRadius: Corner.rXl,
                border: Border.all(color: colors.line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const BrandMark(size: 60),
                  Gap.h16,
                  Text(
                    'أنت على بعد دقيقة واحدة',
                    style: type.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  Gap.h4,
                  Text(
                    'أنشئ حسابك بالرقم الذي تستخدمه، أو سجّل الدخول إن كان لديك حساب.',
                    style: type.bodySmall?.copyWith(color: colors.inkFaint),
                    textAlign: TextAlign.center,
                  ),
                  Gap.h24,
                  FilledButton(
                    onPressed: () => context.push(Path.register),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: const Text('إنشاء حساب جديد'),
                  ),
                  Gap.h12,
                  OutlinedButton(
                    onPressed: () => context.push(Path.signIn),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: const Text('لدي حساب — تسجيل الدخول'),
                  ),
                ],
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 0),
          child: Text('ماذا تكسب بالحساب؟', style: type.titleSmall),
        ),
        Gap.h12,

        for (final (glyph, title, note, tone) in _reasons)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.md),
            child: _Reason(glyph: glyph, title: title, note: note, tone: tone),
          ),

        Gap.h8,
        _BrowseOn(),
      ],
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason({
    required this.glyph,
    required this.title,
    required this.note,
    required this.tone,
  });

  final IconData glyph;
  final String title;
  final String note;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Corner.rLg,
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: Corner.rMd,
            ),
            child: Icon(glyph, size: 22, color: tone),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: type.titleSmall),
                Text(
                  note,
                  style: type.bodySmall?.copyWith(color: colors.inkFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The way out for somebody who does not want an account yet.
///
/// Browsing needs no account and never will, so the screen says so instead of
/// leaving the only door as the one they just declined to walk through.
class _BrowseOn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Metric.pagePad,
      child: Column(
        children: [
          Text(
            'يمكنك التصفّح والشراء لاحقاً — الحساب مطلوب عند إتمام الطلب فقط.',
            style: context.type.labelSmall?.copyWith(
              color: context.palette.inkFaint,
            ),
            textAlign: TextAlign.center,
          ),
          Gap.h12,
          TextButton.icon(
            onPressed: () => context.go(Path.home),
            icon: const Icon(Icons.storefront_rounded, size: 18),
            label: Text('تصفّح ${ShopBadge.instance.name}'),
          ),
        ],
      ),
    );
  }
}
