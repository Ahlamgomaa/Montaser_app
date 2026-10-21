import 'package:flutter/material.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/pills.dart';
import '../../../data/models/account.dart';

/// Choosing where it goes.
///
/// Tapping a card chooses it. There is no separate «اعتماد» button under the
/// list: the tap already said which one, and asking for a second confirmation
/// of a choice the customer can see they made is a step that exists only to be
/// got through.
class PlaceChoice extends StatelessWidget {
  const PlaceChoice({
    required this.places,
    required this.chosen,
    required this.onChoose,
    required this.onAdd,
    super.key,
  });

  final List<Place> places;
  final Place? chosen;
  final ValueChanged<Place> onChoose;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('عنوان التوصيل', style: context.type.titleSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('عنوان جديد'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          Gap.h8,
          if (places.isEmpty)
            _NoPlaces(onAdd: onAdd)
          else
            for (final place in places) ...[
              _PlaceCard(
                place: place,
                chosen: place.id == chosen?.id,
                onTap: () => onChoose(place),
              ),
              Gap.h8,
            ],
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.chosen,
    required this.onTap,
  });

  final Place place;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Material(
      color: context.scheme.surface,
      borderRadius: Corner.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(Gap.lg),
          decoration: BoxDecoration(
            borderRadius: Corner.rLg,
            border: Border.all(
              color: chosen ? context.scheme.primary : colors.line,
              width: chosen ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                chosen
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: chosen ? context.scheme.primary : colors.inkFaint,
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(place.label, style: type.titleSmall),
                        if (place.isDefault) ...[
                          Gap.w8,
                          Pill(
                            label: 'الأساسي',
                            ink: context.scheme.primary,
                            bed: context.scheme.primaryContainer,
                            tight: true,
                          ),
                        ],
                      ],
                    ),
                    Gap.h4,
                    Text(
                      place.oneLine,
                      style: type.bodySmall?.copyWith(color: colors.inkSoft),
                    ),
                    if (place.landmark != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 13,
                            color: colors.inkFaint,
                          ),
                          Gap.w4,
                          Expanded(
                            child: Text(
                              place.landmark!,
                              style: type.labelSmall?.copyWith(
                                color: colors.inkFaint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    Gap.h4,
                    Text(
                      '${place.recipient} · ${place.phone}',
                      style: type.labelSmall?.copyWith(color: colors.inkFaint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoPlaces extends StatelessWidget {
  const _NoPlaces({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Corner.rLg,
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, size: 28, color: colors.inkFaint),
          Gap.h12,
          Text(
            'لم تُضِف عنواناً بعد',
            style: context.type.titleSmall,
            textAlign: TextAlign.center,
          ),
          Gap.h4,
          Text(
            'أضف عنواناً لنعرف إلى أين نرسل الطلب.',
            style: context.type.bodySmall?.copyWith(color: colors.inkFaint),
            textAlign: TextAlign.center,
          ),
          Gap.h16,
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('إضافة عنوان'),
          ),
        ],
      ),
    );
  }
}
