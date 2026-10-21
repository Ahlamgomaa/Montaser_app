import 'package:flutter/material.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/catalogue.dart';

/// The certification the shop trades under.
///
/// Given room rather than tucked into a footer. In this trade the question a
/// customer is actually asking is whether the part is genuine, and a
/// certification mark answers it before a word is read — which is exactly why
/// it is worth the space near the top of the shop front rather than at the
/// bottom of a page nobody scrolls to.
///
/// The picture comes from the settings page. Nothing here is drawn or bundled:
/// a certification can lapse, be renewed under a new mark, or be joined by a
/// second, and none of those should wait on an app store review.
class CertificateBadge extends StatelessWidget {
  const CertificateBadge({required this.identity, super.key});

  final ShopIdentity identity;

  /// The copy that ships with the app.
  static const _bundled = 'assets/brand/certificate.png';

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    /*
     * The shop's own upload wins; the bundled copy is what shows until there is
     * one, and if the settings page is ever cleared.
     *
     * Bundled at all because this is the shop's standing certification rather
     * than something that changes with a season — and a guarantee that appears
     * only after a settings page has been filled in is a guarantee absent on
     * the day the app is first opened, which is the day it matters most.
     */
    final uploaded = identity.certificateUrl;

    return Container(
      margin: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Corner.rLg,
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: Corner.rMd,
            child: uploaded == null || uploaded.isEmpty
                ? Image.asset(
                    _bundled,
                    fit: BoxFit.contain,
                    height: 84,
                    width: double.infinity,
                  )
                : Image.network(
                    uploaded,
                    fit: BoxFit.contain,
              /*
               * Wide and short, which is the shape these marks come in. Given a
               * fixed height so the page does not jump when it loads.
               */
                    height: 84,
                    width: double.infinity,
                    /*
                     * Back to the bundled copy rather than to a broken-picture
                     * icon: a torn image where a guarantee should be says the
                     * opposite of what this is here to say.
                     */
                    errorBuilder: (context, error, stack) =>
                        Image.asset(
                          _bundled,
                          fit: BoxFit.contain,
                          height: 84,
                          width: double.infinity,
                        ),
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const SizedBox(height: 84),
                  ),
          ),
          if ((identity.certificateNote ?? '').isNotEmpty) ...[
            Gap.h8,
            Text(
              identity.certificateNote!,
              textAlign: TextAlign.center,
              style: context.type.bodySmall?.copyWith(color: colors.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}
