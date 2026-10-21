import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/routes.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/loader.dart';
import '../../core/widgets/section_head.dart';
import '../../data/models/catalogue.dart';
import '../catalogue/widgets/part_shelf.dart';
import 'widgets/aisle_strip.dart';
import 'widgets/certificate_badge.dart';
import 'widgets/hero_banner.dart';
import 'widgets/maker_strip.dart';
import 'widgets/promise_row.dart';
import 'widgets/shop_header.dart';

/// The shop front.
///
/// One call fills it. `home` answers with who the shop is, what it is
/// promoting, and three rows of parts — so the page has one thing to wait for
/// and one thing that can fail, rather than five spinners resolving at five
/// different moments.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<ShopFront> _front;

  @override
  void initState() {
    super.initState();
    _front = AppScope.shop.catalogue.front();
  }

  /// Ask again, from the top.
  ///
  /// The future is replaced rather than re-awaited: a `FutureBuilder` watches
  /// the object it was handed, so giving it the same completed future again
  /// would redraw the same failure.
  void _again() {
    setState(() => _front = AppScope.shop.catalogue.front());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
       * No SafeArea: the header runs under the status bar on purpose and pads
       * for it itself. Wrapping the lot would leave a strip of page colour
       * above the gradient.
       */
      body: RefreshIndicator(
        onRefresh: () async => _again(),
        child: Loader<ShopFront>(
          future: _front,
          onRetry: _again,
          waiting: const _Waiting(),
          builder: (context, front) => _Shop(front: front),
        ),
      ),
    );
  }
}

/// The page, once there is something to draw.
class _Shop extends StatelessWidget {
  const _Shop({required this.front});

  final ShopFront front;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: ShopHeader(identity: front.identity)),

        /* The guarantee, near the top where the question is actually asked. */
        SliverToBoxAdapter(child: CertificateBadge(identity: front.identity)),
        const SliverToBoxAdapter(child: SizedBox(height: Gap.lg)),

        if (front.slides.isNotEmpty)
          SliverToBoxAdapter(child: HeroBanner(slide: front.slides.first)),

        const SliverToBoxAdapter(child: PromiseRow()),

        SliverToBoxAdapter(
          child: SectionHead(
            title: 'الأقسام',
            lede: 'كل ما تحتاجه، مرتّباً كما في المخزن.',
            actionLabel: 'الكل',
            onAction: () => context.go(Path.aisles),
          ),
        ),
        const SliverToBoxAdapter(child: AisleStrip()),

        /*
         * Each shelf is drawn only when the shop has put something on it. A
         * heading over an empty rail is worse than no heading — it reads as a
         * section that failed to load rather than one the shop left empty.
         */
        if (front.featured.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHead(
              title: 'مختارات المتجر',
              lede: 'قطع نثق بها ونوصي بها.',
              actionLabel: 'الكل',
              onAction: () => context.push(Path.browse),
            ),
          ),
          SliverToBoxAdapter(child: PartShelf(parts: front.featured)),
        ],

        if (front.bestSellers.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHead(
              title: 'الأكثر مبيعاً',
              lede: 'ما يطلبه الناس أكثر من غيره.',
              actionLabel: 'الكل',
              onAction: () => context.push(Path.browse),
            ),
          ),
          SliverToBoxAdapter(child: PartShelf(parts: front.bestSellers)),
        ],

        SliverToBoxAdapter(
          child: SectionHead(
            title: 'الماركات',
            lede: 'وكلاء معتمدون وقطع أصلية.',
            actionLabel: 'الكل',
            onAction: () => context.push(Path.makers),
          ),
        ),
        const SliverToBoxAdapter(child: MakerStrip()),

        if (front.arrivals.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHead(
              title: 'وصل حديثاً',
              lede: 'آخر ما دخل المخزن.',
              actionLabel: 'الكل',
              onAction: () => context.push(Path.browse),
            ),
          ),
          SliverToBoxAdapter(child: PartShelf(parts: front.arrivals)),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: Metric.bottomRest)),
      ],
    );
  }
}

/// What the shop front looks like while it is coming.
///
/// The header is drawn straight away with nothing in it, so the page has its
/// shape before it has its contents. Waiting on a blank screen and then having
/// a coloured panel appear is two layouts; this is one.
class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ShopHeader(identity: ShopIdentity.unknown),
        SizedBox(height: Gap.huge),
        LoadingNote(tall: false),
      ],
    );
  }
}
