import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/empty_note.dart';
import '../../core/widgets/loader.dart';
import '../../core/widgets/page_crown.dart';
import '../../data/models/catalogue.dart';
import '../home/widgets/aisle_strip.dart';

/// Every department, in a grid.
///
/// The list comes from the server rather than from anything written here: an
/// aisle added at head office has to appear in the app without a new release,
/// and a copy kept in the application is a copy that is wrong the first time
/// somebody adds one.
class AislesPage extends StatefulWidget {
  const AislesPage({super.key});

  @override
  State<AislesPage> createState() => _AislesPageState();
}

class _AislesPageState extends State<AislesPage> {
  late Future<List<Aisle>> _aisles;

  @override
  void initState() {
    super.initState();
    _aisles = AppScope.shop.catalogue.aisles();
  }

  /// Ask again, from the top.
  ///
  /// The future is replaced rather than re-awaited: a `FutureBuilder` watches
  /// the object it was handed, so handing back the same completed future would
  /// redraw the same failure.
  void _again() {
    final next = AppScope.shop.catalogue.aisles();

    setState(() {
      _aisles = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _again(),
        child: Loader<List<Aisle>>(
          future: _aisles,
          onRetry: _again,
          isEmpty: (aisles) => aisles.isEmpty,
          empty: _None(onRetry: _again),
          builder: (context, aisles) => _Grid(aisles: aisles),
        ),
      ),
    );
  }
}

/// No departments yet — a shop still being set up, not a failure.
///
/// The crown stays, so the page is still recognisably the departments page,
/// and the list can still be pulled to ask again.
class _None extends StatelessWidget {
  const _None({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const PageCrown(
          title: 'الأقسام',
          lede: 'كل ما تحتاجه، مرتّباً كما في المخزن.',
          showBack: false,
        ),
        EmptyNote(
          glyph: Icons.grid_view_rounded,
          title: 'لا توجد أقسام بعد',
          body: 'لم يُضِف المتجر أقساماً حتى الآن. اسحب للأسفل للتحديث.',
          actionLabel: 'تحديث',
          onAction: onRetry,
        ),
      ],
    );
  }
}

/// The departments, once there are some.
class _Grid extends StatelessWidget {
  const _Grid({required this.aisles});

  final List<Aisle> aisles;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: PageCrown(
            title: 'الأقسام',
            lede: 'كل ما تحتاجه، مرتّباً كما في المخزن.',
            showBack: false,
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
              maxCrossAxisExtent: 180,
              mainAxisSpacing: Gap.md,
              crossAxisSpacing: Gap.md,
              mainAxisExtent: 128,
            ),
            itemCount: aisles.length,
            itemBuilder: (context, at) =>
                AisleTile(aisle: aisles[at], wide: true),
          ),
        ),
      ],
    );
  }
}
