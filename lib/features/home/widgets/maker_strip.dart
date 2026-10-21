import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/loader.dart';
import '../../../data/models/catalogue.dart';

/// The makers, as lettered badges.
class MakerStrip extends StatefulWidget {
  const MakerStrip({super.key});

  @override
  State<MakerStrip> createState() => _MakerStripState();
}

class _MakerStripState extends State<MakerStrip> {
  late Future<List<Maker>> _makers;

  @override
  void initState() {
    super.initState();
    _makers = AppScope.shop.catalogue.makers();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Loader<List<Maker>>(
        future: _makers,
        waiting: const LoadingNote(tall: false),
        isEmpty: (rows) => rows.isEmpty,
        empty: const SizedBox.shrink(),
        onRetry: () =>
            setState(() => _makers = AppScope.shop.catalogue.makers()),
        builder: (context, makers) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: Metric.pagePad,
          itemCount: makers.length,
          separatorBuilder: (_, _) => Gap.w12,
          itemBuilder: (context, at) => MakerBadge(maker: makers[at]),
        ),
      ),
    );
  }
}

/// One maker.
///
/// Set in Latin on purpose. These names are stamped on the parts in Latin, and
/// a customer matching what is in their hand against what is on the screen
/// should be comparing like with like — transliterating "Copeland" into Arabic
/// would make the match harder, not easier.
class MakerBadge extends StatelessWidget {
  const MakerBadge({required this.maker, this.wide = false, super.key});

  final Maker maker;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;
    final tone = colors.confettiFor(maker.id);

    return Material(
      color: context.scheme.surface,
      borderRadius: Corner.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Path.toBrowse(makerId: maker.id)),
        child: Container(
          width: wide ? null : 132,
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            borderRadius: Corner.rLg,
            border: Border.all(color: colors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  borderRadius: Corner.rSm,
                ),
                child: Text(
                  maker.initials.toUpperCase(),
                  textDirection: TextDirection.ltr,
                  style: type.labelMedium?.copyWith(color: tone),
                ),
              ),
              Gap.w8,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      maker.name,
                      textDirection: TextDirection.ltr,
                      style: type.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (maker.origin != null)
                      Text(
                        maker.origin!,
                        style: type.labelSmall?.copyWith(
                          color: colors.inkFaint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
