# Montaser — مؤسسة منتصر

The mobile shop for **Montaser Foundation**, a supplier of air-conditioning,
refrigeration and washing-machine spare parts. Customers browse the catalogue,
keep parts in a wish list, fill a basket and place orders, all in Arabic and
right to left.

> تطبيق متجر مؤسسة منتصر لقطع غيار التكييف والتبريد والغسالات: تصفّح القطع،
> المفضلة، السلة، إتمام الطلب ومتابعته — بالعربية ومن اليمين لليسار.

The app is a client only. Prices, totals, stock, delivery charges and order
status all come from the shop's Laravel API (`https://montasereg.com/api/v1`);
the app never works them out itself, so it cannot disagree with the invoice.

---

## Features

| Area | What it does |
|---|---|
| **Shop front** | Banner, certification badge, categories and brands strips, featured / best-selling / new arrivals shelves |
| **Catalogue** | Categories, brands, browse with filters and sorting, search by part name or number |
| **Part page** | Gallery, specs, stock, reviews, write a review, add to basket |
| **Basket** | Quantities, coupon, delivery choice, totals from the server, pull-to-refresh |
| **Checkout** | Address, shipping method, payment method, note to the courier, order confirmation |
| **Orders** | Order list and detail with status timeline |
| **Account** | Sign in / register by phone, profile, password, address book, wish list, sign out (this phone or everywhere) |
| **Fingerprint lock** | Optional local lock: while closed, no request carries the sign-in token |
| **Theme** | Designed light and dark themes that follow the phone; Cairo font bundled |

---

## Tech stack

- **Flutter** (developed on 3.47, Dart SDK `^3.11.4`)
- **State**: `ChangeNotifier` stores (`SessionStore`, `BasketStore`) exposed through `InheritedNotifier` (`AppScope`) — no state-management package
- **Routing**: `go_router` with a five-tab `StatefulShellRoute`, plus an auth guard for account screens
- **Networking**: `http`, one `ApiClient` that unwraps the API envelope `{success, message, data, meta, errors}` into data or a typed `ApiFailure`
- **Storage**: `flutter_secure_storage` for the sign-in token; `shared_preferences` for small non-secret settings
- **Biometrics**: `local_auth`
- **Localization**: Arabic (`intl`, `flutter_localizations`)
- **Tooling**: `flutter_lints`, `flutter_launcher_icons`, `flutter_native_splash`

---

## Project structure

```
lib/
├── main.dart              start-up: date symbols, saved settings, token, then runApp
├── app/                   MontaserApp, AppScope (stores), router + routes, tab shell
├── core/
│   ├── format/            money and date formatting
│   ├── theme/             palette, theme, spacing, icons
│   └── widgets/           shared widgets (Loader, EmptyNote, PageCrown, AppField, …)
├── data/
│   ├── api/               ApiClient, ApiConfig, ApiFailure, endpoints, TokenStore
│   ├── models/            catalogue, basket, order, account
│   ├── repositories/      auth, catalogue, basket, checkout / orders / account
│   └── store/             SessionStore, BasketStore, ShopBadge, FingerprintLock
└── features/              account, auth, basket, catalogue, checkout,
                           home, orders, product, splash
assets/
├── brand/                 icon.png, splash.png, splash_dark.png (+ Android 12 copies), certificate.png
└── fonts/                 Cairo Regular / Bold
test/                      widget and unit tests
```

Every network call goes through `lib/data/api/api_client.dart`, and every path
the app calls is listed in `lib/data/api/endpoints.dart`.

---

## Getting started

### Requirements

- Flutter SDK (stable) with Dart `^3.11.4`
- Android Studio / Android SDK for Android, Xcode on macOS for iOS

### Install and run

```bash
flutter pub get
```

```bash
flutter run
```

### Choosing the server

The API address is picked in this order (`lib/data/api/api_config.dart`):

1. `--dart-define=API_BASE_URL=...` — any server, for example staging:

   ```bash
   flutter run --dart-define=API_BASE_URL=https://staging.example/api/v1
   ```

2. `--dart-define=LOCAL_API=true` — debug builds only: the Laravel server on
   your computer, as an Android emulator sees it (`http://10.0.2.2:8000/api/v1`):

   ```bash
   flutter run --dart-define=LOCAL_API=true
   ```

3. Otherwise, the live shop: `https://montasereg.com/api/v1`.

> ⚠️ With no options, **debug builds talk to the live shop too**. Accounts,
> addresses and orders created while testing are real.

On a physical phone, `10.0.2.2` does not reach your computer — use
`API_BASE_URL` with your computer's LAN address instead.

---

## Tests and checks

```bash
flutter analyze
```

```bash
flutter test
```

Tests run with stand-ins for the HTTP client, `SharedPreferences` and secure
storage; they never call the real API. `test/critical_fixes_test.dart` covers
token storage, the fingerprint lock, the route guard, splash recovery and the
review sheet.

---

## App icon and splash screen

Both are generated from the pictures in `assets/brand/`; their settings live at
the end of `pubspec.yaml`.

| File | Used for |
|---|---|
| `icon.png` | App icon (square, at least 1024 × 1024) |
| `splash.png` | Splash logo, light theme (transparent background) |
| `splash_dark.png` | Splash logo, dark theme (same logo, lettering in orange) |
| `splash_android12.png`, `splash_android12_dark.png` | Android 12+ splash: the logo inside the 768 px circle Android shows on a 1152 px canvas |

After changing any of them, regenerate:

```bash
dart run flutter_launcher_icons
```

```bash
dart run flutter_native_splash:create
```

The in-app splash (`lib/features/splash/splash_page.dart`) shows the same logo
on the theme's page colour, so the system splash hands over to it seamlessly.

---

## Release builds

### Android signing

Release builds are signed with the upload key described in
`android/key.properties`:

```properties
storeFile=../../upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

- `storeFile` is relative to `android/app/` (so `../../` is the project root),
  or an absolute path.
- `key.properties`, `*.jks` and `*.keystore` are git-ignored — **never commit
  them**, and keep an offline backup of the keystore and its passwords. Losing
  the upload key means you cannot publish updates without Google's help.
- Without `key.properties` a release build still succeeds but is signed with the
  **debug** key, which no store accepts.

Build and check the signer:

```bash
flutter build appbundle --release
```

```bash
flutter build apk --release
```

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

The certificate shown must match `keytool -list -v -keystore upload-keystore.jks -alias upload`.

### Before publishing

- Application ID is still `com.montaser.montaser_app` (iOS
  `com.montaser.montaserApp`). It cannot change after the first upload, so
  confirm it first.
- Version is set in `pubspec.yaml` (`version: 1.0.0+1`).
- iOS signing (team, provisioning) is configured in Xcode.

---

## Known limitations

- **Password reset** — the API has no reset endpoint yet; the app tells the
  customer to contact the shop.
- **Catalogue and orders paging** — only the first page (20 parts) is shown.
- **Notifications, "notify me", share, contact about an order** — placeholders
  with no backend behind them yet.
- **Crash reporting** — none configured.

Full audit notes are in `FLUTTER_AUDIT_REPORT.md`.
