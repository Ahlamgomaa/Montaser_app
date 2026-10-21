import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/api/api_failure.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/page_crown.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/governorate_picker.dart';
import '../../data/models/account.dart';

/// Adding or editing an address.
///
/// One screen for both. The only difference between them is what the fields
/// start with and what the button says, and two screens that differ by that
/// much are one screen that has been copied.
class PlaceFormPage extends StatefulWidget {
  const PlaceFormPage({this.id, super.key});

  final int? id;

  @override
  State<PlaceFormPage> createState() => _PlaceFormPageState();
}

class _PlaceFormPageState extends State<PlaceFormPage> {
  final _form = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _recipient = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _street = TextEditingController();
  final _building = TextEditingController();
  final _flat = TextEditingController();
  final _landmark = TextEditingController();

  int? _governorateId;
  String? _governorate;
  bool _isDefault = false;
  bool _submitted = false;
  Place? _editing;

  @override
  void initState() {
    super.initState();

    if (widget.id == null) {
      return;
    }

    for (final place in AppScope.session(context).places) {
      if (place.id != widget.id) {
        continue;
      }

      _editing = place;
      _label.text = place.label;
      _recipient.text = place.recipient;
      _phone.text = place.phone;
      _city.text = place.city;
      _street.text = place.street;
      _building.text = place.building ?? '';
      _flat.text = place.flat ?? '';
      _landmark.text = place.landmark ?? '';
      _governorateId = place.governorateId;
      _governorate = place.governorate;
      _isDefault = place.isDefault;
      break;
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _recipient.dispose();
    _phone.dispose();
    _city.dispose();
    _street.dispose();
    _building.dispose();
    _flat.dispose();
    _landmark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = _editing != null;

    return Scaffold(
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.only(bottom: Metric.bottomRest),
          children: [
            PageCrown(
              title: editing ? 'تعديل العنوان' : 'عنوان جديد',
              lede: 'كلما كان العنوان أدق، وصل الطلب أسرع.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppField(
                    label: 'اسم العنوان',
                    controller: _label,
                    glyph: Icons.bookmark_outline_rounded,
                    hint: 'الورشة، البيت، المخزن',
                    helper: 'اسم تعرفه أنت، يظهر لك عند اختيار العنوان.',
                    validator: _required,
                  ),
                  Gap.h16,
                  AppField(
                    label: 'اسم المستلم',
                    hint: 'الاسم كما سيسأل عنه المندوب',
                    controller: _recipient,
                    glyph: Icons.person_outline_rounded,
                    validator: _required,
                  ),
                  Gap.h16,
                  AppField(
                    label: 'رقم هاتف المستلم',
                    hint: '01xxxxxxxxx',
                    controller: _phone,
                    glyph: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                    helper: 'يتصل به المندوب عند الوصول.',
                    validator: (value) {
                      final text = (value ?? '').trim();

                      if (text.isEmpty) {
                        return 'اكتب رقم الهاتف.';
                      }

                      return text.length == 11
                          ? null
                          : 'الرقم يجب أن يكون ١١ رقماً.';
                    },
                  ),
                  Gap.h16,
                  GovernoratePicker(
                    /* The list the address book came with — see the picker. */
                    options: AppScope.sessionOf(context).governorates,
                    value: _governorateId,
                    errorText: _submitted && _governorateId == null
                        ? 'اختر المحافظة.'
                        : null,
                    onPicked: (next) => setState(() {
                      _governorateId = next.id;
                      _governorate = next.name;
                    }),
                  ),
                  Gap.h16,
                  AppField(
                    label: 'المدينة أو المركز',
                    hint: 'مثلاً: مدينة نصر',
                    controller: _city,
                    glyph: Icons.location_city_outlined,
                    validator: _required,
                  ),
                  Gap.h16,
                  AppField(
                    label: 'الشارع',
                    hint: 'اسم الشارع ورقمه إن وُجد',
                    controller: _street,
                    glyph: Icons.signpost_outlined,
                    validator: _required,
                  ),
                  Gap.h16,
                  Row(
                    children: [
                      Expanded(
                        child: AppField(
                          label: 'رقم العمارة',
                          hint: 'مثلاً: 12',
                          controller: _building,
                          optional: true,
                        ),
                      ),
                      Gap.w12,
                      Expanded(
                        child: AppField(
                          label: 'رقم الشقة',
                          hint: 'مثلاً: 4',
                          controller: _flat,
                          optional: true,
                        ),
                      ),
                    ],
                  ),
                  Gap.h16,
                  AppField(
                    label: 'علامة مميزة',
                    controller: _landmark,
                    optional: true,
                    glyph: Icons.place_outlined,
                    hint: 'أمام محطة السكة الحديد',
                    /*
               * Marked optional but asked for prominently. In much of Egypt
               * the landmark is what actually gets the driver there, and an
               * order without one is an order that ends in a phone call.
               */
                    helper:
                        'أهم من رقم العمارة أحياناً — تساعد المندوب على الوصول.',
                  ),
                  Gap.h24,
                  _DefaultSwitch(
                    on: _isDefault,
                    onChanged: (next) => setState(() => _isDefault = next),
                  ),
                  Gap.h32,
                  FilledButton(
                    onPressed: _save,
                    child: Text(editing ? 'حفظ التعديلات' : 'حفظ العنوان'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'هذا الحقل مطلوب.' : null;

  Future<void> _save() async {
    setState(() => _submitted = true);

    final fieldsPass = _form.currentState?.validate() ?? false;

    if (!fieldsPass || _governorateId == null) {
      return;
    }

    final session = AppScope.session(context);

    final place = Place(
      /*
       * Zero for a new one. The server mints the id — an address invented with
       * a number chosen here would be an address the shop cannot find again.
       */
      id: _editing?.id ?? 0,
      label: _label.text.trim(),
      recipient: _recipient.text.trim(),
      phone: _phone.text.trim(),
      governorate: _governorate ?? '',
      governorateId: _governorateId!,
      city: _city.text.trim(),
      street: _street.text.trim(),
      building: _building.text.trim().isEmpty ? null : _building.text.trim(),
      flat: _flat.text.trim().isEmpty ? null : _flat.text.trim(),
      landmark: _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
      isDefault: _isDefault,
    );

    try {
      if (_editing == null) {
        await session.addPlace(place);
      } else {
        await session.updatePlace(place);
      }
    } on ApiFailure catch (fault) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(fault.message)));
      }

      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _editing == null ? 'تمت إضافة العنوان.' : 'تم حفظ العنوان.',
          ),
        ),
      );

    context.pop();
  }
}

class _DefaultSwitch extends StatelessWidget {
  const _DefaultSwitch({required this.on, required this.onChanged});

  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.sm),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Corner.rMd,
        border: Border.all(color: colors.line),
      ),
      child: SwitchListTile(
        value: on,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        title: Text('اجعله العنوان الأساسي', style: context.type.bodyMedium),
        subtitle: Text(
          'يُختار تلقائياً عند إتمام الطلب.',
          style: context.type.labelSmall?.copyWith(color: colors.inkFaint),
        ),
      ),
    );
  }
}
