import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import 'app_scope.dart';
import 'router.dart';

/// The application.
class MontaserApp extends StatelessWidget {
  const MontaserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      child: MaterialApp.router(
        title: 'منتصر',
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,

        theme: AppTheme.light,
        darkTheme: AppTheme.dark,

        /*
         * The phone decides. An app that forces its own brightness is one that
         * glares at somebody reading it in bed, and the dark theme here is
         * designed rather than derived, so there is nothing to protect.
         */
        themeMode: ThemeMode.system,

        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        /*
         * Right to left comes from the locale, not from a Directionality
         * wrapped round the tree. Doing it by hand works until a dialog or a
         * bottom sheet opens — those are built on the root navigator, outside
         * any wrapper, and they would come back left to right.
         */
        builder: (context, child) {
          final media = MediaQuery.of(context);

          /*
           * Type scaling is honoured but capped. A customer who has set their
           * phone to the largest text should get larger text here; at 2.0 the
           * price and the stock badge stop fitting on one line and the card
           * layout breaks, so the ceiling protects the design without ignoring
           * the setting.
           */
          return MediaQuery(
            data: media.copyWith(
              textScaler: media.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.3,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
