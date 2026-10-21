import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/api/api_failure.dart';
import '../../core/widgets/loader.dart';
import '../../app/routes.dart';
import '../../core/format/money.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/page_crown.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/empty_note.dart';
import '../../data/models/account.dart';
import '../../data/models/basket.dart';
import '../../data/store/session_store.dart';
import '../../data/store/basket_store.dart';
import '../basket/widgets/totals_card.dart';
import 'widgets/pay_choice.dart';
import 'widgets/place_choice.dart';
import 'widgets/shipping_choice_list.dart';
import 'widgets/step_rail.dart';

/// Turning a basket into an order.
///
/// Three decisions on one page rather than three pages. A customer at this
/// point has already decided to buy, and every screen between them and the
/// button is another chance to change their mind — but the decisions are still
/// staged, because the delivery options depend on the address and offering them
/// before one is chosen means quoting a price for a place nobody named.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Place? _place;
  String _note = '';
  String? _payWith;
  bool _placing = false;

  /// What the shop offers at this moment: the addresses, the delivery methods
  /// and the ways to pay. Asked for rather than assumed — a way to pay that the
  /// shop switched off must not still be on this screen.
  late Future<CheckoutView> _view;

  @override
  void initState() {
    super.initState();

    _view = AppScope.shop.checkout.view();

    /*
     * Opened on the default address rather than on nothing. Most orders go to
     * the same place, and asking every time is a question with a known answer.
     */
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final fallback = AppScope.session(context).defaultPlace;

      if (fallback != null) {
        _chooseAddress(fallback);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.basketOf(context);
    final session = AppScope.sessionOf(context);
    final basket = store.basket;

    if (basket.isEmpty) {
      return Scaffold(
        body: ListView(
          children: [
            const PageCrown(title: 'إتمام الطلب'),
            EmptyNote(
              glyph: Icons.shopping_bag_outlined,
              title: 'لا شيء لإتمامه',
              body: 'سلتك فارغة. أضف قطعاً ثم عد إلى هنا.',
              actionLabel: 'تصفّح القطع',
              onAction: () => context.go(Path.home),
            ),
          ],
        ),
      );
    }

    return Loader<CheckoutView>(
      future: _view,
      onRetry: () => setState(() {
        _view = AppScope.shop.checkout.view();
      }),
      builder: (context, view) => _body(context, store, session, basket, view),
    );
  }

  Widget _body(
    BuildContext context,
    BasketStore store,
    SessionStore session,
    Basket basket,
    CheckoutView view,
  ) {
    /*
     * Settled on the first method the shop actually offers, rather than on a
     * name written here. Cash on delivery is usually first in the shop's own
     * order, and following that order means the app never preselects something
     * head office has switched off.
     */
    final pay =
        _payWith ??
        view.paymentMethods
            .where((one) => one.available)
            .map((one) => one.value)
            .firstOrNull;

    final ready = _place != null && basket.shipping != null && pay != null;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: Metric.bottomRest),
        children: [
          const PageCrown(
            title: 'إتمام الطلب',
            lede: 'العنوان، ثم الشحن، ثم الدفع.',
          ),
          StepRail(
            atAddress: _place != null,
            atShipping: basket.shipping != null,
          ),

          PlaceChoice(
            places: session.places,
            chosen: _place,
            onChoose: _chooseAddress,
            onAdd: () => context.push(Path.toPlaceForm()),
          ),

          if (_place != null)
            ShippingChoiceList(
              choices: view.shippingOptions,
              chosen: basket.shipping,
              freeEarned: (store.shortOfFreeShipping ?? 1) <= 0,
              onChoose: (choice) => _chooseShipping(choice.id),
            )
          else
            const _Locked(
              glyph: Icons.local_shipping_outlined,
              title: 'طريقة التوصيل',
              body: 'اختر عنوان التوصيل أولاً لتظهر الطرق المتاحة وأسعارها.',
            ),

          PayChoice(
            methods: view.paymentMethods,
            chosen: pay,
            onChoose: (how) => setState(() => _payWith = how),
          ),

          _NoteBox(onChanged: (value) => _note = value),

          Gap.h16,
          Padding(
            padding: Metric.pagePad,
            child: TotalsCard(
              totals: basket.totals,
              coupon: basket.coupon?.code,
              shippingKnown: basket.shipping != null,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _PlaceBar(
        total: basket.totals.total,
        ready: ready && !_placing,
        onPlace: () => _submit(pay ?? ''),
      ),
    );
  }

  /// Tell the server which address the order is going to.
  ///
  /// Not a local choice, and getting this wrong is the kind of fault nobody
  /// sees until an order arrives: what delivery costs and how long it takes are
  /// decided by the governorate, so an address chosen only in the app leaves
  /// the customer looking at the charge for wherever they picked last time.
  ///
  /// The server answers with the options for the place actually named, and the
  /// screen redraws around them.
  Future<void> _chooseAddress(Place next) async {
    setState(() => _place = next);

    final messenger = ScaffoldMessenger.of(context);

    try {
      final view = await AppScope.shop.checkout.chooseAddress(next.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _view = Future<CheckoutView>.value(view);

        /*
         * A method chosen for the last address may not be offered for this
         * one — a courier that does not serve the governorate — so a choice
         * that is no longer on the list is dropped rather than carried.
         */
        if (!view.paymentMethods.any(
          (one) => one.value == _payWith && one.available,
        )) {
          _payWith = null;
        }
      });

      /* The charge changed with the address, so the basket has too. */
      await AppScope.basket(context).load(force: true);
    } on ApiFailure catch (fault) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(fault.message)));
    }
  }

  /// Tell the server which delivery method was chosen.
  ///
  /// It answers with a fresh basket, because choosing one changes the charge
  /// and may earn free delivery — the total has to come back from the place
  /// that worked it out.
  Future<void> _chooseShipping(int methodId) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await AppScope.basket(context).chooseShipping(methodId);
    } on ApiFailure catch (fault) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(fault.message)));
    }
  }

  /// Place the order.
  ///
  /// This used to invent a reference and empty the basket without telling
  /// anybody — the customer saw a confirmation for an order that did not exist,
  /// and the shop never heard about it. The order is now written by the server,
  /// and the screen that follows is opened on what it answered.
  Future<void> _submit(String payWith) async {
    if (_place == null || _placing) {
      return;
    }

    setState(() => _placing = true);

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final order = await AppScope.shop.checkout.place(
        placeId: _place!.id,
        paymentMethod: payWith,
        note: _note,
      );

      if (!mounted) {
        return;
      }

      /* The basket is the server's now: it emptied when the order was written. */
      AppScope.basket(context).forget();

      router.pushReplacement(
        '${Path.placed}?id=${order.id}&ref=${Uri.encodeComponent(order.reference)}',
      );
    } on ApiFailure catch (fault) {
      if (mounted) {
        setState(() => _placing = false);
      }

      /*
       * A timeout is the one refusal that is not a refusal: the order may have
       * been written and only the answer lost. Saying "try again" there invites
       * a second order, so the customer is sent to check first.
       */
      if (fault.kind == FailureKind.timeout) {
        _unsure(messenger);
      } else {
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(fault.message)));
      }
    } catch (error, stack) {
      /*
       * Anything that is not the server refusing — most likely an answer the
       * app could not read. The server may well have taken the order, so this
       * neither claims success nor invites a second order. It used to leave the
       * button disabled for good, with the basket still showing.
       */
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'checkout',
        ),
      );

      if (mounted) {
        setState(() => _placing = false);
      }

      _unsure(messenger);
    }
  }

  /// When nobody knows whether the order went through.
  ///
  /// The basket is read again — the server empties it when it writes an
  /// order — and the customer is told to look at their orders before trying
  /// again. No retry is made here: placing an order twice is worse than asking.
  void _unsure(ScaffoldMessengerState messenger) {
    if (mounted) {
      AppScope.basket(context).load(force: true).catchError((Object _) {});
    }

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'لم نتأكد من تسجيل طلبك. راجع «طلباتي» قبل المحاولة مرة أخرى.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
  }
}

/// A section that cannot be used yet, drawn rather than hidden.
///
/// Hiding it would make the page jump when an address is chosen and leave a
/// customer wondering where the delivery options went. Showing it greyed says
/// what is coming and why it is not ready.
class _Locked extends StatelessWidget {
  const _Locked({required this.glyph, required this.title, required this.body});

  final IconData glyph;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Container(
      margin: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.sm),
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: colors.canvas,
        borderRadius: Corner.rLg,
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Icon(glyph, size: 22, color: colors.inkFaint),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.type.titleSmall?.copyWith(
                    color: colors.inkFaint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: context.type.bodySmall?.copyWith(
                    color: colors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ملاحظة للمندوب', style: context.type.titleSmall),
          Gap.h8,
          TextField(
            onChanged: onChanged,
            maxLines: 3,
            minLines: 2,
            style: context.type.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'مثلاً: اتصل قبل الوصول بنصف ساعة.',
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceBar extends StatelessWidget {
  const _PlaceBar({
    required this.total,
    required this.ready,
    required this.onPlace,
  });

  final double total;
  final bool ready;
  final VoidCallback onPlace;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.md),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!ready)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: colors.warn,
                    ),
                    Gap.w8,
                    Expanded(
                      child: Text(
                        'اختر عنوان التوصيل وطريقة الشحن أولاً.',
                        style: context.type.labelSmall?.copyWith(
                          color: colors.warn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الإجمالي',
                      style: context.type.labelSmall?.copyWith(
                        color: colors.inkFaint,
                      ),
                    ),
                    Text(
                      Money.of(total),
                      style: context.type.titleLarge?.copyWith(
                        color: colors.price,
                      ),
                    ),
                  ],
                ),
                Gap.w16,
                Expanded(
                  child: FilledButton(
                    onPressed: ready ? onPlace : null,
                    child: const Text('إصدار الطلب'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
