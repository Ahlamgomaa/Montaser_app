import 'package:flutter/material.dart';

import 'palette.dart';

/// Every icon and status colour the application uses, decided in one place.
///
/// Real `Icons.` constants rather than code points. `IconData(0xe8b1)` compiles
/// perfectly and draws a camera — nothing checks that a number is the icon you
/// meant — and Flutter's release build strips unused icons by tracking which
/// constants are referenced, so an icon built from a variable is invisible to
/// that pass.
///
/// Nothing here decides *what* a thing is. The shop names its own departments
/// and its own order statuses, and this file only says what each looks like,
/// falling back to something ordinary for a name it has not met. A department
/// added on the website therefore appears in the app the same day, with a plain
/// icon rather than none.
abstract final class Glyphs {
  /// The picture for a department, by its slug.
  static IconData aisle(String slug) {
    return switch (slug) {
      'compressors' => Icons.hvac_rounded,
      'coils' => Icons.ac_unit_rounded,
      'refrigerants' => Icons.propane_tank_outlined,
      'tubing' => Icons.line_axis_rounded,
      'controls' => Icons.tune_rounded,
      'fans' => Icons.mode_fan_off_rounded,
      'filters' => Icons.filter_alt_outlined,
      'tools' => Icons.handyman_outlined,
      _ => Icons.category_outlined,
    };
  }

  /// The picture for a part, from the department it belongs to.
  ///
  /// A part carries its department's name rather than its slug, so this matches
  /// on what the catalogue actually sends and gives anything unrecognised the
  /// plain box.
  static IconData aisleNamed(String name) {
    return switch (name) {
      'ضواغط' => Icons.hvac_rounded,
      'مكثفات ومبخرات' => Icons.ac_unit_rounded,
      'غازات تبريد' => Icons.propane_tank_outlined,
      'مواسير ووصلات' => Icons.line_axis_rounded,
      'تحكم وحساسات' => Icons.tune_rounded,
      'مراوح وموتورات' => Icons.mode_fan_off_rounded,
      'فلاتر ومجففات' => Icons.filter_alt_outlined,
      'عدد وأدوات' => Icons.handyman_outlined,
      _ => Icons.category_outlined,
    };
  }

  /// The picture for an order status, by the value the server sends.
  static IconData standing(String value, {bool wentWrong = false}) {
    if (wentWrong) {
      return switch (value) {
        'returned' => Icons.assignment_return_outlined,
        'failed' => Icons.error_outline_rounded,
        _ => Icons.cancel_outlined,
      };
    }

    return switch (value) {
      'pending' || 'placed' || 'new' => Icons.receipt_long_rounded,
      'confirmed' || 'processing' || 'packing' => Icons.inventory_2_rounded,
      'shipped' || 'out_for_delivery' => Icons.local_shipping_rounded,
      'delivered' || 'completed' => Icons.task_alt_rounded,
      _ => Icons.radio_button_unchecked_rounded,
    };
  }

  /// The picture for a way of paying, by the value the server sends.
  static IconData payment(String value) {
    return switch (value) {
      'cod' || 'cash' => Icons.payments_outlined,
      'card' || 'visa' || 'online' => Icons.credit_card_rounded,
      'wallet' || 'instapay' => Icons.account_balance_wallet_outlined,
      'transfer' || 'bank' => Icons.account_balance_outlined,
      _ => Icons.payment_rounded,
    };
  }
}

/// The shop's own word for how a status reads, turned into a colour.
///
/// The word comes from the server — `success`, `warning`, `danger` — because
/// which statuses are good news is the shop's judgement, not the app's. All the
/// app decides is what each of the three looks like.
extension StatusTone on BuildContext {
  (Color ink, Color bed) toneFor(String? tone) {
    final colors = palette;

    return switch (tone) {
      'success' => (colors.success, colors.successWash),
      'warning' || 'warn' => (colors.warn, colors.warnWash),
      'danger' || 'error' => (colors.danger, colors.dangerWash),
      'info' || 'primary' => (scheme.primary, scheme.primaryContainer),
      _ => (colors.inkSoft, colors.canvas),
    };
  }
}
