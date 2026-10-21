import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import 'widgets/password_sheet.dart';
import '../../data/api/api_failure.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/page_crown.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/app_field.dart';

/// The customer's own details.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _company;

  @override
  void initState() {
    super.initState();

    final shopper = AppScope.session(context).shopper;

    _name = TextEditingController(text: shopper?.name ?? '');
    _email = TextEditingController(text: shopper?.email ?? '');
    _company = TextEditingController(text: shopper?.company ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _company.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopper = AppScope.sessionOf(context).shopper;

    return Scaffold(
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.only(bottom: Metric.bottomRest),
          children: [
            const PageCrown(
              title: 'الملف الشخصي',
              lede: 'اسمك وبريدك وبيانات الفاتورة.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppField(
                    label: 'الاسم',
                    hint: 'اسمك كما تحب أن نناديك',
                    controller: _name,
                    glyph: Icons.person_outline_rounded,
                    validator: (value) => (value ?? '').trim().length < 3
                        ? 'اكتب اسمك كاملاً.'
                        : null,
                  ),
                  Gap.h16,

                  /*
             * The telephone number is shown and not editable. It is the
             * account itself — changing it would move the account to a
             * different person — so it is a support request rather than a
             * field, and saying so here is kinder than a form that refuses on
             * submit.
             */
                  _Locked(value: shopper?.phone ?? ''),
                  Gap.h16,

                  AppField(
                    label: 'البريد الإلكتروني',
                    hint: 'name@example.com',
                    controller: _email,
                    optional: true,
                    glyph: Icons.mail_outline_rounded,
                    keyboard: TextInputType.emailAddress,
                    helper: 'نرسل عليه إيصال الطلب فقط.',
                    validator: (value) {
                      final text = (value ?? '').trim();

                      if (text.isEmpty) {
                        return null;
                      }

                      return text.contains('@') && text.contains('.')
                          ? null
                          : 'اكتب بريداً صحيحاً.';
                    },
                  ),
                  Gap.h16,
                  AppField(
                    label: 'اسم الشركة أو الورشة',
                    hint: 'إن كنت تشتري لشركة أو ورشة',
                    controller: _company,
                    optional: true,
                    glyph: Icons.storefront_outlined,
                    helper: 'يظهر على الفاتورة.',
                  ),
                  Gap.h32,
                  FilledButton(
                    onPressed: _save,
                    child: const Text('حفظ التعديلات'),
                  ),
                  Gap.h12,
                  /*
                   * This said "we have sent you a link" and sent nothing. The
                   * password is changed here, against the server, with the
                   * current one asked for first.
                   */
                  OutlinedButton.icon(
                    onPressed: _changePassword,
                    icon: const Icon(Icons.lock_outline_rounded, size: 18),
                    label: const Text('تغيير كلمة المرور'),
                  ),
                  Gap.h8,
                  TextButton.icon(
                    onPressed: _signOutEverywhere,
                    icon: const Icon(Icons.devices_outlined, size: 18),
                    label: const Text('تسجيل الخروج من كل الأجهزة'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Save, and say what actually happened.
  ///
  /// This used to announce "saved" the moment it was pressed, without waiting
  /// for the server — so a refused change and a successful one looked exactly
  /// the same, and the customer only found out on the next screen that read
  /// their name.
  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      await AppScope.session(context).updateProfile(
        name: _name.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        company: _company.text.trim().isEmpty ? null : _company.text.trim(),
      );
    } on ApiFailure catch (fault) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(fault.message)));

      return;
    }

    messenger
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('تم حفظ بياناتك.')));
  }

  /// Change the password, in a sheet that asks for the current one first.
  Future<void> _changePassword() async {
    final messenger = ScaffoldMessenger.of(context);
    final changed = await PasswordSheet.open(context);

    if (!changed) {
      return;
    }

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('تم تغيير كلمة المرور.')),
      );
  }

  /// End every session but this one.
  ///
  /// For a phone that was lost or lent. Confirmed first: it is not undoable and
  /// somebody signed in on a shop computer will have to sign in there again.
  Future<void> _signOutEverywhere() async {
    final messenger = ScaffoldMessenger.of(context);
    final session = AppScope.session(context);

    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الخروج من كل الأجهزة؟'),
        content: const Text(
          'سيُطلب تسجيل الدخول من جديد على كل جهاز، بما فيه هذا الجهاز.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('نعم، اخرج'),
          ),
        ],
      ),
    );

    if (sure != true) {
      return;
    }

    try {
      await session.signOutEverywhere();
    } on ApiFailure catch (fault) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(fault.message)));
    }
  }
}

class _Locked extends StatelessWidget {
  const _Locked({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 2, bottom: Gap.sm),
          child: Text('رقم الهاتف', style: context.type.labelMedium),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.lg,
            vertical: Gap.lg,
          ),
          decoration: BoxDecoration(
            color: colors.canvas,
            borderRadius: Corner.rMd,
            border: Border.all(color: colors.line),
          ),
          child: Row(
            children: [
              Icon(Icons.phone_outlined, size: 20, color: colors.inkFaint),
              Gap.w12,
              Expanded(child: Text(value, style: context.type.bodyMedium)),
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: colors.inkFaint,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Gap.sm, right: 2),
          child: Text(
            'رقم الهاتف هو حسابك. لتغييره تواصل معنا.',
            style: context.type.labelSmall?.copyWith(color: colors.inkFaint),
          ),
        ),
      ],
    );
  }
}
