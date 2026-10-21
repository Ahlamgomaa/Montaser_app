import 'package:flutter/material.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';
import '../browse_page.dart';

/// Choosing the order of a list.
class SortSheet extends StatelessWidget {
  const SortSheet({required this.current, super.key});

  final Sorting current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.md),
            child: Row(
              children: [Text('الترتيب حسب', style: context.type.titleMedium)],
            ),
          ),
          const Divider(height: 1),
          for (final one in Sorting.values)
            ListTile(
              title: Text(one.label),
              leading: Icon(
                one == current
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: one == current
                    ? context.scheme.primary
                    : context.palette.inkFaint,
              ),
              onTap: () => Navigator.pop(context, one),
            ),
          Gap.h16,
        ],
      ),
    );
  }
}
