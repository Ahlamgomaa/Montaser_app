import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/app_field.dart';
import '../../../data/api/api_failure.dart';

/// Changing the password.
///
/// The current one is asked for. Not ceremony: somebody changing a password is
/// often somebody who thinks another person has it, and a form that changes it
/// without asking is a form that lets whoever has the phone lock the owner out
/// of their own account.
///
/// Every other handset is signed out when it succeeds — the server does that,
/// and it is the point. A change that leaves the other person's session alive
/// is a change that did nothing.
class PasswordSheet extends StatefulWidget {
  const PasswordSheet({super.key});

  /// Open it, and answer true if the password was actually changed.
  static Future<bool> open(BuildContext context) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const PasswordSheet(),
    );

    return done ?? false;
  }

  @override
  State<PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<PasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();

  bool _sending = false;
  String? _fault;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _again.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تغيير كلمة المرور', style: context.type.titleMedium),
            Gap.h4,
            Text(
              'سيتم تسجيل الخروج من باقي أجهزتك.',
              style: context.type.bodySmall?.copyWith(color: colors.inkFaint),
            ),
            Gap.h16,

            AppField(
              label: 'كلمة المرور الحالية',
              hint: 'التي تدخل بها الآن',
              controller: _current,
              glyph: Icons.lock_outline_rounded,
              obscure: true,
            ),
            Gap.h12,
            AppField(
              label: 'كلمة المرور الجديدة',
              hint: 'ثمانية أحرف على الأقل',
              controller: _next,
              glyph: Icons.lock_reset_rounded,
              obscure: true,
              helper: 'ثمانية أحرف على الأقل.',
            ),
            Gap.h12,
            AppField(
              label: 'أعد كتابتها',
              hint: 'اكتب الكلمة الجديدة مرة أخرى',
              controller: _again,
              glyph: Icons.lock_reset_rounded,
              obscure: true,
            ),

            if (_fault != null) ...[
              Gap.h12,
              Text(
                _fault!,
                style: context.type.bodySmall?.copyWith(color: colors.danger),
              ),
            ],

            Gap.h16,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sending ? null : _send,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(_sending ? 'جارٍ الحفظ…' : 'غيّر كلمة المرور'),
              ),
            ),
            Gap.h8,
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    /*
     * Checked here as well, because these two are answerable without asking
     * anybody: a round trip to be told the boxes do not match is a round trip
     * that told the customer nothing they could not already see.
     */
    if (_next.text.length < 8) {
      setState(() => _fault = 'كلمة المرور لازم تكون ٨ أحرف على الأقل.');

      return;
    }

    if (_next.text != _again.text) {
      setState(() => _fault = 'الكلمتان غير متطابقتين.');

      return;
    }

    setState(() {
      _sending = true;
      _fault = null;
    });

    final navigator = Navigator.of(context);

    try {
      await AppScope.session(context).changePassword(
        current: _current.text,
        next: _next.text,
      );

      navigator.pop(true);
    } on ApiFailure catch (fault) {
      if (mounted) {
        setState(() {
          _sending = false;
          /* The server knows whether the current one was wrong; this does not. */
          _fault = fault.message;
        });
      }
    }
  }
}
