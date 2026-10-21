import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/loader.dart';
import '../../core/widgets/page_crown.dart';
import '../../data/models/catalogue.dart';
import '../home/widgets/maker_strip.dart';

/// Every maker.
///
/// Answered by the server, which lists the makes the shop actually stocks
/// rather than every make that exists. A list written into the app would go on
/// offering a brand months after the shop stopped carrying it.
class MakersPage extends StatefulWidget {
  const MakersPage({super.key});

  @override
  State<MakersPage> createState() => _MakersPageState();
}

class _MakersPageState extends State<MakersPage> {
  late Future<List<Maker>> _makers;

  @override
  void initState() {
    super.initState();
    _makers = AppScope.shop.catalogue.makers();
  }

  void _again() {
    final next = AppScope.shop.catalogue.makers();

    setState(() {
      _makers = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _again(),
        child: Loader<List<Maker>>(
          future: _makers,
          onRetry: _again,
          builder: (context, makers) => _Grid(makers: makers),
        ),
      ),
    );
  }
}

/// The makes, once there are some.
class _Grid extends StatelessWidget {
  const _Grid({required this.makers});

  final List<Maker> makers;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: PageCrown(
            title: 'الماركات',
            lede: 'وكلاء معتمدون وقطع أصلية.',
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            Gap.lg,
            Gap.sm,
            Gap.lg,
            Metric.bottomRest,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisSpacing: Gap.md,
              crossAxisSpacing: Gap.md,
              mainAxisExtent: 70,
            ),
            itemCount: makers.length,
            itemBuilder: (context, at) =>
                MakerBadge(maker: makers[at], wide: true),
          ),
        ),
      ],
    );
  }
}
