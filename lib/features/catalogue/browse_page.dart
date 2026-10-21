import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/repositories/catalogue_repository.dart';
import '../../data/api/api_failure.dart';
import '../../core/widgets/loader.dart';
import '../../app/routes.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/page_crown.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/empty_note.dart';
import '../../data/models/catalogue.dart';
import 'widgets/part_card.dart';
import 'widgets/sort_sheet.dart';

/// How a list of parts may be ordered.
enum Sorting {
  chosen('المختارة أولاً', 'featured'),
  newest('الأحدث', 'newest'),
  cheapest('الأقل سعراً', 'cheapest'),
  dearest('الأعلى سعراً', 'dearest'),
  rated('الأعلى تقييماً', 'rated');

  const Sorting(this.label, this.wire);

  final String label;

  /// The word the server knows this ordering by.
  ///
  /// Kept beside the label so the two cannot drift: a screen showing
  /// "cheapest" while sending something the server does not recognise gets the
  /// default ordering back and looks as though it ignored the tap.
  final String wire;
}

/// The catalogue, filtered.
///
/// One screen serves browsing, an aisle, a maker and a search, because they are
/// the same screen with a different starting filter. Writing four would mean
/// four places to fix the day the card layout changes.
class BrowsePage extends StatefulWidget {
  const BrowsePage({
    this.aisleId,
    this.makerId,
    this.title,
    this.query,
    super.key,
  });

  /// Narrowed by key rather than by name: the server filters on one, and a
  /// name would have to be matched back to a row somewhere.
  final int? aisleId;
  final int? makerId;

  /// What to put in the crown, so the page need not fetch a name to show one.
  final String? title;

  final String? query;

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  late final TextEditingController _search = TextEditingController(
    text: widget.query ?? '',
  );

  int? _aisleId;
  int? _makerId;
  String? _aisle;
  String? _maker;
  Sorting _sort = Sorting.chosen;
  bool _inStockOnly = false;

  /// The shelf, as the server narrowed it.
  ///
  /// Asked of the server rather than filtered here, and that is not a detail:
  /// the shop has thousands of parts and the app holds one page of them. A
  /// filter applied to whatever happened to be loaded would search a fraction
  /// of the catalogue and report it as the whole.
  late Future<PartPage> _results;

  /// What the filter chips offer, fetched once.
  late Future<List<Aisle>> _aisles;
  late Future<List<Maker>> _makers;

  @override
  void initState() {
    super.initState();

    _aisleId = widget.aisleId;
    _makerId = widget.makerId;
    _aisle = widget.aisleId != null ? widget.title : null;
    _maker = widget.makerId != null ? widget.title : null;

    _aisles = AppScope.shop.catalogue.aisles();
    _makers = AppScope.shop.catalogue.makers();

    _run();
  }

  /// Ask again, with whatever is chosen now.
  void _run() {
    setState(() {
      _results = AppScope.shop.catalogue.search(
        PartQuery(
          text: _search.text.trim(),
          aisleId: _aisleId,
          makerId: _makerId,
          sort: _sort.wire,
        ),
      );
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// How many chips are on, for the "clear" line.
  int get _filterCount =>
      (_aisleId != null ? 1 : 0) +
      (_makerId != null ? 1 : 0) +
      (_inStockOnly ? 1 : 0);

  /// The line under the title, once the count is known.
  String get _lede => 'كل القطع المتاحة';

  String get _heading {
    if (_maker != null) {
      return _maker!;
    }

    if (_aisle != null) {
      return _aisle!;
    }

    return 'كل القطع';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PageCrown(
            title: _heading,
            lede: _lede,
            actions: [
              CrownAction(glyph: Icons.swap_vert_rounded, onTap: _openSort),
            ],
            trailing: AppSearchField(
              controller: _search,
              /* Asked of the server on each change: the catalogue is
                 larger than any page of it held here. */
              onChanged: (_) => _run(),
              onClear: () {
                _search.clear();
                _run();
              },
            ),
          ),
          Gap.h8,
          _FilterBar(
            aisles: _aisles,
            makers: _makers,
            aisle: _aisle,
            maker: _maker,
            inStockOnly: _inStockOnly,
            sort: _sort,
            onAisle: (next) {
              setState(() {
                _aisleId = next?.id;
                _aisle = next?.name;
              });
              _run();
            },
            onMaker: (next) {
              setState(() {
                _makerId = next?.id;
                _maker = next?.name;
              });
              _run();
            },
            onInStock: () => setState(() => _inStockOnly = !_inStockOnly),
            onSort: _openSort,
          ),
          Expanded(
            child: Loader<PartPage>(
              future: _results,
              onRetry: _run,
              isEmpty: (page) => _visible(page.parts).isEmpty,
              empty: EmptyNote(
                glyph: Icons.search_off_rounded,
                title: 'لا توجد نتائج',
                body: 'جرّب كلمة أخرى، أو أزل بعض عوامل التصفية.',
                actionLabel: _filterCount > 0 ? 'أزل التصفية' : null,
                onAction: _filterCount > 0 ? _clear : null,
              ),
              builder: (context, page) => Column(
                children: [
                  _CountLine(
                    count: page.total,
                    filters: _filterCount,
                    onClear: _clear,
                  ),
                  Expanded(child: _Grid(parts: _visible(page.parts))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clear() {
    setState(() {
      _aisleId = null;
      _makerId = null;
      _aisle = null;
      _maker = null;
      _inStockOnly = false;
      _search.clear();
    });

    _run();
  }

  /// The page, less anything the customer asked not to see.
  ///
  /// "In stock only" is applied here rather than sent, because the server has
  /// no such filter — what can be bought is the shelf less what other baskets
  /// are holding, worked out per request. Applied to the page in hand, so the
  /// count above still says what the shop has: a total that changed with a
  /// local filter would be the app reporting on a fraction of the catalogue.
  List<Part> _visible(List<Part> parts) {
    if (!_inStockOnly) {
      return parts;
    }

    return parts
        .where((one) => one.availability != Availability.none)
        .toList(growable: false);
  }

  Future<void> _openSort() async {
    final picked = await showModalBottomSheet<Sorting>(
      context: context,
      builder: (_) => SortSheet(current: _sort),
    );

    if (picked != null && mounted) {
      setState(() => _sort = picked);
      _run();
    }
  }
}

/// The grid itself.
class _Grid extends StatelessWidget {
  const _Grid({required this.parts});

  final List<Part> parts;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        Gap.lg,
        Gap.sm,
        Gap.lg,
        Metric.bottomRest,
      ),
      /*
       * A maximum width rather than a fixed count, so the grid answers the
       * screen instead of the phone it was designed on: two columns on a
       * handset, three on a large one, four on a tablet — without a breakpoint
       * written anywhere.
       */
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisSpacing: Gap.md,
        crossAxisSpacing: Gap.md,
        mainAxisExtent: PartCard.tall,
      ),
      itemCount: parts.length,
      itemBuilder: (context, at) => _GridCard(part: parts[at]),
    );
  }
}

/// Put a part in the basket, and say what happened either way.
Future<void> _add(BuildContext context, Part part) async {
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);

  try {
    await AppScope.basket(context).add(part.id);
  } on ApiFailure catch (fault) {
    /* The server's own sentence: "only two left" is something to act on. */
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(fault.message)));

    return;
  }

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: const Text('أُضيفت إلى السلة.'),
        action: SnackBarAction(
          label: 'السلة',
          onPressed: () => router.go(Path.basket),
        ),
      ),
    );
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.part});

  final Part part;

  @override
  Widget build(BuildContext context) {
    final basket = AppScope.basketOf(context);
    final session = AppScope.sessionOf(context);

    return PartCard(
      part: part,
      inBasket: basket.quantityOf(part.id),
      isKept: session.keeps(part.id),
      onKeep: () => session.toggleKept(part.id),
      onOpen: () => context.push(Path.toPart(part.slug)),
      onAdd: () => _add(context, part),
    );
  }
}

/// The scrolling row of filters.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.aisles,
    required this.makers,
    required this.aisle,
    required this.maker,
    required this.inStockOnly,
    required this.sort,
    required this.onAisle,
    required this.onMaker,
    required this.onInStock,
    required this.onSort,
  });

  /// What the shop actually has, fetched once by the page above.
  final Future<List<Aisle>> aisles;
  final Future<List<Maker>> makers;

  final String? aisle;
  final String? maker;
  final bool inStockOnly;
  final Sorting sort;

  /// Null clears the filter.
  final ValueChanged<Aisle?> onAisle;
  final ValueChanged<Maker?> onMaker;

  final VoidCallback onInStock;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: Metric.pagePad,
        children: [
          _Chip(
            label: sort.label,
            glyph: Icons.swap_vert_rounded,
            on: sort != Sorting.chosen,
            onTap: onSort,
          ),
          Gap.w8,
          _Chip(
            label: 'متوفر فقط',
            glyph: Icons.check_circle_outline,
            on: inStockOnly,
            onTap: onInStock,
          ),

          Gap.w8,
          _Chip(
            label: aisle ?? 'القسم',
            glyph: Icons.grid_view_rounded,
            on: aisle != null,
            onTap: () async {
              final rows = await aisles;

              if (!context.mounted) {
                return;
              }

              await _pick<Aisle>(
                context,
                title: 'القسم',
                options: rows,
                nameOf: (one) => one.name,
                current: aisle,
                onPicked: onAisle,
              );
            },
          ),
          Gap.w8,
          _Chip(
            label: maker ?? 'الماركة',
            glyph: Icons.factory_outlined,
            on: maker != null,
            onTap: () async {
              final rows = await makers;

              if (!context.mounted) {
                return;
              }

              await _pick<Maker>(
                context,
                title: 'الماركة',
                options: rows,
                nameOf: (one) => one.name,
                current: maker,
                onPicked: onMaker,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Choose one of the shop's own rows, or clear the filter.
  ///
  /// The row is handed back rather than its name: the server filters on the
  /// key, and a name would have to be matched to a row somewhere — which is
  /// where two spellings start disagreeing.
  Future<void> _pick<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required String Function(T) nameOf,
    required String? current,
    required ValueChanged<T?> onPicked,
  }) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PickSheet(
        title: title,
        options: [for (final one in options) nameOf(one)],
        current: current,
      ),
    );

    /*
     * A sheet dismissed by swiping returns null, and so does "الكل". They mean
     * different things, so the sheet returns a sentinel for the second and the
     * difference survives the trip back.
     */
    if (picked == _PickSheet.any) {
      onPicked(null);

      return;
    }

    if (picked == null) {
      return;
    }

    for (final one in options) {
      if (nameOf(one) == picked) {
        onPicked(one);

        return;
      }
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.glyph,
    required this.on,
    required this.onTap,
  });

  final String label;
  final IconData glyph;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Material(
      color: on ? context.scheme.primary : context.scheme.surface,
      borderRadius: Corner.pill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          decoration: BoxDecoration(
            borderRadius: Corner.pill,
            border: Border.all(color: on ? Colors.transparent : colors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                glyph,
                size: 15,
                color: on ? context.scheme.onPrimary : colors.inkSoft,
              ),
              Gap.w4,
              Text(
                label,
                style: context.type.labelMedium?.copyWith(
                  color: on ? context.scheme.onPrimary : colors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountLine extends StatelessWidget {
  const _CountLine({
    required this.count,
    required this.filters,
    required this.onClear,
  });

  final int count;
  final int filters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xs),
      child: Row(
        children: [
          Text(
            '$count قطعة',
            style: context.type.labelMedium?.copyWith(
              color: context.palette.inkSoft,
            ),
          ),
          const Spacer(),
          if (filters > 0)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: Text('أزل التصفية ($filters)'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: context.palette.danger,
              ),
            ),
        ],
      ),
    );
  }
}

/// A one-of-many picker.
class _PickSheet extends StatelessWidget {
  const _PickSheet({
    required this.title,
    required this.options,
    required this.current,
  });

  static const any = '__any__';

  final String title;
  final List<String> options;
  final String? current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
            child: Row(
              children: [
                Text(title, style: context.type.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context, any),
                  child: const Text('الكل'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: Gap.lg),
              itemCount: options.length,
              itemBuilder: (context, at) {
                final one = options[at];
                final chosen = one == current;

                return ListTile(
                  title: Text(one),
                  trailing: chosen
                      ? Icon(Icons.check_rounded, color: context.scheme.primary)
                      : null,
                  onTap: () => Navigator.pop(context, one),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
