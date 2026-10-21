import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/theme/dimens.dart';
import '../../core/theme/glyphs.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/empty_note.dart';
import '../../core/widgets/page_crown.dart';
import '../../core/widgets/pills.dart';
import '../../app/app_scope.dart';
import '../../core/widgets/loader.dart';
import '../../data/models/order.dart';

/// Everything the customer has ordered.
///
/// Asked of the server every time the screen opens. An order moves while
/// nobody is looking at it — it is packed, it ships, it arrives — and a list
/// held in the app would go on saying whatever it said when it was last built.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<Order>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = AppScope.shop.orders.mine();
  }

  void _again() {
    final next = AppScope.shop.orders.mine();

    setState(() {
      _orders = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _again(),
        child: Loader<List<Order>>(
          future: _orders,
          onRetry: _again,
          builder: (context, orders) => _List(orders: orders),
        ),
      ),
    );
  }
}

/// The orders, once they have arrived.
class _List extends StatelessWidget {
  const _List({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageCrown(
              title: 'طلباتي',
              lede: orders.isEmpty
                  ? 'كل ما طلبته، وأين وصل.'
                  : '${orders.length} طلبات',
            ),
          ),
          if (orders.isEmpty)
            SliverToBoxAdapter(
              child: EmptyNote(
                glyph: Icons.receipt_long_outlined,
                title: 'لا توجد طلبات بعد',
                body: 'حين تطلب شيئاً ستجده هنا بكل تفاصيله.',
                actionLabel: 'تصفّح القطع',
                onAction: () => context.go(Path.home),
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
                itemCount: orders.length,
                itemBuilder: (context, at) => Padding(
                  padding: const EdgeInsets.only(bottom: Gap.md),
                  child: OrderCard(order: orders[at]),
                ),
              ),
            ),
      ],
    );
  }
}

/// One order, summarised.
///
/// The reference, the state and the total — the three things somebody scanning
/// a list is looking for. The parts are named underneath because an order
/// identified only by a number is one the customer has to open to recognise.
class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Material(
      color: context.scheme.surface,
      borderRadius: Corner.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Path.toOrder(order.id)),
        child: Container(
          padding: const EdgeInsets.all(Gap.lg),
          decoration: BoxDecoration(
            borderRadius: Corner.rLg,
            border: Border.all(color: colors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    order.reference,
                    textDirection: TextDirection.ltr,
                    style: type.titleSmall,
                  ),
                  const Spacer(),
                  OrderStatePill(order: order),
                ],
              ),
              Gap.h4,
              Text(
                order.placedAt == null
                    ? ''
                    : Dates.fullWithClock(order.placedAt!),
                style: type.labelSmall?.copyWith(color: colors.inkFaint),
              ),
              Gap.h12,
              Divider(height: 1, color: colors.line),
              Gap.h12,
              for (final line in order.lines.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '${line.quantity}×',
                        style: type.labelSmall?.copyWith(
                          color: colors.inkFaint,
                        ),
                      ),
                      Gap.w8,
                      Expanded(
                        child: Text(
                          line.name,
                          style: type.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (order.lines.length > 2)
                Text(
                  'و${order.lines.length - 2} قطعة أخرى',
                  style: type.labelSmall?.copyWith(color: colors.inkFaint),
                ),
              Gap.h12,
              Row(
                children: [
                  Text(
                    '${order.pieces} قطعة',
                    style: type.labelSmall?.copyWith(color: colors.inkFaint),
                  ),
                  const Spacer(),
                  Text(
                    Money.of(order.totals.total),
                    style: type.titleSmall?.copyWith(color: colors.price),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where the order stands, as one badge.
///
/// A cancelled order shows its misstep instead of its last step. It did not
/// reach «جارٍ التحضير» and stop there — it left, and saying otherwise would
/// have a customer waiting for something that is not coming.
class OrderStatePill extends StatelessWidget {
  const OrderStatePill({required this.order, this.tight = true, super.key});

  final Order order;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    final standing = order.standing;

    /*
     * The colour follows the shop's own word for how this reads — `success`,
     * `warning`, `danger` — rather than a list of states kept here. The app
     * decides what a tone looks like; it does not decide which states are good,
     * because that answer changes when the shop adds a state and this file
     * would not know.
     */
    final (ink, bed) = switch (standing.tone) {
      'success' => (colors.success, colors.successWash),
      'warning' => (colors.warn, colors.warnWash),
      'danger' => (colors.danger, colors.dangerWash),
      'primary' => (context.scheme.primary, context.scheme.primaryContainer),
      _ => (colors.inkSoft, colors.canvas),
    };

    return Pill(
      label: standing.label,
      ink: ink,
      bed: bed,
      glyph: Glyphs.standing(standing.value, wentWrong: standing.wentWrong),
      tight: tight,
    );
  }
}
