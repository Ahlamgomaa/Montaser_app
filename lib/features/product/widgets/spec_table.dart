import 'package:flutter/material.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';

/// The specifications, as rows.
///
/// A table rather than a paragraph, because this is the part of the page a
/// customer reads with a part in their other hand, comparing one value at a
/// time. Prose makes them hunt for the voltage; rows let them find it.
class SpecTable extends StatelessWidget {
  const SpecTable({required this.specs, super.key});

  final List<(String, String)> specs;

  @override
  Widget build(BuildContext context) {
    if (specs.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.palette;
    final type = context.type;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المواصفات', style: type.titleSmall),
          Gap.h12,
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.scheme.surface,
              borderRadius: Corner.rLg,
              border: Border.all(color: colors.line),
            ),
            child: Column(
              children: [
                for (var at = 0; at < specs.length; at++) ...[
                  if (at > 0) Divider(height: 1, color: colors.line),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Gap.lg,
                      vertical: Gap.md,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 116,
                          child: Text(
                            specs[at].$1,
                            style: type.bodySmall?.copyWith(
                              color: colors.inkFaint,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            specs[at].$2,
                            style: type.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
