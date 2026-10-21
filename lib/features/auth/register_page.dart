import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models/catalogue.dart';
import '../../data/api/api_failure.dart';
import '../../app/routes.dart';
import '../../core/theme/dimens.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/governorate_picker.dart';
import 'widgets/auth_crown.dart';

/// Opening an account.
///
/// Five required answers and two optional ones. Every extra question is a
/// customer who does not finish, so the shop asks only for what it cannot
/// deliver without: a name, a number to ring, a password, and the governorate —
/// which is not a nicety here but the thing delivery is priced by.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _password = TextEditingController();

  int? _governorate;

  /// Where the shop delivers, as it says today.
  ///
  /// Fetched rather than carried in the app: this list decides what delivery
  /// costs, and a copy kept here would be wrong the first time a governorate is
  /// added or stops being served — quoting a price for a place the shop no
  /// longer covers.
  late Future<List<Governorate>> _governorates;
  bool _hidden = true;
  bool _agreed = false;
  bool _working = false;

  /// Set only once the form has been submitted.
  ///
  /// Complaining about the empty governorate while somebody is still filling in
  /// their name would be scolding them for not having got there yet.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _governorates = AppScope.shop.catalogue.governorates();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _company.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.only(bottom: Gap.huge),
                children: [
                  const AuthCrown(
                    title: 'أنشئ حسابك',
                    lede: 'دقيقة واحدة، ثم تطلب متى شئت.',
                    height: 200,
                  ),

                  Transform.translate(
                    offset: const Offset(0, -34),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppField(
                              label: 'الاسم',
                              controller: _name,
                              glyph: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                              validator: (value) =>
                                  (value ?? '').trim().length < 3
                                  ? 'اكتب اسمك كاملاً.'
                                  : null,
                            ),
                            Gap.h16,
                            AppField(
                              label: 'رقم الهاتف',
                              controller: _phone,
                              glyph: Icons.phone_outlined,
                              keyboard: TextInputType.phone,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              helper: 'هو حسابك، ونتواصل به بخصوص طلباتك.',
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                final text = (value ?? '').trim();

                                if (text.isEmpty) {
                                  return 'اكتب رقم الهاتف.';
                                }

                                return text.length == 11
                                    ? null
                                    : 'الرقم يجب أن يكون ١١ رقماً.';
                              },
                            ),
                            Gap.h16,
                            FutureBuilder<List<Governorate>>(
                              future: _governorates,
                              builder: (context, snapshot) =>
                                  GovernoratePicker(
                                    options: snapshot.data ?? const [],
                                    value: _governorate,
                                    helper:
                                        'نحسب بها تكلفة الشحن ومدة التوصيل.',
                                    errorText:
                                        _submitted && _governorate == null
                                        ? 'اختر المحافظة.'
                                        : null,
                                    onPicked: (next) =>
                                        setState(() => _governorate = next.id),
                                  ),
                            ),
                            Gap.h16,
                            AppField(
                              label: 'كلمة المرور',
                              controller: _password,
                              glyph: Icons.lock_outline_rounded,
                              obscure: _hidden,
                              helper: 'ستة أحرف على الأقل.',
                              textInputAction: TextInputAction.next,
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
                              validator: (value) => (value ?? '').length < 6
                                  ? 'كلمة المرور قصيرة.'
                                  : null,
                            ),
                            Gap.h24,
                            const _Rule(label: 'اختياري'),
                            Gap.h16,
                            AppField(
                              label: 'البريد الإلكتروني',
                              controller: _email,
                              optional: true,
                              glyph: Icons.mail_outline_rounded,
                              keyboard: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
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
                              controller: _company,
                              optional: true,
                              glyph: Icons.storefront_outlined,
                              helper: 'يظهر على الفاتورة.',
                              textInputAction: TextInputAction.done,
                            ),
                            Gap.h24,
                            _Agreement(
                              on: _agreed,
                              onChanged: (next) =>
                                  setState(() => _agreed = next),
                            ),
                            Gap.h16,
                            FilledButton(
                              onPressed: _working ? null : _register,
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
                                  : const Text('إنشاء الحساب'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'لديك حساب بالفعل؟',
                        style: context.type.bodySmall?.copyWith(
                          color: colors.inkSoft,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.pushReplacement(Path.signIn),
                        child: const Text('سجّل الدخول'),
                      ),
                    ],
                  ),
                  Gap.h16,
                  const BrandLine(),
                ],
              ),
            ),
          ),

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

  Future<void> _register() async {
    setState(() => _submitted = true);

    final fieldsPass = _form.currentState?.validate() ?? false;

    if (!fieldsPass || _governorate == null) {
      return;
    }

    if (!_agreed) {
      _say('وافق على الشروط أولاً.');

      return;
    }

    setState(() => _working = true);

    final session = AppScope.session(context);
    final router = GoRouter.of(context);
    final canPop = context.canPop();

    try {
      await session.register(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        governorateId: _governorate,
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        company: _company.text.trim().isEmpty ? null : _company.text.trim(),
      );
    } on ApiFailure catch (fault) {
      if (mounted) {
        setState(() => _working = false);
        /* The server's own words — "this number already has an account" is
           something to act on; "registration failed" is not. */
        _say(fault.message);
      }

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _working = false);
    _say('أهلاً بك يا ${_name.text.trim()}.');

    canPop ? router.pop() : router.go(Path.account);
  }

  void _say(String what) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(what)));
  }
}

/// A labelled rule, dividing what must be answered from what need not be.
class _Rule extends StatelessWidget {
  const _Rule({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Row(
      children: [
        Expanded(child: Divider(color: colors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          child: Text(
            label,
            style: context.type.labelSmall?.copyWith(color: colors.inkFaint),
          ),
        ),
        Expanded(child: Divider(color: colors.line)),
      ],
    );
  }
}

class _Agreement extends StatelessWidget {
  const _Agreement({required this.on, required this.onChanged});

  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return InkWell(
      onTap: () => onChanged(!on),
      borderRadius: Corner.rMd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: on,
            onChanged: (next) => onChanged(next ?? false),
            visualDensity: VisualDensity.compact,
          ),
          Gap.w8,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'أوافق على شروط الاستخدام وسياسة الخصوصية.',
                style: context.type.bodySmall?.copyWith(color: colors.inkSoft),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
