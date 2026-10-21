import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/catalogue_repository.dart';
import '../../core/widgets/loader.dart';
import '../../app/app_scope.dart';

import '../../app/routes.dart';
import '../../core/theme/dimens.dart';
import '../../core/theme/glyphs.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/part_artwork.dart';
import '../../core/widgets/price_line.dart';
import '../../data/models/catalogue.dart';

/// Search, with the keyboard already open.
///
/// A separate screen from browsing rather than a mode of it. Somebody who taps
/// search wants to type immediately and see results as they go; somebody
/// browsing wants filters and a grid. Serving both from one screen means each
/// gets the other's compromises.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _field = TextEditingController();

  /// What the shop stocks, for the screen before anything is typed.
  late final Future<List<Aisle>> _aisles = AppScope.shop.catalogue.aisles();

  /// What people here actually look for. In a finished app these would be the
  /// shop's own most-searched terms; the point of showing any is that an empty
  /// search screen asks the customer to guess what the shop stocks.
  static const _common = <String>[
    'ضاغط',
    'R410A',
    'صمام تمدد',
    'ماسورة نحاس',
    'فلتر مجفف',
    'بريشر سويتش',
  ];

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  /// What the shop found, or null before anything has been typed.
  ///
  /// Asked of the server rather than matched here. A search that only looks at
  /// whatever the app happens to have loaded searches a fraction of the
  /// catalogue and tells the customer the part is not stocked — while it sits
  /// on a shelf.
  Future<PartPage>? _hits;

  /// Ask again for whatever is in the box.
  void _look() {
    final term = _field.text.trim();

    setState(() {
      _hits = term.isEmpty
          ? null
          : AppScope.shop.catalogue.search(PartQuery(text: term));
    });
  }
  @override
  Widget build(BuildContext context) {
    final term = _field.text.trim();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsetsDirectional.only(end: Gap.lg),
          child: AppSearchField(
            controller: _field,
            autofocus: true,
            onChanged: (_) => _look(),
            onClear: () {
              _field.clear();
              _look();
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                context.pushReplacement(Path.toBrowse(query: value.trim()));
              }
            },
          ),
        ),
      ),
      body: term.isEmpty
          ? _Suggestions(
              terms: _common,
              aisles: _aisles,
              onPick: (one) {
                _field.text = one;
                _look();
              },
            )
          : Loader<PartPage>(
              future: _hits,
              onRetry: _look,
              isEmpty: (page) => page.parts.isEmpty,
              empty: _NoHits(term: term),
              builder: (context, page) => ListView.separated(
                padding: const EdgeInsets.only(bottom: Metric.bottomRest),
                itemCount: page.parts.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 88),
                itemBuilder: (context, at) =>
                    _Hit(part: page.parts[at], term: term),
              ),
            ),
    );
  }
}

/// One result.
///
/// The part number is shown under the name because it is what half the searches
/// were: somebody typing `ZR24K` wants to see `ZR24K3E-TFD-522` and be sure
/// before they tap.
class _Hit extends StatelessWidget {
  const _Hit({required this.part, required this.term});

  final Part part;
  final String term;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Gap.lg,
        vertical: Gap.sm,
      ),
      leading: PartArtwork(
        seed: part.id,
        imageUrl: part.imageUrl,
        glyph: Glyphs.aisleNamed(part.aisle),
        size: 56,
        radius: Corner.rMd,
        dense: true,
      ),
      title: Text(
        part.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.type.titleSmall?.copyWith(height: 1.45),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${part.brand} · ${part.code}',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
              style: context.type.labelSmall?.copyWith(color: colors.inkFaint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            PriceLine(
              price: part.price,
              unit: part.unit,
              wasPrice: part.wasPrice,
            ),
          ],
        ),
      ),
      onTap: () => context.push(Path.toPart(part.slug)),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.terms,
    required this.aisles,
    required this.onPick,
  });

  final List<String> terms;

  /// The shop's own aisles, so an empty search screen still says what is here.
  final Future<List<Aisle>> aisles;

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Gap.lg),
      children: [
        Text('الأكثر بحثاً', style: context.type.titleSmall),
        Gap.h12,
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            for (final one in terms)
              ActionChip(
                label: Text(one),
                onPressed: () => onPick(one),
                avatar: Icon(
                  Icons.north_east_rounded,
                  size: 14,
                  color: context.palette.inkFaint,
                ),
              ),
          ],
        ),
        Gap.h32,
        Text('تصفّح حسب القسم', style: context.type.titleSmall),
        Gap.h12,

        /*
         * Nothing while the aisles are still coming, rather than a spinner: the
         * suggestions above are already on the screen and worth reading, and a
         * loader under them would make a screen that is doing its job look
         * like one that is stuck.
         */
        FutureBuilder<List<Aisle>>(
          future: aisles,
          builder: (context, snapshot) => Column(
            children: [
              for (final aisle in snapshot.data ?? const <Aisle>[])
                _AisleRow(aisle: aisle),
            ],
          ),
        ),
      ],
    );
  }
}

/// One aisle on the screen before anything has been typed.
class _AisleRow extends StatelessWidget {
  const _AisleRow({required this.aisle});

  final Aisle aisle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Glyphs.aisle(aisle.slug),
              color: context.scheme.primary,
            ),
            title: Text(aisle.name, style: context.type.bodyMedium),
            trailing: Text(
              '${aisle.count}',
              style: context.type.labelSmall?.copyWith(
                color: context.palette.inkFaint,
              ),
            ),
            onTap: () => context.pushReplacement(
              Path.toBrowse(aisleId: aisle.id, title: aisle.name),
            ),
    );
  }
}

class _NoHits extends StatelessWidget {
  const _NoHits({required this.term});

  final String term;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Padding(
      padding: const EdgeInsets.all(Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Gap.h32,
          Icon(Icons.search_off_rounded, size: 44, color: colors.inkFaint),
          Gap.h16,
          Text(
            'لا نتائج لـ «$term»',
            style: context.type.titleMedium,
            textAlign: TextAlign.center,
          ),
          Gap.h8,
          Text(
            'جرّب رقم القطعة كما هو مكتوب عليها، أو ابحث باسم الماركة.',
            style: context.type.bodySmall?.copyWith(color: colors.inkFaint),
            textAlign: TextAlign.center,
          ),
          Gap.h24,
          OutlinedButton.icon(
            onPressed: () => context.pushReplacement(Path.browse),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text('تصفّح كل القطع'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(220, 48)),
          ),
        ],
      ),
    );
  }
}
