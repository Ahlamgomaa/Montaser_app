# Flutter Audit Report: montaser_app

| | |
|---|---|
| **Project** | `montaser_app` (Arabic RTL storefront for an auto-parts shop, backed by a Laravel API) |
| **Path** | `F:\Work\vexxai_flutter\montaser-app\montaser-app` |
| **Audit date** | 2026-10-20 |
| **Toolchain** | Flutter 3.47.6 (stable), Dart 3.13.5 |
| **Size** | 84 Dart files in `lib/` (≈16.4k lines), 2 test files |
| **Mode** | Read-only. No application files were changed and no production service was contacted. |

> **Note on the audit brief.** `FLUTTER_AUDIT_PROMPT.md` was **not found**. I searched the project root, its parent folders and the user profile. This report therefore follows the scope given in the request: source, structure, architecture, validation, state management, API integration, error handling, security, performance, dependencies, platform configuration and tests. It also includes exact paths and line numbers, severity, confidence, impact, fixes, and a separation of confirmed defects, potential risks and items that need external verification. If the prompt file turns up, this report can be re-cut to its section list.

---

## 1. Executive summary

The codebase is **well organised and unusually well documented**. It has:
- a clean `app / core / data / features` split;
- one API client with a typed failure model;
- server-authoritative pricing;
- careful `mounted` handling in most screens;
- a clean analyzer run (1 info) and passing tests.

The weaknesses are concentrated in four areas:

1. **Session and privacy boundaries.**
   - Signing out leaves the previous user's basket and wishlist on screen.
   - The fingerprint lock hides profile data but leaves the token fully usable. A person holding the phone can still view the wishlist, add addresses and place orders on the owner's account.
   - There are no route guards.
2. **Incomplete features that report success.**
   - Catalogue and orders show only page 1 (20 items).
   - The "write a review" button can never open.
   - "Forgot password", "copy order number", "share", "notify me" and "contact about order" all show a success message without doing anything.
3. **Error handling that only expects `ApiFailure`.**
   - Any other exception (for example a `TypeError` from a model cast) leaves the splash stuck forever, or leaves sign-in, checkout and review buttons spinning forever.
   - The model helpers silently turn numeric strings into `0`. Laravel commonly sends decimals as strings, so this **must be verified against the real API** before release.
4. **Release readiness.**
   - The Android release build is signed with the debug key.
   - iOS has no `NSFaceIDUsageDescription` although biometrics are used.
   - The auth token is stored in plain `SharedPreferences` and is included in Android backups.
   - There is no crash reporting.

### Scorecard

| Area | Rating | Notes |
|---|---|---|
| Architecture & structure | **Good** | Clear layering; singletons plus `InheritedNotifier`; no DI container needed at this size |
| Code quality / static analysis | **Good** | `flutter analyze`: 1 info (deprecation) |
| State management | **Weak** | Per-user state not cleared on sign-out or lock; partial-success states |
| API integration | **Fair** | Good envelope handling; parsing fragile to type drift; no pagination in the UI |
| Error handling | **Weak** | `on ApiFailure`-only catches; several unawaited calls that can throw |
| Validation | **Fair** | Basic validators present; rules inconsistent with each other; no max lengths |
| Security | **Weak** | Plain-text token, backup enabled, lock bypass, no route guards, debug-signed release |
| Performance | **Fair** | Lazy lists are good; un-debounced search, full-size image decode, spinner-swap reloads |
| Accessibility / RTL | **Fair** | Locale-driven RTL is good; mirrored icons point the wrong way; contrast fails AA; unlabelled icon buttons |
| Tests | **Weak** | 5 widget tests; no unit tests for models, stores, repositories or the API client |
| Release readiness | **Not ready** | See P0 list in §15 |

### Findings count

Approximate counts; borderline Low/Medium items are counted once.

| Severity | Confirmed defects | Potential risks / needs external verification |
|---|---|---|
| Critical | 0 | 1 (numeric-string parsing, S-01) |
| High | 13 | 3 (PLAT-02, S-02, S-03) |
| Medium | ≈29 | 5 |
| Low / Info | ≈25 | 6 |

---

## 2. Method and evidence

1. Read the whole data layer (`lib/data/**`), the app bootstrap (`lib/main.dart`, `lib/app/**`), the splash screen, and the Android, iOS and web configuration line by line.
2. Two read-only review passes covered every remaining file in `lib/features/**`, `lib/core/**` and `lib/data/models/**` in full.
3. I re-checked the key findings from those passes against the source myself: verdict_list, sign-out, wishlist, checkout catch, fake actions, `asInt`/`asDouble`, `order.dart` casts, missing pagination, and the icon mirroring flags in the Flutter SDK `icons.dart`.
4. I ran safe local commands (§3). They made no network calls to production. Widget tests run under `TestWidgetsFlutterBinding`, which stubs HTTP, and in debug the base URL resolves to `http://10.0.2.2:8000`, not production.

**Labels used**
- **Confirmed defect**: the code demonstrably behaves wrongly.
- **Potential risk**: a plausible failure that depends on conditions or timing.
- **Needs external verification (EXT)**: depends on server payloads or behaviour, store review, or device runtime.
- **Confidence**: Confirmed / Likely / Possible.

---

## 3. Commands run

| Command | Result |
|---|---|
| `flutter --version` | Flutter 3.47.6, Dart 3.13.5 |
| `flutter analyze --no-pub` | **1 issue (info):** `'cacheExtent' is deprecated … Use scrollCacheExtent` at `lib/features/catalogue/widgets/part_shelf.dart:34`. Exit code 1 only because an issue exists. |
| `flutter test --no-pub` | **5/5 passed** (`dialog_test.dart` ×1, `widget_test.dart` ×4) |
| `flutter pub outdated` | `go_router` 17.5.0 → 18.1.0 (major); `cupertino_icons` 1.0.9 → 2.0.0 (major); `shared_preferences` 2.5.5 → 2.5.6; 14 transitive packages locked to older versions, including `local_auth_android` 2.0.10 → 2.3.0 |

`pubspec.lock` was not modified (timestamp unchanged, 2025-09-02).

**Not run:**
- `flutter build` for release: it needs signing material and writes build output.
- Integration or device tests: no devices, and there is no test backend.
- A dependency vulnerability scan: Dart has no offline advisory database. `pub outdated` was used instead.

---

## 4. Project structure and architecture

```
lib/
  main.dart                     bootstrap: date symbols, prefs, token, badge, fingerprint
  app/                          MontaserApp, AppScope (InheritedNotifiers), router, routes, shell
  core/                         theme (palette, dimens, glyphs), format (money, dates), shared widgets
  data/
    api/                        ApiClient, ApiConfig, ApiFailure, endpoints, TokenStore
    models/                     account, basket, catalogue, order (hand-written fromJson)
    repositories/               auth, basket, catalogue, shop (checkout/orders/account), holder
    store/                      SessionStore, BasketStore, ShopBadge, FingerprintLock
  features/                     account, auth, basket, catalogue, checkout, home, orders, product, splash
test/                           widget_test.dart, dialog_test.dart
android/ ios/ web/ windows/
```

**Assessment**

- The layering is sound: Widgets → `AppScope` stores and repositories → `ApiClient` → HTTP. Only `ApiClient` knows the envelope format (`lib/data/api/api_client.dart:1-22`).
- **AR-01 (Low, Confirmed)**: global singletons `ApiConfig.instance`, `TokenStore.instance`, `ShopBadge.instance`, `FingerprintLock.instance` and `Repositories.instance` are reached directly from widgets. Examples: `lib/features/account/account_page.dart:402`; `lib/data/repositories/catalogue_repository.dart:95`, where a repository writes into the UI-facing `ShopBadge`.
  - **Impact:** hard to unit-test; hidden coupling.
  - **Fix:** inject through `AppScope`, or keep the singletons but expose test seams like `Repositories.useForTesting`.
- **AR-02 (Low, Confirmed)**: Screens hold their own `Future` and swap it in `setState`. Every refresh tears the page down to a spinner, and paging or caching logic is duplicated per page (`browse_page.dart`, `search_page.dart`, `orders_page.dart`, `wishlist_page.dart`).
  - **Fix:** introduce small per-feature controllers (`ChangeNotifier`) that keep the last data while loading, or adopt a state library.
- **AR-03 (Info)**: The repository is **not under version control** (no `.git`). The README and `pubspec.yaml` `description` are still Flutter template text (`README.md:1-16`, `pubspec.yaml:2`).
- **AR-04 (Info)**: `windows/` and `web/` targets exist. Biometrics are unsupported on web, and on web the token would sit in `localStorage` (XSS-exposed). `web/index.html` still carries template title and description (`web/index.html:18,29`).

---

## 5. Findings index

| ID | Sev. | Status | Title | Location |
|---|---|---|---|---|
| SEC-01 | High | Confirmed | Fingerprint lock does not lock the token or any API | `lib/data/store/session_store.dart:82-92`, `lib/features/splash/splash_page.dart:106-115` |
| ST-01 | High | Confirmed | Sign-out leaves the previous user's basket visible | `lib/features/account/account_page.dart:208-212`, `lib/features/account/profile_page.dart:221-227` |
| ST-02 | High | Confirmed | Wishlist tab keeps the previous user's data across sign-out/in | `lib/features/account/wishlist_page.dart:34-38` |
| NAV-01 | High | Confirmed | No route guards / `redirect` / `errorBuilder` | `lib/app/router.dart:50-219` |
| ERR-01 | High | Confirmed | Splash hangs forever on a non-`ApiFailure` error | `lib/features/splash/splash_page.dart:70-83`, `lib/data/store/session_store.dart:110-133` |
| ERR-02 | High | Confirmed | Place-order catches only `ApiFailure`: stuck button, basket not cleared, re-order risk | `lib/features/checkout/checkout_page.dart:264-289` |
| FN-01 | High | Confirmed | "Write a review" button can never open the sheet | `lib/features/product/widgets/verdict_list.dart:48,64-70` |
| FN-02 | High | Confirmed | Browse and search show only the first 20 parts | `lib/features/catalogue/browse_page.dart:106-117,205-213`, `search_page.dart:68,110-117` |
| PERF-01 | High | Confirmed | Search fires a request per keystroke and resets the result view | `browse_page.dart:161`, `search_page.dart:83` |
| PLAT-01 | High | Confirmed | Android release signed with the debug key | `android/app/build.gradle.kts:34-38` |
| PLAT-02 | High | Likely | iOS `NSFaceIDUsageDescription` missing while `local_auth` is used | `ios/Runner/Info.plist` (absent) |
| SEC-02 | High | Confirmed | Bearer token stored in plain `SharedPreferences` | `lib/data/api/token_store.dart:6-62` |
| FN-03 | High | Confirmed | "Forgot password" reports a reset link was sent but does nothing | `lib/features/auth/sign_in_page.dart:135-139` |
| S-01 | Critical* | EXT | Numeric strings (Laravel decimals) parse to `0` | `lib/data/models/catalogue.dart:8-15` |
| S-02 | High* | EXT | Hard `as String?` / `as Map?` casts throw on type drift | models, see §8 |
| S-03 | High* | EXT/Potential | No idempotency on order placement | `lib/data/repositories/shop_repository.dart:36-51` |
| … | | | Medium and Low findings are listed per section below | |

\* Severity applies if the server behaves as described; it needs external verification.

---

## 6. Security

| ID | Sev. | Conf. | Status | Finding | Impact | Fix |
|---|---|---|---|---|---|---|
| **SEC-01** | High | Confirmed (client) | Confirmed defect | `lockAway()` only nulls `_shopper`, `_book` and `_kept`; its own comment says "The token is untouched" (`session_store.dart:82-92`). After a failed fingerprint (`splash_page.dart:110-115`) every API call still sends the bearer token. With no route guards (NAV-01) the following all still work: Wishlist tab (`wishlist_page.dart:34`); checkout (`router.dart:193-197`) → add address → `session.addPlace` → `loadPlaces()` refills the owner's address book (`session_store.dart:221-224`) → `_submit` places an order (`checkout_page.dart:254-280`); orders by deep link (`orders_page.dart:35`, `order_page.dart:31`). | Anyone holding an unlocked phone can view and act on the owner's account despite the lock. | Hold the token in memory only after the fingerprint is proved, or add a `locked` flag that makes `ApiClient._headers` omit `Authorization`. Add route guards. Re-lock on `AppLifecycleState.resumed` after a timeout. |
| **SEC-02** | High | Confirmed | Confirmed defect | The token is persisted with `SharedPreferences.setString('auth.token', …)` (`token_store.dart:49-54`). That is plain XML on Android, `NSUserDefaults` on iOS, and `localStorage` on web. | The token can be read from backups, rooted or jailbroken devices, and web XSS. | Use `flutter_secure_storage` (Keystore/Keychain). Migrate the existing value once on upgrade. |
| **SEC-03** | Medium | Confirmed | Confirmed defect | `android:allowBackup` is not set in `android/app/src/main/AndroidManifest.xml:14-17`, so the default `true` applies. Shared prefs, including the token, go into Google/ADB backups. | Token restored onto another device or extracted via `adb backup` (older Android versions). | `android:allowBackup="false"`, or `dataExtractionRules`/`fullBackupContent` excluding `FlutterSharedPreferences.xml`. |
| **SEC-04** | Medium | Confirmed | Confirmed defect | `wake()` on 401 calls `_forget()`, which never calls `_tokens.drop()` (`session_store.dart:127-129,294-298`). | The rejected token is still sent on every request, including public catalogue calls, and is re-validated on every launch. | `await _tokens.drop()` in that branch. |
| **SEC-05** | Low | Confirmed | Potential risk | A persisted `api.base_url` override has the highest priority even in release builds (`api_config.dart:69-76`). `pointAt` has **no caller** in `lib/` (grep), so it cannot be set from the UI today. | If a future debug panel exposes it, a release build could be pointed at an arbitrary (even `http`) host and send the token there. `faultIn` explicitly allows `http` (`api_config.dart:118-136`). | Ignore `_saved` when `!kDebugMode`, or require https in release. Remove the dead code if it is unused. |
| **SEC-06** | Low | Confirmed | Potential risk | The fingerprint lock is checked only on cold start. There is no `WidgetsBindingObserver` re-lock on resume. `biometricOnly: false` lets the device PIN unlock (`fingerprint_lock.dart:62-77`). | A backgrounded app stays unlocked indefinitely. Accepting the PIN is a deliberate product choice. | Add a resume re-lock with a grace period. |
| **SEC-07** | Low | Confirmed | Confirmed defect | No `minifyEnabled` / R8 or `--obfuscate` setup (`android/app/build.gradle.kts:31-38`). | Easier reverse engineering. Low risk because there are no secrets in the binary (grep found no keys or secrets). | Build release with `--obfuscate --split-debug-info`. Enable R8. |
| **SEC-08** | Info | Confirmed | Positive | The sign-in error shows the server's single message without revealing which phone numbers have accounts. All totals come from the server. No hard-coded secrets were found. | | |

---

## 7. State management

The pattern is `ChangeNotifier` stores (`SessionStore`, `BasketStore`) exposed through `InheritedNotifier` scopes (`lib/app/app_scope.dart:85-105`), plus per-screen `FutureBuilder`s.

| ID | Sev. | Conf. | Status | Finding | Fix |
|---|---|---|---|---|---|
| **ST-01** | High | Confirmed | Confirmed defect | `BasketStore.forget()` is called only on a 401 (`app_scope.dart:67`) and after an order (`checkout_page.dart:276`). It is **not** called after `session.signOut()` (`account_page.dart:208-212`) or `signOutEverywhere()` (`profile_page.dart:221-227`). The previous user's lines, totals and tab badge (`shell.dart:78`) remain, and checkout is still reachable. | Have `SessionStore` emit a signed-out event that `AppScope` wires to `_basket.forget()`, in the same way as `onTokenRejected`. |
| **ST-02** | High | Confirmed | Confirmed defect | The wishlist page fetches once in `initState` (`wishlist_page.dart:34`) and never listens to the session. Tabs use `StatefulShellRoute.indexedStack` (`router.dart:65`), so the state survives sign-out and sign-in. | Watch `AppScope.sessionOf(context)` and refetch when the shopper changes. Show `SignedOutPanel` when there is no shopper. |
| **ST-03** | Medium | Confirmed | Confirmed defect | `signIn` and `register` set `_shopper`, and the token is already persisted in `AuthRepository._admit` (`auth_repository.dart:133-143`), **before** `_loadOwn()`. If loading addresses or the wishlist fails, the call throws, the page shows an error, `notifyListeners()` is skipped, yet the user is signed in (`session_store.dart:136-169`). | `notifyListeners()` right after setting `_shopper`. Treat a `_loadOwn` failure as non-fatal. |
| **ST-04** | Medium | Confirmed | Confirmed defect | `wasRefused` (`session_store.dart:72`) has **no reader** (grep). A mid-session 401 wipes the basket (`app_scope.dart:65-68`) while the account still shows as signed in. `_refused` is reset only in `signIn` (line 141). | Show a re-login prompt when `wasRefused` is true. Reset the flag in `_forget()` and `register`. |
| **ST-05** | Medium | Confirmed | Confirmed defect | The basket is never loaded after sign-in, register or fingerprint unlock. `load` is called only at `splash_page.dart:129` and `checkout_page.dart:223`. `BasketPage` never calls `load`, contradicting `basket_store.dart:49-51`. `store.fault` is never rendered. | Call `load(force: true)` after authentication and when the basket tab opens. Render the fault with a retry. |
| **ST-06** | Medium | Confirmed | Confirmed defect | `BasketStore.isBusy` is documented as gating the steppers (`basket_store.dart:29-33`) but is never read in `basket_page.dart`. `_run` has no re-entrancy guard. Calls are fire-and-forget: `basket_page.dart:106` `store.clear();`, `:260` `store.remove(...)`, `coupon_box.dart` `removeCoupon()`. | Disable controls while busy. `await` and catch every call. Add a guard in `_run`. |
| **ST-07** | Medium | Confirmed | Confirmed defect | Add-to-basket can be double-submitted (`part_page.dart:538`, `part_card.dart:304`). | Disable while `isBusy`. |
| **ST-08** | Medium | Likely | Potential risk | Checkout sets `_place` before the server confirms and keeps it on failure. Rapid address taps can apply out of order. `_chooseShipping` has no guard. A 409 conflict only shows a snackbar and does not reload (`checkout_page.dart:195-246,281-289`). | Revert on failure. Use a request token to ignore stale replies. On 409, reload the basket and the checkout view. |
| **ST-09** | Low | Confirmed | Confirmed defect | `toggleKept` races on rapid taps (`session_store.dart:256-277`). Browse grid hearts are shown to guests and fail with an unhandled 401 (`browse_page.dart:327-345`). | Serialise per item. Gate on sign-in, using `LivePartCard`. |
| **ST-10** | Info | Confirmed | Positive | Stores rethrow so screens can report errors. `wake()` correctly tells offline apart from unauthenticated (`session_store.dart:113-129`). Controllers are disposed throughout. | |

---

## 8. API integration and data models

**Positives**
- One client with an envelope parser (`api_client.dart:138-166`).
- Status codes map to `FailureKind` (`:196-207`).
- Laravel field-level errors are collected (`:226-237`).
- `Accept-Language: ar` is sent.
- Null query values are dropped.
- A 20 s timeout is applied.
- Endpoints are centralised in `endpoints.dart`.

| ID | Sev. | Conf. | Status | Finding | Fix |
|---|---|---|---|---|---|
| **S-01** | Critical if true | Possible | **EXT** | `asDouble` and `asInt` accept only `num`; `asText` accepts only `String` (`lib/data/models/catalogue.dart:8-15`). Laravel `decimal` casts serialise as strings such as `"1250.00"`. If the API does this, every price, total and stock (`free`) becomes `0`: all parts show sold out and add is disabled. String ids would become `0`, and numeric part codes or phones would become `''`. | Accept numeric strings (`num.tryParse`) and stringify numbers in `asText`. **Verify** `ProductResource`, `BasketResource` and `OrderResource` JSON. |
| **S-02** | High if true | Likely/Possible | **EXT** | Hard casts throw `TypeError` (not `ApiFailure`) on type drift. **Likely** case: `order.dart:241` reads `json['shipping_method'] as String?`, while `basket.dart:201` treats the same key as a `Map`. If the order resource matches the basket, every order fails to parse. Also `order.dart:226` `status as Map?` (fails if it is a plain string). Others: `order.dart:30,108,144,232`; `catalogue.dart:182-184,192,313,357-361,366,423-427,453,496`; `basket.dart:26,29,32,134,168,196`; `account.dart:321-324,400,407-409`, where a numeric `building` or `flat` is plausible. PHP empty arrays encode as `[]`, which fails `as Map?`. | Add tolerant `asMap` / `asTextOrNull` helpers, using the `is Map` pattern already used for `coupon`, `payment` and `recipient`. |
| **S-03** | High | Possible | **EXT / Potential** | `POST checkout` has no idempotency key (`shop_repository.dart:36-51`). If the reply times out (20 s, `api_client.dart:35`) after the server has committed, the user retries and may create a duplicate order. | Send an `Idempotency-Key` header and have the server dedupe. After a timeout, re-read orders and the basket before allowing a retry. |
| **S-04** | Medium | Confirmed | Confirmed defect | Orders fetch page 1 only (`orders_page.dart:35,39`). `PartPage.hasMore` and `PartQuery.atPage` are unused (grep across `features/` and `core/`). See FN-02. | Implement paging. |
| **S-05** | Medium | Likely | Potential risk | `ApiClient._send` catches `TimeoutException`, `SocketException` and `ClientException` only (`api_client.dart:117-133`). TLS `HandshakeException` and similar escape as raw exceptions into `on ApiFailure`-only callers (§9). The timeout wraps only `send`, not the body read (`:115-116`). `Paged` casts `envelope['data'] as List<dynamic>?` (`:67-70`), which throws `TypeError` if `data` is an object. | Add a final `catch (e)` that maps to `FailureKind.unknown`, and wrap `_read` in the same guard. Apply the timeout to the full response. |
| **S-06** | Medium | Possible | **EXT** | Booleans are compared with `== true` or `!= false` (`catalogue.dart:195,316`; `account.dart:410`; `basket.dart:136-137,169`; `order.dart:31`). An un-cast tinyint `1`/`0` breaks them: `is_default: 1` reads as false, and `available: 0` reads as available. | Add an `asBool` helper. |
| **S-07** | Low | Confirmed | Confirmed defect | `AuthRepository._admit` returns a `Shopper` even when the envelope has no `token` (`auth_repository.dart:134-138`). The app then shows a signed-in user with no credentials. | Throw `ApiFailure(unknown)` when the token is absent. |
| **S-08** | Low | Possible | EXT | Dates are formatted without `.toLocal()` (`core/format/dates.dart:14-21,52`). UTC timestamps can show the wrong day near midnight in Egypt. | Call `toLocal()` before formatting. |
| **S-09** | Info | Confirmed | Confirmed | `updateProfile` sends `email: ''` and `company: ''` when null (`auth_repository.dart:84-86`), which may clear server values. Confirm this is intended. | |
| **S-10** | Info | Confirmed | Dead code | `_shipped` is never empty, so `isConfigured` is always true and the splash "not configured" UI is unreachable (`api_config.dart:36,87`; `splash_page.dart:381-387`). | Remove it or gate it behind debug. |

---

## 9. Error handling

The pattern is that screens catch `on ApiFailure` only. `Loader` (`core/widgets/loader.dart`) renders a generic Arabic message for any error type, which is good. Imperative handlers, however, are not covered.

| ID | Sev. | Conf. | Status | Finding | Fix |
|---|---|---|---|---|---|
| **ERR-01** | High | Confirmed | Confirmed defect | `_open` awaits `Future.wait([_waken(), delay])` and then `context.go(home)` (`splash_page.dart:70-83`). `SessionStore.wake` catches only `ApiFailure` (`session_store.dart:113`). Any other error (a `TypeError` in `Shopper.fromJson`, a platform exception) propagates, so `go()` never runs. | `try/finally` in `_open` that always navigates. Catch `Object` in `wake()`. |
| **ERR-02** | High | Confirmed | Confirmed defect | Place order (`checkout_page.dart:264-289`) catches `on ApiFailure` only. A parse error **after** the server has written the order leaves `_placing = true` (button disabled forever), does not clear the basket, and shows no confirmation. The user may order again. | Use `catch (e)` with `finally` resetting `_placing`. Treat unknown post-submit errors as "check your orders". |
| **ERR-03** | Medium | Confirmed | Confirmed defect | The same `on ApiFailure`-only pattern leaves buttons spinning in sign-in (`sign_in_page.dart:225-242`), register (`register_page.dart:313-331`), review (`review_sheet.dart:166`, where the button stays on "جارٍ الإرسال…" (sending…) forever), profile save (`profile_page.dart:147-171`) and password change (`password_sheet.dart:144-160`). | Use a catch-all plus `finally`, and the existing `sayFailure` helper. |
| **ERR-04** | Medium | Confirmed | Confirmed defect | Unawaited futures that rethrow produce uncaught async errors with no user feedback: `places_page.dart:154` `makeDefault`, `:198-200` `removePlace`; `basket_page.dart:106,260`; `coupon_box.dart` `removeCoupon`; `wishlist_page.dart:114-124`; `browse_page.dart:305`; `part_page.dart:161,411,568`. | Await and catch, and show a snackbar. |
| **ERR-05** | Medium | Confirmed | Confirmed defect | Filter-chip futures fail permanently: `final rows = await aisles;` (`browse_page.dart:99-100,406-421`). One offline open breaks the chips for the life of the page. | Re-fetch on failure. |
| **ERR-06** | Medium | Confirmed | Confirmed defect | Register ignores `snapshot.hasError` for governorates (`register_page.dart:145-160`). The field is required (`:297`), so an offline user cannot register and is not told why. | Show the error with a retry. |
| **ERR-07** | Medium | Confirmed | Confirmed defect | No global error handling. `main.dart` sets no `FlutterError.onError`, `PlatformDispatcher.instance.onError` or crash reporting, and does not use `runZonedGuarded` (`lib/main.dart:1-33`). If `SharedPreferences` fails in `main`, the app shows a blank screen. | Add handlers and a crash reporter (Crashlytics or Sentry). |
| **ERR-08** | Medium | Likely | Confirmed defect | The password sheet captures `Navigator.of(context)` and then pops after `await` without checking `mounted` (`password_sheet.dart:144-152`). The sheet can be drag-dismissed while the request is in flight, so `pop(true)` would pop the **ProfilePage** instead. | Check `mounted`. Set `isDismissible: !_sending` and `enableDrag: !_sending`. |
| **ERR-09** | Info | Confirmed | Positive | `Loader` never shows raw exception text. Dialogs pop with their own builder context, as covered by `test/dialog_test.dart`. | |

---

## 10. Input validation

| ID | Sev. | Conf. | Status | Finding | Fix |
|---|---|---|---|---|---|
| **VAL-01** | Medium | Confirmed | Confirmed defect (rule source is EXT) | The password rules disagree. Register requires 6 or more characters (`register_page.dart:167,180`). Change password requires 8 or more (`password_sheet.dart:127-131`). Neither has a maximum. The current-password field is not checked for non-empty. | Align with the Laravel rule. Add `maxLength`. |
| **VAL-02** | Low-Med | Likely | Confirmed defect | Phone: sign-in only checks `length < 11` with no `maxLength` (`sign_in_page.dart:104-107`). Register and the address form require 11 digits but not the `01x` prefix. `FilteringTextInputFormatter.digitsOnly` silently **drops Arabic-Indic digits** (٠-٩) typed on Arabic keyboards (`sign_in_page.dart:97-99`, `register_page.dart:127-129`, `place_form_page.dart:127`). | Normalise Eastern digits to ASCII, add `maxLength: 11`, and validate `^01[0125]\d{8}$`. |
| **VAL-03** | Low | Confirmed | Confirmed defect | No `maxLength` on name, company, email, address fields, coupon, checkout note or review title/body (`review_sheet.dart:93-105`). Email validation is just `contains('@') && contains('.')` (`register_page.dart:201`, `profile_page.dart:97`). | Mirror the server's `max:` rules. |
| **VAL-04** | Medium | Confirmed | Confirmed defect | The address form has no busy flag, so a double tap creates duplicates (`place_form_page.dart:209-212`). Editing an id not in `session.places` (for example the deep link `/account/places/form?id=99`) silently **creates** a new address (`:49-71,256-259`). | Add a `_saving` flag. Show not-found for unknown ids. |
| **VAL-05** | Low | Possible | Potential risk | The quantity stepper ceiling ignores the quantity already in the basket. Fractional stock between 0 and 1 shows "باقي 0" (0 left) but is still orderable. Fractional units are rounded (`part_page.dart:530-533`, `basket.dart:33`). | The server is authoritative; align the UI with it. |
| **VAL-06** | Low | Confirmed | Confirmed defect | Forms are not wrapped in `AutofillGroup`, and register and password fields have no `autofillHints`. | Add hints (`telephoneNumber`, `newPassword`, …). |

---

## 11. Navigation and functional completeness

| ID | Sev. | Conf. | Status | Finding | Fix |
|---|---|---|---|---|---|
| **NAV-01** | High | Confirmed | Confirmed defect | `GoRouter` has no `redirect`, `refreshListenable` or `errorBuilder` (`router.dart:50-219`). `/checkout`, `/account/orders[/:id]`, `/account/profile` and `/account/places[/form]` render for guests and locked users. A profile save then fails with 401, and orders show "sign in first" with no sign-in action. Unknown paths such as `/part/` (from `basket_page.dart:223` with a null slug) show go_router's default error page. | Add a guard `redirect` with `refreshListenable: session` and a return-to location, plus an Arabic `errorBuilder`. |
| **NAV-02** | Medium | Possible | EXT (runtime) | Checkout is on the root navigator but pushes `/account/places/form`, which lives inside a shell branch (`checkout_page.dart:142`; `router.dart:193-197`). | Add a root-level address route or open the form as a modal. Verify on a device. |
| **FN-01** | High | Confirmed | Confirmed defect | `_write(context)` uses `context.findAncestorWidgetOfExactType<VerdictList>()` with `VerdictList`'s **own** build context (`verdict_list.dart:11,33,48,64-70`). The lookup starts at the parent, so it always returns null and the function returns silently. Reviews can never be written. | Pass `itemId` directly and gate on sign-in. |
| **FN-02** | High | Confirmed | Confirmed defect | Browse and search show `page.total` ("340 قطعة", 340 parts) but only the first 20 parts (`perPage = 20`, `catalogue_repository.dart:18`). There is no load-more. | Add infinite scroll with a loading guard. |
| **FN-03** | High | Confirmed | Confirmed defect | "نسيت كلمة المرور؟" (forgot password?) shows "أرسلنا رسالة بها رابط الاستعادة." (we sent a message with a recovery link) and calls nothing (`sign_in_page.dart:135-139`). | Implement it, or replace it with contact instructions. |
| **FN-04** | Medium | Confirmed | Confirmed defect | More placeholder actions that report success: copy order number shows "نُسخ" (copied) with no `Clipboard.setData` (`order_page.dart:93-102`); "سنتواصل معك" (we'll contact you, `order_page.dart:176-184`); share part shows "link copied" (`part_page.dart:172-180`); "أبلغني" (notify me, `part_page.dart:510-519`); notifications bell (`shop_header.dart:87-95`); contact-us shows the number but does not dial (`account_page.dart:108-111`). | Implement them (`Clipboard`, `url_launcher` for tel: or WhatsApp, `share_plus`) or remove them. |
| **FN-05** | Medium | Confirmed | Confirmed defect | Browse opened from an aisle or maker tile shows "كل القطع" (all parts) and unselected chips although a filter is active (`aisle_strip.dart:265`, `maker_strip.dart:394`, `browse_page.dart:96-97`). Banner "تسوّق الآن" (shop now) ignores the parsed `slide.aisle` and `slide.maker` (`hero_banner.dart:232,302`). | Pass the names and ids through. |
| **FN-06** | Medium | Confirmed | Confirmed defect | The full `description` and `modelNumber` are parsed but never shown. "الوصف" (description) renders empty when `short_description` is null (`part_page.dart:395`). | Show `description ?? summary`. |
| **FN-07** | Medium | Confirmed | Confirmed defect | Text shows "null": `'${part.brand} · ${part.code}'` with a nullable `brand` (`search_page.dart:163`; `catalogue.dart:241`), and `'${aisle.count}'`, where `count` is usually null (`search_page.dart:260-265`; `catalogue.dart:32,44`). | Null-aware formatting. |
| **FN-08** | Medium | Likely | Potential risk | "لا توجد تقييمات بعد" (no reviews yet) appears above actual review cards when the server omits `rating` and `rating_count` (`verdict_list.dart:36-46`). | Derive the values from `verdicts`. |
| **FN-09** | Medium | Confirmed | Confirmed defect | The part page has no back button in loading and error states (`part_page.dart:49-66`). The checkout `Loader` states have no Scaffold or crown (`checkout_page.dart:94-100`). | Add an `AppBar` for non-success states. |
| **FN-10** | Medium | Likely | Confirmed defect | Checkout swaps the `Future` on address change (`checkout_page.dart:207-208`). This rebuilds the body and resets the uncontrolled note `TextField` (`:361-368`), while `_note` keeps the old text that the user can no longer see. | Keep the view in state and use a `TextEditingController`. |
| **FN-11** | Low | Confirmed | Confirmed defect | Pull-to-refresh returns before the reload finishes, and the error and loading states cannot be scrolled (`home_page.dart:57-59`, `aisles_page.dart:44-46`, `makers_page.dart:133-135`, orders, order, wishlist). | Return the future. Use `AlwaysScrollableScrollPhysics`. |
| **FN-12** | Low | Confirmed | Confirmed defect | `/placed` without params shows an empty reference. The ETA "يومين إلى أربعة أيام" (two to four days) is hard-coded (`placed_page.dart:97`). The version string `'إصدار ١٫٠٫٠'` (version 1.0.0) is hard-coded (`account_page.dart:150`). | Read the ETA from the server and the version from `package_info_plus`. |

---

## 12. Performance

| ID | Sev. | Conf. | Status | Finding | Fix |
|---|---|---|---|---|---|
| **PERF-01** | High | Confirmed | Confirmed defect | `onChanged: (_) => _run()` (`browse_page.dart:161`) and `_look()` (`search_page.dart:83`) issue one request per keystroke. `Loader` swaps to a spinner on each one, losing the scroll position, and fast typing can trigger 429 responses. Stale replies are ignored correctly, because `FutureBuilder` follows only the latest future. | 300–400 ms debounce (cancel in `dispose`), a minimum query length, and keep the old results while loading. |
| **PERF-02** | Medium | Confirmed | Confirmed defect | `Image.network` has no `cacheWidth` or `cacheHeight` (`core/widgets/part_artwork.dart:57-69`, `home/widgets/certificate_badge.dart:407-432`), so full-size photos are decoded for thumbnails. There is no disk cache. | Set `cacheWidth` from the size × DPR. Consider `cached_network_image`. |
| **PERF-03** | Low | Confirmed | Confirmed defect | Aisles and makers are fetched separately by `AisleStrip`, `MakerStrip`, `BrowsePage` and `SearchPage` with no cache. Every card watches both stores, and `BasketStore._run` notifies twice per call, so all visible cards rebuild on each basket change (`browse_page.dart:334-335`, `part_shelf.dart:390-391`). | Cache the reference data and use `select`-style listening. |
| **PERF-04** | Low | Confirmed | Confirmed defect | `AppTheme.light` and `AppTheme.dark` are getters that rebuild `ThemeData` on every access, although documented as "built once". | Use `static final`. |
| **PERF-05** | Low | Confirmed | Confirmed (analyzer) | Deprecated `cacheExtent` (`part_shelf.dart:34`). | Use `scrollCacheExtent`. |
| **PERF-06** | Info | Confirmed | Positive | Lists use `SliverList.builder`, `SliverGrid.builder` and `GridView.builder`. Formatters are static. | |

---

## 13. UI, accessibility, RTL and localisation

| ID | Sev. | Conf. | Status | Finding | Fix |
|---|---|---|---|---|---|
| **A11Y-01** | Medium | Confirmed | Confirmed defect | Mirrored icons point the wrong way. The Flutter SDK declares `arrow_forward_rounded`, `arrow_back_rounded` and `chevron_left_rounded` with `matchTextDirection: true` (checked in `D:/src/flutter/.../material/icons.dart:2304,2496,5496`). With the `ar` locale they are flipped. Back buttons use `arrow_forward_rounded` (`page_crown.dart:75`, `sign_in_page.dart:195`, `register_page.dart:279`); "proceed" uses `arrow_back_rounded` (`basket_page.dart:351`); "see all" and list rows use `chevron_left_rounded` (`section_head.dart:85`, `account_page.dart:368`). | Use the semantic icon (back = `arrow_back`) and let Flutter mirror it, or use `BackButtonIcon`. |
| **A11Y-02** | Medium | Confirmed | Confirmed defect | Light-theme contrast is below WCAG AA (computed): price coral `#FF7A45` on white ≈2.6:1; `inkFaint #8AA0A8` ≈2.7:1; white on `brand #10B5A8` (primary buttons) ≈2.6:1; white on `brandLift #2AD6C6` ≈1.8:1; warn pill ≈2.2:1 (`core/theme/palette.dart`, `app_theme.dart`). | Darken the text-bearing tokens and keep the bright hues for fills. |
| **A11Y-03** | Low | Confirmed | Confirmed defect | Icon-only controls have no tooltip or semantics: `CrownAction` has no label field (`page_crown.dart:126-132,167-187`); also `shop_header.dart:164-184`, `part_card.dart:242-266` (≈30 px target), `quantity_stepper.dart:324-354` (32 px), `places_page.dart:162-167`, the password visibility toggles, `review_sheet.dart:79` stars, `app_field.dart:320`. | Add `tooltip` or `Semantics`, with a minimum 48 px target. |
| **A11Y-04** | Low | Confirmed | Confirmed (design choice) | Text scale is clamped to 1.3 (`app/montaser_app.dart:55-58`). This limits users who need 200% text (WCAG 1.4.4). | Raise the cap and fix the layouts that break. |
| **L10N-01** | Low-Med | Confirmed | Confirmed defect | Digits are mixed. `Money` uses `ar_EG`, which gives Arabic-Indic digits (`money.dart:72-73`). `DateFormat(..., 'ar')` gives Western digits in intl 0.20.3, so the comment at `dates.dart:9-11` is wrong. Interpolated ints are Western (`quantity_stepper.dart:308`, `pills.dart:279,328`). "منذ 2 أيام" ("2 days ago", with the wrong grammatical form) is used where Arabic needs the dual "منذ يومين" (`dates.dart:32-58`). | Pick one numbering system and route every number through it. Use proper Arabic plural forms (`Intl.plural`). |
| **L10N-02** | Medium | Confirmed | Confirmed defect | The governorate search does not normalise hamza, taa marbuta or alif maqsura (`governorate_picker.dart:512`), so "اسوان" does not match "أسوان". | Normalise both sides of the comparison. |
| **UI-01** | Medium | Confirmed | Confirmed defect | Home strips put a full-size `FailureNote` (>300 px) inside 132 px and 92 px boxes. This overflows in debug and is clipped in release (`aisle_strip.dart:213-216`, `maker_strip.dart:350-352`). | Use a compact error variant. |
| **UI-02** | Low | Confirmed | Confirmed defect | Physical `right` padding and `TextAlign.right` are used instead of directional values (`app_field.dart:226`, `governorate_picker.dart:399,447`, `search_page.dart:165`, `part_page.dart:347`). The star colour is hard-coded outside the theme (`pills.dart:323`, `verdict_list.dart:171`). | Use `EdgeInsetsDirectional` and `TextAlign.end`, and add a theme token. |
| **UI-03** | Info | Confirmed | Confirmed | Comments disagree with the code: the dead conditional `plain ? Colors.white : Colors.white` (`brand_mark.dart:34`); `leave_guard.dart:14-16` vs `shell.dart:49`; `aisles_page.dart:85` `128` vs `AisleTile.tall` 132; fallback name `'منتصر'` (`shop_header.dart:68`). | Fix them. |
| **UI-04** | Info | Confirmed | Positive | RTL comes from the locale rather than a hand-placed `Directionality`. There is a full dark theme. Cairo is bundled. Directional widgets are used in most places. | |

---

## 14. Dependencies

From `pubspec.yaml:22-77` and `pubspec.lock`:

| Package | Locked | Latest | Note |
|---|---|---|---|
| `go_router` | 17.5.0 | 18.1.0 | Major upgrade available; review the breaking changes before adopting. |
| `cupertino_icons` | 1.0.9 | 2.0.0 | Major. Low impact; it is also **not referenced** in `lib/`, so it may be removable (EXT: confirm). |
| `shared_preferences` | 2.5.5 | 2.5.6 | Patch. Its use for the token should move to secure storage (SEC-02). |
| `local_auth` | 3.0.x | (transitive `local_auth_android` 2.0.10 → 2.3.0) | Run `flutter pub upgrade` to pick up platform fixes. |
| `http` | ^1.6.0 | current | OK |
| `intl` | ^0.20.3 | pinned by `flutter_localizations` | The rationale is documented in pubspec; OK. |

- **DEP-01 (Low, Confirmed)**: 14 transitive packages are locked below resolvable versions. Run `flutter pub upgrade` in a branch and re-run the tests.
- **DEP-02 (Info)**: The following are missing:
  - `flutter_secure_storage` (SEC-02);
  - a crash reporter (ERR-07);
  - `url_launcher`, `share_plus` or `Clipboard` usage for the stub actions (FN-04);
  - `package_info_plus` (FN-12).
- **DEP-03 (EXT)**: There was no offline vulnerability advisory check. Check https://osv.dev against `pubspec.lock` in CI.

---

## 15. Platform configuration

### Android

| ID | Sev. | Conf. | Status | Finding | Fix |
|---|---|---|---|---|---|
| **PLAT-01** | High | Confirmed | Confirmed defect | `release { signingConfig = signingConfigs.getByName("debug") }` (`android/app/build.gradle.kts:34-38`). The Play Store rejects it, and the debug key is not under the owner's control. | Add an upload keystore through `key.properties`. It is already gitignored (`android/.gitignore`). |
| **PLAT-03** | Medium | Confirmed | Confirmed | `applicationId = "com.montaser.montaser_app"` still has the template `TODO` (`build.gradle.kts:23-24`). The application ID cannot change after publishing. | Decide it before the first release. |
| SEC-03 | Medium | Confirmed | Confirmed defect | `allowBackup` is not disabled (see §6). | |
| **PLAT-04** | Low | Possible | EXT | There is no `usesCleartextTraffic` or network security config. `http://` image URLs from the API fail on Android 9+ and fall back to the drawn artwork (`catalogue.dart:118-124`). Dart HTTP itself is not affected. | Have the server send https URLs. |
| **PLAT-05** | Info | Confirmed | Positive | `MainActivity` correctly extends `FlutterFragmentActivity` for BiometricPrompt (`MainActivity.kt:13`). `INTERNET` is declared in the main manifest (`AndroidManifest.xml:11`). | |

Note: `android/.kotlin/errors/*.log` files exist. They are build leftovers from 2026 builds and are harmless, but should not be committed.

### iOS

| ID | Sev. | Conf. | Status | Finding | Fix |
|---|---|---|---|---|---|
| **PLAT-02** | High | Likely | Confirmed missing (runtime effect EXT) | `ios/Runner/Info.plist` has no `NSFaceIDUsageDescription`, although `local_auth` is used (`fingerprint_lock.dart`). On Face ID devices, iOS refuses or degrades Face ID for the app, and App Review flags it. | Add an Arabic usage string. |
| **PLAT-06** | Low | Confirmed | Confirmed | `CFBundleDisplayName` is "Montaser App" (`Info.plist:10`), while the Android label is "مؤسسة منتصر". There is no `CFBundleLocalizations` entry for `ar`, so system dialogs may be in English. | Align the names and add `ar`. |
| **PLAT-07** | Low | Confirmed | Potential risk | Landscape is enabled on iPhone (`Info.plist:56-61`), but the layouts are tested only in portrait (`widget_test.dart`). | Restrict to portrait, or test landscape. |

### Web / Windows

- **PLAT-08 (Low, Confirmed)**: Template title and description (`web/index.html:18,29`, `manifest.json`). The token would sit in `localStorage`. Biometrics are unsupported on web and fail closed (`isPossible` returns false). Decide whether web and Windows are supported targets; if not, remove them.

---

## 16. Tests

| ID | Sev. | Conf. | Status | Finding | Fix |
|---|---|---|---|---|---|
| **TEST-01** | High | Confirmed | Confirmed gap | Only 5 widget tests exist. There are **no unit tests** for `ApiClient` envelope and error mapping, model `fromJson` (where S-01 and S-02 would have been caught), `SessionStore` or `BasketStore` transitions (ST-01 to ST-05), or the router. `ApiClient` already accepts an injected `http.Client` (`api_client.dart:23`) and `Repositories.useForTesting` exists (`repositories.dart:54-56`), so the seams are in place. | Add `MockClient`-based tests for the client, fixture-based model tests using **real API JSON samples**, and store tests. |
| **TEST-02** | Low | Confirmed | Confirmed | `test/widget_test.dart:64-78`, "says so plainly when the shop cannot be reached": under `TestWidgetsFlutterBinding`, HTTP returns 400, so this exercises `FailureKind.unknown`, not the offline path its comment describes. | Inject a `MockClient` that throws `SocketException`. |
| **TEST-03** | Low | Confirmed | Confirmed | `test/dialog_test.dart` tests an inline copy of the dialog pattern, not the app's dialogs. | Pump the real account and basket confirmation flows. |
| **TEST-04** | Info | Confirmed | | No CI configuration, no coverage, and no integration tests (`integration_test/` is absent). | Add CI running `analyze` and `test`. |

---

## 17. Classification summary

### 17.1 Confirmed defects (fix before release)
SEC-01, SEC-02, SEC-03, SEC-04, ST-01–ST-07, NAV-01, ERR-01–ERR-08, FN-01–FN-07, FN-09–FN-12, VAL-01 (the client-side mismatch), VAL-02–VAL-04, VAL-06, PERF-01–PERF-05, A11Y-01–A11Y-03, L10N-01, L10N-02, UI-01, UI-02, PLAT-01, PLAT-02 (key missing), PLAT-03, TEST-01.

### 17.2 Potential risks
SEC-05, SEC-06, ST-08, ST-09, S-05, VAL-05, FN-08, PLAT-07, AR-01, AR-02.

### 17.3 Requires external verification
| Item | What to verify | Against |
|---|---|---|
| S-01 | Are prices, quantities and ids sent as JSON numbers or strings? | Real `/products`, `/cart`, `/orders` responses |
| S-02 | Shape of `orders[].shipping_method` (string or object) and `status` (object or string); empty objects sent as `[]` | `OrderResource` / `/orders/{id}` |
| S-03 | Does `POST /checkout` dedupe retries? | Backend |
| S-06 | Are booleans cast (`true`/`false`) or tinyint (`1`/`0`)? | Model `$casts` |
| S-08 | Are timestamps UTC (`Z`)? | API |
| VAL-01 | Server password `min` rule | `RegisterRequest` / `PasswordRequest` |
| SEC-04 | Do public routes reject a stale bearer token? | Sanctum middleware config |
| NAV-02 | go_router behaviour when a root route pushes a shell-branch route | Device run |
| PLAT-02 | Face ID behaviour without the usage key | iOS device / App Review |
| PLAT-04 | Are image URLs https? | API |
| DEP-03 | Advisories for locked versions | osv.dev |

---

## 18. Prioritised remediation plan (not implemented)

**P0: release blockers**
1. Verify S-01 and S-02 against real API payloads, then make the model helpers type-tolerant.
2. Fix the session boundary:
   - clear basket and wishlist on sign-out (ST-01, ST-02);
   - make the lock actually withhold the token (SEC-01);
   - drop rejected tokens (SEC-04);
   - add router guards (NAV-01).
3. Use catch-all plus `finally` in the splash, checkout, sign-in, register, review and profile flows (ERR-01 to ERR-03). Add an idempotency key to checkout (S-03).
4. Release signing (PLAT-01), `NSFaceIDUsageDescription` (PLAT-02), final application ID (PLAT-03).
5. Move the token to secure storage and disable backup (SEC-02, SEC-03).

**P1: functional correctness**
6. Pagination for catalogue and orders (FN-02, S-04). Debounced search (PERF-01).
7. Fix the review button (FN-01). Implement or remove the stub actions (FN-03, FN-04).
8. Load the basket after authentication. Use the busy flag and awaited calls for basket and address actions (ST-05 to ST-07, ERR-04, VAL-04).
9. Global error handler and crash reporting (ERR-07).

**P2: quality**
10. RTL icon direction, contrast, semantics (A11Y-01 to A11Y-03). Digit consistency and Arabic normalisation (L10N-01, L10N-02).
11. Image decode sizing and caching (PERF-02). Reference-data caching (PERF-03).
12. Unit-test suite and CI (TEST-01 to TEST-04). Dependency upgrades (DEP-01). Version control (AR-03).

---

## 19. Limitations

- `FLUTTER_AUDIT_PROMPT.md` was not available. The section structure follows the request text instead.
- No backend, device or simulator was available. Runtime behaviour (layout, biometrics, go_router nested navigation) is inferred from code and SDK sources and is marked EXT where it matters.
- Feature screens were reviewed in two read-only passes. The highest-impact claims were re-checked directly against the source (§2). Other line numbers come from `cat -n` output at audit time.
- No fixes were applied. The only file this audit creates is this report.
