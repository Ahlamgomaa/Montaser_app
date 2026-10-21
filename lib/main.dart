import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/montaser_app.dart';
import 'data/repositories/repositories.dart';
import 'data/store/fingerprint_lock.dart';
import 'data/store/identity_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    /*
     * Arabic month and weekday names. Without this the first date the app
     * formats throws — and the first date it formats is on the orders screen,
     * which is exactly where a crash is least welcome.
     */
    initializeDateFormatting('ar'),

    /*
     * The server address and the saved token, both off disk. Read before the
     * first frame because the splash makes its first call immediately, and a
     * call made before the token is loaded is a call made signed out.
     */
    Repositories.wake(),
    /* The shop's own name, as it was last answered. See [ShopBadge]. */
    ShopBadge.instance.wake(),
    /* Whether this handset asks for a fingerprint first. */
    FingerprintLock.instance.wake(),
  ]);

  runApp(const MontaserApp());
}
