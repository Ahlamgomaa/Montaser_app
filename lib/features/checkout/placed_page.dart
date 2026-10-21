import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/theme/dimens.dart';
import '../../core/theme/palette.dart';

/// The order went through.
///
/// The reference is the whole point of this screen and so it is the largest
/// thing on it, and it can be copied. It is what a customer quotes on the phone
/// when they ring to ask, and a number they cannot select is a number they will
/// transcribe wrongly.
class PlacedPage extends StatelessWidget {
  const PlacedPage({required this.orderId, required this.reference, super.key});

  /// What the server knows it by, so "track my order" can open it.
  final int orderId;

  /// What the customer reads and quotes on the telephone.
  final String reference;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.successWash,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 52,
                  color: colors.success,
                ),
              ),
              Gap.h32,
              Text(
                'تم إصدار طلبك',
                style: type.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Gap.h8,
              Text(
                'وصلنا طلبك ونبدأ تجهيزه الآن. سنُبلغك بكل خطوة.',
                style: type.bodyMedium?.copyWith(color: colors.inkSoft),
                textAlign: TextAlign.center,
              ),
              Gap.h32,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Gap.lg),
                decoration: BoxDecoration(
                  color: context.scheme.surface,
                  borderRadius: Corner.rLg,
                  border: Border.all(color: colors.line),
                ),
                child: Column(
                  children: [
                    Text(
                      'رقم الطلب',
                      style: type.labelSmall?.copyWith(color: colors.inkFaint),
                    ),
                    Gap.h4,
                    SelectableText(
                      reference,
                      textDirection: TextDirection.ltr,
                      style: type.headlineSmall?.copyWith(
                        color: context.scheme.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    Gap.h12,
                    Divider(height: 1, color: colors.line),
                    Gap.h12,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: colors.inkFaint,
                        ),
                        Gap.w8,
                        Text(
                          'التسليم المتوقع خلال يومين إلى أربعة أيام',
                          style: type.bodySmall?.copyWith(
                            color: colors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go(Path.toOrder(orderId)),
                child: const Text('تتبّع الطلب'),
              ),
              Gap.h12,
              OutlinedButton(
                onPressed: () => context.go(Path.home),
                child: const Text('العودة إلى المتجر'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
