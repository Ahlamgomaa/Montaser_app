import 'package:flutter/material.dart';

import '../../data/models/catalogue.dart';
import '../theme/dimens.dart';
import '../theme/palette.dart';

/// Choosing a governorate.
///
/// From a list, never typed. Delivery is priced per governorate, so a
/// misspelling is not a cosmetic problem — it is an order the shop cannot quote
/// a shipping charge for. Free text here would also put four spellings of
/// الغربية into the customer table and make every report that groups by
/// governorate quietly wrong.
///
/// Shared by the address form and the registration form rather than written
/// twice. The two screens ask the same question, and the day a governorate is
/// added they should both learn about it at once.
class GovernoratePicker extends StatelessWidget {
  const GovernoratePicker({
    required this.value,
    required this.options,
    required this.onPicked,
    this.label = 'المحافظة',
    this.helper,
    this.errorText,
    super.key,
  });

  /// The chosen one, by id. Ids rather than names throughout: the order is
  /// keyed by one, and a name would have to be matched back somewhere.
  final int? value;

  /// Where the shop delivers, as the shop says. Passed in rather than fetched
  /// here, because both screens that show this already have the list — the
  /// address book sends it beside the addresses, and registration fetches it
  /// openly — and fetching it again would be a second call for the same rows.
  final List<Governorate> options;

  final ValueChanged<Governorate> onPicked;
  final String label;
  final String? helper;

  /// Shown under the box when the form was submitted without an answer. A
  /// picker cannot use [TextFormField]'s validation, so the error is passed in
  /// and drawn in the same place a field's would be.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;
    final wrong = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 2, bottom: Gap.sm),
          child: Text(label, style: type.labelMedium),
        ),
        Material(
          color: context.scheme.surface,
          borderRadius: Corner.rMd,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _open(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.lg,
                vertical: Gap.lg,
              ),
              decoration: BoxDecoration(
                borderRadius: Corner.rMd,
                border: Border.all(
                  color: wrong ? context.scheme.error : colors.line,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 20,
                    color: wrong ? context.scheme.error : colors.inkFaint,
                  ),
                  Gap.w12,
                  Expanded(
                    child: Text(
                      _chosenName ?? 'اختر المحافظة',
                      style: type.bodyMedium?.copyWith(
                        color: _chosenName == null ? colors.inkFaint : null,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: colors.inkFaint,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (wrong || helper != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.sm, right: Gap.md),
            child: Text(
              errorText ?? helper!,
              style: type.labelSmall?.copyWith(
                color: wrong ? context.scheme.error : colors.inkFaint,
              ),
            ),
          ),
      ],
    );
  }

  String? get _chosenName {
    for (final one in options) {
      if (one.id == value) {
        return one.name;
      }
    }

    return null;
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<Governorate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GovernorateSheet(current: value, options: options),
    );

    if (picked != null) {
      onPicked(picked);
    }
  }
}

/// The sheet, with a filter at the top.
///
/// Twenty-seven governorates is more than a thumb wants to scroll past, and
/// somebody who knows they live in أسوان should be able to type three letters
/// rather than travel the whole list to the bottom.
class _GovernorateSheet extends StatefulWidget {
  const _GovernorateSheet({required this.current, required this.options});

  final int? current;
  final List<Governorate> options;

  @override
  State<_GovernorateSheet> createState() => _GovernorateSheetState();
}

class _GovernorateSheetState extends State<_GovernorateSheet> {
  final _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final term = _filter.text.trim();
    final shown = term.isEmpty
        ? widget.options
        : widget.options
              .where((one) => one.name.contains(term))
              .toList(growable: false);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.md),
            child: Row(
              children: [
                Text('المحافظة', style: context.type.titleMedium),
                const Spacer(),
                Text(
                  '${shown.length} محافظة',
                  style: context.type.labelSmall?.copyWith(
                    color: context.palette.inkFaint,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.md),
            child: TextField(
              controller: _filter,
              onChanged: (_) => setState(() {}),
              style: context.type.bodyMedium,
              decoration: InputDecoration(
                hintText: 'اكتب أول حروف المحافظة',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: Gap.md),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: context.palette.inkFaint,
                ),
                border: const OutlineInputBorder(borderRadius: Corner.pill),
                enabledBorder: OutlineInputBorder(
                  borderRadius: Corner.pill,
                  borderSide: BorderSide(color: context.palette.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: Corner.pill,
                  borderSide: BorderSide(
                    color: context.scheme.primary,
                    width: 1.6,
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      'لا محافظة بهذا الاسم.',
                      style: context.type.bodySmall?.copyWith(
                        color: context.palette.inkFaint,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: controller,
                    itemCount: shown.length,
                    itemBuilder: (context, at) {
                      final one = shown[at];

                      return ListTile(
                        title: Text(one.name),
                        trailing: one.id == widget.current
                            ? Icon(
                                Icons.check_rounded,
                                color: context.scheme.primary,
                              )
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
