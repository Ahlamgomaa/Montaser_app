import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/dimens.dart';
import '../theme/palette.dart';

/// A labelled text field.
///
/// The label sits above the box rather than floating inside it. A floating
/// label in Arabic has to travel to the top-right corner and shrink, and at
/// small sizes Cairo's diacritics start colliding with the border — a static
/// label is simply easier to read, which is the only thing a label is for.
class AppField extends StatelessWidget {
  const AppField({
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.glyph,
    this.keyboard,
    this.formatters,
    this.obscure = false,
    this.optional = false,
    this.lines = 1,
    this.validator,
    this.onSubmitted,
    this.trailing,
    this.autofillHints,
    this.textInputAction,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final IconData? glyph;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final bool obscure;

  /// Marked in the label rather than the other way round.
  ///
  /// Most fields on these forms are required, so starring the required ones
  /// would star nearly everything. Naming the two that are not is quieter and
  /// says the same thing.
  final bool optional;

  final int lines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final type = context.type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 2, bottom: Gap.sm),
          child: Row(
            children: [
              Text(label, style: type.labelMedium),
              if (optional) ...[
                Gap.w8,
                Text(
                  'اختياري',
                  style: type.labelSmall?.copyWith(color: colors.inkFaint),
                ),
              ],
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          inputFormatters: formatters,
          maxLines: obscure ? 1 : lines,
          minLines: lines,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          style: type.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperStyle: type.labelSmall?.copyWith(color: colors.inkFaint),
            helperMaxLines: 2,
            prefixIcon: glyph == null
                ? null
                : Icon(glyph, size: 20, color: colors.inkFaint),
            suffixIcon: trailing,
            alignLabelWithHint: lines > 1,
          ),
        ),
      ],
    );
  }
}

/// The search box.
///
/// Read-only mode exists so the same box can sit on the home page and be a
/// button. Two boxes that look alike but behave differently is how a customer
/// ends up typing into something that does not take typing.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    this.controller,
    this.hint = 'ابحث باسم القطعة أو رقمها',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.onClear,
    super.key,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final hasText = controller?.text.isNotEmpty ?? false;

    return TextField(
      controller: controller,
      readOnly: readOnly,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      textInputAction: TextInputAction.search,
      style: context.type.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: Gap.md),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 22,
          color: colors.inkFaint,
        ),
        suffixIcon: hasText && onClear != null
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
                color: colors.inkFaint,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: Corner.pill,
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Corner.pill,
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Corner.pill,
          borderSide: BorderSide(color: context.scheme.primary, width: 1.6),
        ),
      ),
    );
  }
}
