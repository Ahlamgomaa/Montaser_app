import 'package:flutter/material.dart';

import '../../../core/format/dates.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/glyphs.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/order.dart';

/// The road the order travels, drawn.
///
/// Every stop is shown, including the ones still ahead — a customer wants to
/// know what happens next, not only what has happened. The stops behind are
/// filled and dated; the ones ahead are outlined and silent.
///
/// The stops themselves arrive with the order. The shop owns the journey: how
/// many there are and what each is called. A road with four stages written into
/// the app is a road that lies the day the shop adds a fifth.
///
/// An order that went wrong is drawn differently: the road stops where it
/// stopped and the reason is shown at the end of it. Continuing the line past a
/// cancellation would promise a delivery that is not coming.
class OrderRoad extends StatelessWidget {
  const OrderRoad({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final standing = order.standing;

    /*
     * Cut at wherever it stopped. `step` counts from one, so it is also the
     * number of stops worth keeping.
     */
    final stops = order.wentWrong
        ? order.journey.take(standing.step).toList(growable: false)
        : order.journey;

    if (stops.isEmpty && !order.wentWrong) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Corner.rLg,
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var at = 0; at < stops.length; at++)
            _Stop(
              stop: stops[at],
              /* `step` counts from one; `at` counts from zero. */
              reached: at < standing.step,
              current: !order.wentWrong && at == standing.step - 1,
              last: at == stops.length - 1 && !order.wentWrong,
              at: order.reachedAt(stops[at].value),
            ),
          if (order.wentWrong) _WentWrong(standing: standing),
        ],
      ),
    );
  }
}

/// One stop, and the line leading away from it.
class _Stop extends StatelessWidget {
  const _Stop({
    required this.stop,
    required this.reached,
    required this.current,
    required this.last,
    required this.at,
  });

  final OrderStop stop;
  final bool reached;
  final bool current;
  final bool last;
  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;
    final tone = reached ? context.scheme.primary : colors.inkFaint;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: reached
                      ? context.scheme.primary
                      : context.scheme.surface,
                  border: Border.all(
                    color: reached ? context.scheme.primary : colors.line,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Glyphs.standing(stop.value),
                  size: 15,
                  color: reached ? context.scheme.onPrimary : colors.inkFaint,
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: reached ? context.scheme.primary : colors.line,
                  ),
                ),
            ],
          ),
          Gap.w12,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : Gap.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          stop.label,
                          style: type.titleSmall?.copyWith(
                            color: reached ? null : colors.inkFaint,
                          ),
                        ),
                      ),
                      if (current) ...[
                        Gap.w8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: context.scheme.primaryContainer,
                            borderRadius: Corner.pill,
                          ),
                          child: Text(
                            'الآن',
                            style: type.labelSmall?.copyWith(
                              color: context.scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  /*
                   * The date only where there is one. A stop still ahead has
                   * not happened, and an empty line under it reads as missing
                   * rather than as future.
                   */
                  if (at != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 12, color: tone),
                        Gap.w4,
                        Text(
                          Dates.fullWithClock(at!),
                          style: type.labelSmall?.copyWith(color: tone),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the road stopped, and why.
class _WentWrong extends StatelessWidget {
  const _WentWrong({required this.standing});

  final OrderStanding standing;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.dangerWash,
            border: Border.all(color: colors.danger, width: 1.5),
          ),
          child: Icon(
            Glyphs.standing(standing.value, wentWrong: true),
            size: 15,
            color: colors.danger,
          ),
        ),
        Gap.w12,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              /* The word the shop uses for it, not one chosen here. */
              standing.label,
              style: context.type.titleSmall?.copyWith(color: colors.danger),
            ),
          ),
        ),
      ],
    );
  }
}
