import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/glyphs.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/loader.dart';
import '../../../data/models/catalogue.dart';

/// The departments, as a run of tiles.
///
/// Fetched here rather than passed down from the shop front. The departments
/// are the same on every screen that shows them and change about once a year,
/// so the call is cheap; and asking for them here means this strip can be
/// dropped onto any page without that page having to know it needs to fetch
/// something first.
class AisleStrip extends StatefulWidget {
  const AisleStrip({super.key});

  @override
  State<AisleStrip> createState() => _AisleStripState();
}

class _AisleStripState extends State<AisleStrip> {
  late Future<List<Aisle>> _aisles;

  @override
  void initState() {
    super.initState();
    _aisles = AppScope.shop.catalogue.aisles();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AisleTile.tall,
      child: Loader<List<Aisle>>(
        future: _aisles,
        waiting: const LoadingNote(tall: false),
        isEmpty: (rows) => rows.isEmpty,
        /*
         * Nothing at all rather than a message. A shop with no departments is
         * a shop still being set up, and the customer has the rest of the page
         * to look at — an error box in the middle of it would be the loudest
         * thing on the screen and the least useful.
         */
        empty: const SizedBox.shrink(),
        onRetry: () =>
            setState(() => _aisles = AppScope.shop.catalogue.aisles()),
        builder: (context, aisles) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: Metric.pagePad,
          itemCount: aisles.length,
          separatorBuilder: (_, _) => Gap.w12,
          itemBuilder: (context, at) => AisleTile(aisle: aisles[at]),
        ),
      ),
    );
  }
}

/// One department.
class AisleTile extends StatelessWidget {
  const AisleTile({required this.aisle, this.wide = false, super.key});

  /// How tall one of these is, wherever it appears.
  ///
  /// Read by the strip and by the grid on the departments page, so the two
  /// cannot drift. Cairo sits lower in its box than the system face and needs
  /// a looser line; the number that fitted before the real font arrived was six
  /// pixels short of fitting after it.
  static const tall = 132.0;

  final Aisle aisle;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Material(
      color: context.scheme.surface,
      borderRadius: Corner.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Path.toBrowse(aisleId: aisle.id)),
        child: Container(
          width: wide ? null : 104,
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            borderRadius: Corner.rLg,
            border: Border.all(color: colors.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.confettiFor(aisle.id).withValues(alpha: 0.14),
                  borderRadius: Corner.rMd,
                ),
                child: Icon(
                  Glyphs.aisle(aisle.slug),
                  size: 21,
                  color: colors.confettiFor(aisle.id),
                ),
              ),
              Gap.h8,
              Flexible(
                child: Text(
                  aisle.name,
                  style: type.labelMedium,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              /*
               * Only when the shop counted. A department labelled "0 قطعة"
               * because the endpoint does not send a count reads as empty, and
               * would keep customers out of a department that is full.
               */
              if (aisle.count != null)
                Flexible(
                  child: Text(
                    '${aisle.count} قطعة',
                    style: type.labelSmall?.copyWith(color: colors.inkFaint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
