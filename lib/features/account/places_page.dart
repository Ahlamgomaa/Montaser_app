import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/routes.dart';
import '../../core/theme/dimens.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/empty_note.dart';
import '../../core/widgets/page_crown.dart';
import '../../core/widgets/pills.dart';
import '../../data/models/account.dart';

/// The address book.
class PlacesPage extends StatelessWidget {
  const PlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.sessionOf(context);
    final places = session.places;

    return Scaffold(
      floatingActionButton: places.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(Path.toPlaceForm()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('عنوان جديد'),
            ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageCrown(
              title: 'عناويني',
              lede: places.isEmpty
                  ? 'إلى أين نرسل طلباتك.'
                  : '${places.length} عناوين محفوظة',
              actions: [
                CrownAction(
                  glyph: Icons.add_rounded,
                  onTap: () => context.push(Path.toPlaceForm()),
                ),
              ],
            ),
          ),
          if (places.isEmpty)
            SliverToBoxAdapter(
              child: EmptyNote(
                glyph: Icons.location_off_outlined,
                title: 'لا توجد عناوين',
                body: 'أضف عنواناً لنعرف إلى أين نرسل طلباتك.',
                actionLabel: 'إضافة عنوان',
                onAction: () => context.push(Path.toPlaceForm()),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Gap.lg,
                Gap.md,
                Gap.lg,
                Metric.bottomRest,
              ),
              sliver: SliverList.builder(
                itemCount: places.length,
                itemBuilder: (context, at) => Padding(
                  padding: const EdgeInsets.only(bottom: Gap.md),
                  child: _PlaceCard(place: places[at]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Corner.rLg,
        border: Border.all(
          color: place.isDefault ? context.scheme.primary : colors.line,
          width: place.isDefault ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 18,
                color: context.scheme.primary,
              ),
              Gap.w8,
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
          Gap.h8,
          Text(
            place.oneLine,
            style: type.bodySmall?.copyWith(color: colors.inkSoft),
          ),
          if (place.landmark != null) ...[
            const SizedBox(height: 2),
            Text(
              'علامة مميزة: ${place.landmark}',
              style: type.labelSmall?.copyWith(color: colors.inkFaint),
            ),
          ],
          Gap.h4,
          Text(
            '${place.recipient} · ${place.phone}',
            style: type.labelSmall?.copyWith(color: colors.inkFaint),
          ),
          Gap.h12,
          Divider(height: 1, color: colors.line),
          Gap.h4,
          Row(
            children: [
              TextButton.icon(
                onPressed: () => context.push(Path.toPlaceForm(id: place.id)),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('تعديل'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (!place.isDefault)
                TextButton.icon(
                  onPressed: () =>
                      AppScope.session(context).makeDefault(place.id),
                  icon: const Icon(Icons.star_outline_rounded, size: 16),
                  label: const Text('اجعله الأساسي'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              const Spacer(),
              IconButton(
                onPressed: () => _confirmRemove(context),
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
                color: colors.danger,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final sure = await showDialog<bool>(
      context: context,
      /* The dialog's own context: `(_)` here popped the page instead. */
      builder: (dialog) => AlertDialog(
        title: const Text('حذف العنوان؟'),
        content: Text('سيُحذف «${place.label}» من عناوينك.'),
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
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if ((sure ?? false) && context.mounted) {
      AppScope.session(context).removePlace(place.id);
    }
  }
}
