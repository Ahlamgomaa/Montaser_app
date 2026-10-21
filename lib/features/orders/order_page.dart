import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/page_crown.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/empty_note.dart';
import '../../app/app_scope.dart';
import '../../core/widgets/loader.dart';
import '../../data/models/order.dart';
import '../basket/widgets/totals_card.dart';
import 'orders_page.dart';
import 'widgets/order_road.dart';

/// One order, in full.
///
/// Fetched rather than passed in. The card that opened this screen carries a
/// summary — enough for a list and not enough for a page — and the lines, the
/// address and the road it travelled only arrive on the detail call.
class OrderPage extends StatefulWidget {
  const OrderPage({required this.id, super.key});

  final int id;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late Future<Order> _order;

  @override
  void initState() {
    super.initState();
    _order = AppScope.shop.orders.one(widget.id);
  }

  void _again() {
    final next = AppScope.shop.orders.one(widget.id);

    setState(() {
      _order = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _again(),
        child: Loader<Order>(
          future: _order,
          onRetry: _again,
          /*
           * An order that is not there is not a network fault. It is a link to
           * somebody else's order, or one that was opened from a stale list.
           */
          onMissing: (context) => ListView(
            children: [
              const PageCrown(title: 'الطلب'),
              EmptyNote(
                glyph: Icons.receipt_long_outlined,
                title: 'لم نجد هذا الطلب',
                body: 'راجع رقم الطلب، أو افتحه من قائمة طلباتك.',
                actionLabel: 'طلباتي',
                onAction: () => context.pushReplacement(Path.orders),
              ),
            ],
          ),
          builder: (context, order) => _Order(order: order),
        ),
      ),
    );
  }
}

/// The order, once it has arrived.
class _Order extends StatelessWidget {
  const _Order({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return ListView(
      padding: const EdgeInsets.only(bottom: Metric.bottomRest),
        children: [
          PageCrown(
            title: order.reference,
            lede: '${order.pieces} قطعة· ${order.shippingMethod ?? ""}',
            actions: [
              CrownAction(
                glyph: Icons.copy_rounded,
                /*
                 * Copied for real. This used to say "copied" and put nothing
                 * on the clipboard.
                 */
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);

                  await Clipboard.setData(
                    ClipboardData(text: order.reference),
                  );

                  messenger
                    ..clearSnackBars()
                    ..showSnackBar(
                      const SnackBar(content: Text('نُسخ رقم الطلب.')),
                    );
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 0),
            child: Row(
              children: [
                OrderStatePill(order: order, tight: false),
                const Spacer(),
                Text(
                  order.placedAt == null ? '' : Dates.fullWithClock(order.placedAt!),
                  style: type.labelSmall?.copyWith(color: colors.inkFaint),
                ),
              ],
            ),
          ),

          OrderRoad(order: order),

          if (!order.wentWrong &&
              order.expectedFrom != null &&
              order.expectedTo != null)
            _Expected(from: order.expectedFrom!, to: order.expectedTo!),

          _Block(
            title: 'القطع',
            child: Column(
              children: [
                for (var at = 0; at < order.lines.length; at++) ...[
                  if (at > 0) Divider(height: Gap.xl, color: colors.line),
                  _LineRow(line: order.lines[at]),
                ],
              ],
            ),
          ),

          _Block(
            title: 'التوصيل',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Fact(
                  glyph: Icons.place_outlined,
                  label: 'العنوان',
                  value: order.recipient?.oneLine ?? '',
                ),
                Gap.h12,
                _Fact(
                  glyph: Icons.local_shipping_outlined,
                  label: 'طريقة الشحن',
                  value: order.shippingMethod ?? '',
                ),
                Gap.h12,
                _Fact(
                  glyph: Icons.payments_outlined,
                  label: 'طريقة الدفع',
                  value: order.payment.method,
                ),
              ],
            ),
          ),

          Gap.h16,
          Padding(
            padding: Metric.pagePad,
            child: TotalsCard(totals: order.totals),
          ),

          Gap.h24,
          Padding(
            padding: Metric.pagePad,
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('سنتواصل معك بخصوص هذا الطلب.'),
                        ),
                      );
                  },
                  icon: const Icon(Icons.support_agent_outlined, size: 18),
                  label: const Text('تواصل بخصوص الطلب'),
                ),
                if (order.standing.step >= order.standing.steps &&
                    !order.wentWrong) ...[
                  Gap.h12,
                  FilledButton.icon(
                    onPressed: () => context.go(Path.home),
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('اطلب مرة أخرى'),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Expected extends StatelessWidget {
  const _Expected({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Container(
      margin: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 0),
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: context.scheme.primaryContainer,
        borderRadius: Corner.rLg,
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 22,
            color: context.scheme.primary,
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التسليم المتوقع',
                  style: context.type.labelSmall?.copyWith(
                    color: context.scheme.primary,
                  ),
                ),
                Text(
                  Dates.window(from, to),
                  style: context.type.titleSmall?.copyWith(
                    color: context.scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.schedule_rounded, size: 18, color: colors.inkFaint),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.type.titleSmall),
          Gap.h12,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Gap.lg),
            decoration: BoxDecoration(
              color: context.scheme.surface,
              borderRadius: Corner.rLg,
              border: Border.all(color: colors.line),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.canvas,
            borderRadius: Corner.rSm,
          ),
          child: Text('${line.quantity}', style: type.labelMedium),
        ),
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.name, style: type.bodyMedium),
              Text(
                line.code,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                style: type.labelSmall?.copyWith(color: colors.inkFaint),
              ),
            ],
          ),
        ),
        Gap.w8,
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Money.of(line.lineTotal),
              style: type.labelMedium?.copyWith(color: colors.price),
            ),
            if (line.quantity > 1)
              Text(
                '${Money.of(line.unitPrice)} × ${line.quantity}',
                style: type.labelSmall?.copyWith(color: colors.inkFaint),
              ),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.glyph, required this.label, required this.value});

  final IconData glyph;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(glyph, size: 18, color: colors.inkFaint),
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.type.labelSmall?.copyWith(
                  color: colors.inkFaint,
                ),
              ),
              Text(value, style: context.type.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
