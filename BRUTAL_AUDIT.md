# 🚨 Brutal Production‑Level Audit Report

**Project:** Crescent‑Gate (Flutter + Supabase + OneSignal)
**Generated:** 2025‑12‑10

---

## 📑 Table of Contents
1. [Code Quality & Linting](#code-quality--linting)
2. [Architecture & Modularity](#architecture--modularity)
3. [Security & Permissions](#security--permissions)
4. [Performance & Responsiveness](#performance--responsiveness)
5. [UI/UX & Design Consistency](#uiux--design-consistency)
6. [Testing & Coverage](#testing--coverage)
7. [Build & Release Configuration](#build--release-configuration)
8. [CI/CD & Automation](#cicd--automation)
9. [Dependency Management](#dependency-management)
10. [Database & Schema Integrity](#database--schema-integrity)
11. [API & Network Layer](#api--network-layer)
12. [Notification System](#notification-system)
13. [Logging, Crash Reporting & Monitoring](#logging-crash-reporting--monitoring)
14. [Internationalisation & Accessibility](#internationalisation--accessibility)
15. [Documentation & On‑boarding](#documentation--on‑boarding)
16. [Compliance & Legal]

---

## 1️⃣ Code Quality & Linting
| # | Check | Status | Notes |
|---|-------|--------|-------|
| 1 | **Run `flutter analyze`** – ensure no warnings/errors. | ❓ | Add `analysis_options.yaml` with `strict-inference` and `prefer_const_constructors`. |
| 2 | **Enable `dart format`** on CI – enforce consistent formatting. |
| 3 | **Unused imports / dead code** – use `dart pub global run dart_code_metrics:metrics`. |
| 4 | **Prefer `const` where possible** – reduces rebuild cost. |
| 5 | **Avoid `dynamic`** – enforce strong typing (`no_dynamic` rule). |
| 6 | **Check for `!` null‑assertions** – replace with proper null‑checks. |
| 7 | **Enforce `final` for immutable fields** – especially in model classes (`AppUser`). |
| 8 | **Detect duplicated code** – run `sonarqube` or `dart_code_metrics` `duplicate_code`. |
| 9 | **Check for large widgets** – split >200 LOC widgets into smaller components. |
|10| **Avoid heavy work in `build`** – no async calls, DB queries, or heavy calculations. |
|11| **No `print` statements** – replace with proper logging (`logger`). |
|12| **Avoid `setState` in `StatelessWidget`** – ensure correct widget type. |
|13| **Check for `await` without `try/catch`** – wrap all async calls. |
|14| **Ensure `await` on futures** – no fire‑and‑forget unless intentional. |
|15| **Avoid `Future.microtask` misuse** – only for non‑blocking UI init. |
|16| **Validate all `Navigator` calls** – use named routes, avoid hard‑coded strings. |
|17| **Check for `BuildContext` usage after `await`** – may be disposed. |
|18| **Enforce `async`/`await` naming convention** – suffix with `Async`. |
|19| **Avoid `any`/`as` casts** – use proper generics. |
|20| **Check for `List<dynamic>`** – replace with typed lists. |
|21| **Enforce `required` keyword** on all non‑optional constructor params. |
|22| **Detect large `switch`/`if` chains** – consider strategy pattern. |
|23| **Check for magic numbers** – extract to constants. |
|24| **Validate naming conventions** – `camelCase` for variables, `PascalCase` for classes. |
|25| **Ensure all files have a header comment** – author, purpose, date. |
|26| **Run `dart pub outdated --mode=null-safety`** – no outdated packages. |
|27| **Check for transitive dependencies with known CVEs** – use `snyk` or `dependabot`. |
|28| **Enforce `no_implicit_call_tearoffs`** – avoid ambiguous callbacks. |
|29| **Check for `debugPrint` leakage** – remove before release. |
|30| **Validate `@override` usage** – all overridden methods must have it. |
|31| **Ensure `@immutable` on data classes** – e.g., `AppUser`. |
|32| **Check for `late` variables without initialization guard** – may cause runtime errors. |
|33| **Detect large `Map` literals** – extract to separate constants. |
|34| **Validate `enum` usage** – prefer enums over string literals for roles. |
|35| **Check for `Future<void>` vs `Future<T>` misuse** – return proper types. |
|36| **Ensure all `async` functions are awaited** – avoid unhandled futures. |
|37| **Run `dart analyze --fatal-infos`** – treat infos as errors. |
|38| **Check for `@Deprecated` usage** – remove or replace. |
|39| **Validate `pubspec.yaml` formatting** – no trailing spaces, proper indentation. |
|40| **Enforce `flutter_lints`** – add to `dev_dependencies`. |
|41| **Check for `package:meta` annotations misuse** – `@required` vs `required`. |
|42| **Detect `await` inside loops** – consider `Future.wait`. |
|43| **Validate `Stream` subscriptions** – always cancel in `dispose`. |
|44| **Check for `Timer` leaks** – cancel on widget dispose. |
|45| **Ensure `dispose` calls `super.dispose()`**. |
|46| **Validate `StatefulWidget` vs `ConsumerStatefulWidget` usage** – consistent with Riverpod. |
|47| **Check for `context.read` vs `ref.watch` mixing** – stick to Riverpod pattern. |
|48| **Validate `ProviderScope` placed at top level** – no nested scopes unless needed. |
|49| **Check for `FutureBuilder` without `snapshot.hasError` handling**. |
|50| **Validate `CircularProgressIndicator` color contrast** – meets WCAG AA. |

> **Result:** 50 concrete lint‑style checks. Add the remaining 50 in the sections below.

---

## 2️⃣ Architecture & Modularity
| # | Check | Status |
|---|-------|--------|
| 51 | **Feature‑folder structure** – each screen has its own `widgets`, `models`, `services`. |
| 52 | **Separation of concerns** – UI should not contain business logic (move to providers/services). |
| 53 | **Avoid large `main.dart`** – keep only app bootstrap. |
| 54 | **Dependency injection** – use Riverpod `Provider` for all services (Auth, Supabase, OneSignal). |
| 55 | **Singleton misuse** – ensure no manual `new` of services; rely on providers. |
| 56 | **State management consistency** – all screens use Riverpod; no `setState` for global state. |
| 57 | **Navigation** – use named routes only; avoid `push` with raw widgets. |
| 58 | **Modularize notification logic** – separate OneSignal handling into its own service (done). |
| 59 | **Avoid tight coupling** – e.g., `AuthWrapper` directly calls `FirestoreService`; consider abstraction. |
| 60 | **Domain layer** – consider adding a `repository` layer between Supabase and UI. |
| 61 | **Use `freezed` or `json_serializable`** for model classes (`AppUser`). |
| 62 | **Avoid mutable models** – make `AppUser` immutable (`@immutable`). |
| 63 | **File naming consistency** – snake_case for files, PascalCase for classes. |
| 64 | **Avoid duplicate widget code** – extract common UI (e.g., app bar, loading spinner). |
| 65 | **Ensure `ThemeData` is centralized** – no hard‑coded colors scattered. |
| 66 | **Dark mode support** – verify all colors have dark equivalents. |
| 67 | **Responsive layout** – use `LayoutBuilder` / `MediaQuery` for tablets. |
| 68 | **Avoid large `switch` for role navigation** – consider a map of role → widget. |
| 69 | **Check for `globalKey` misuse** – only one `navigatorKey` needed. |
| 70 | **Ensure `AppTheme` provides both light & dark** – currently only dark. |

---

## 3️⃣ Security & Permissions
| # | Check |
|---|-------|
| 71 | **Supabase RLS policies** – verify they cover all tables (visitors, complaints, etc.). |
| 72 | **Never expose `anonKey` in client logs** – mask in production builds. |
| 73 | **OneSignal App ID** – keep in env variables, not hard‑coded. |
| 74 | **Secure storage for tokens** – use `flutter_secure_storage` for refresh tokens. |
| 75 | **Validate all user input** – server‑side validation for visitor names, phone numbers. |
| 76 | **Enforce HTTPS** – Supabase endpoint must be `https://`. |
| 77 | **Content‑Security‑Policy** – not applicable to mobile but ensure no insecure WebViews. |
| 78 | **Avoid SQL injection** – use parameterized queries (`.eq`, `.select`). |
| 79 | **Check for over‑permissive RLS** – e.g., `INSERT WITH CHECK (true)` may be too open. |
| 80 | **Audit `public` schema** – ensure no tables are unintentionally public. |
| 81 | **Two‑factor auth** – consider enabling MFA for admin accounts. |
| 82 | **Password policy** – enforce minimum length, complexity. |
| 83 | **Rate limiting on auth endpoints** – Supabase provides built‑in throttling. |
| 84 | **Audit `auth.users` deletion** – ensure no orphaned profiles remain. |
| 85 | **Check for `owner_id` leakage** – never expose internal IDs to UI unless needed. |
| 86 | **Secure notification payloads** – avoid sending sensitive data via OneSignal. |
| 87 | **Ensure `supabase` client uses `autoRefreshToken`** – avoid stale sessions. |
| 88 | **Audit third‑party SDK versions** – OneSignal, Google Mobile Ads for known vulnerabilities. |
| 89 | **Validate `photo_url` inputs** – ensure they are from trusted storage (Supabase). |
| 90 | **Check for open redirects** – any URL launch should be whitelisted. |

---

## 4️⃣ Performance & Responsiveness
| # | Check |
|---|-------|
| 91 | **Profile app startup time** – aim < 2 s cold start. Use `flutter build apk --profile` and `adb shell am start -W`. |
| 92 | **Lazy‑load heavy screens** – use `FutureBuilder` or `DeferredComponent`. |
| 93 | **Image caching** – ensure `cached_network_image` is used everywhere. |
| 94 | **Image compression** – compress before upload (already using `image` lib). |
| 95 | **Avoid large widget trees** – keep depth < 10 where possible. |
| 96 | **Use `const` constructors** – reduces rebuild cost. |
| 97 | **Network request batching** – combine multiple small calls into one. |
| 98 | **Pagination for visitor list** – avoid loading all rows at once. |
| 99 | **Use `ListView.builder`** – not `ListView` with many children. |
|100| **Avoid `setState` on every keystroke** – debounce text fields. |
|101| **Measure memory usage** – ensure < 150 MB on typical device. |
|102| **Dispose of controllers** – `AnimationController`, `TextEditingController`. |
|103| **Avoid `Future.microtask` for heavy work** – use isolates if needed. |
|104| **Check for jank** – use `flutter performance` overlay, aim < 16 ms frame. |
|105| **Enable `--split-debug-info`** for release builds. |
|106| **Minify assets** – compress SVG/PNG, use WebP where possible. |
|107| **Audit `pubspec.yaml` assets** – no unused large images. |
|108| **Use `flutter_native_splash`** – avoid blank screens on launch. |
|109| **Background service efficiency** – ensure it runs only when needed. |
|110| **OneSignal notification handling** – avoid heavy UI work in callbacks. |

---

## 5️⃣ UI/UX & Design Consistency
| # | Check |
|---|-------|
|111| **Consistent color palette** – all screens use `AppTheme` colors. |
|112| **Typography hierarchy** – use `GoogleFonts` with defined `TextTheme`. |
|113| **Touch target size** – minimum 48 dp for tappable elements. |
|114| **Contrast ratio** – meet WCAG AA (≥ 4.5:1). |
|115| **Avoid hard‑coded strings** – use `intl` for localization. |
|116| **Error messages** – user‑friendly, not raw stack traces. |
|117| **Loading states** – always show a spinner or skeleton. |
|118| **Empty states** – friendly illustration + call‑to‑action. |
|119| **Animation performance** – use `flutter_staggered_animations` wisely. |
|120| **Back navigation** – confirm before discarding unsaved changes. |
|121| **Form validation** – immediate feedback, not only on submit. |
|122| **Responsive font scaling** – respect system `fontScale`. |
|123| **Accessibility labels** – `semanticsLabel` for icons. |
|124| **Test on both iOS & Android** – ensure UI parity. |
|125| **Avoid overflow** – use `Flexible`/`Expanded` where needed. |
|126| **Dark mode testing** – verify all images have dark variants or proper tint. |
|127| **Use `SafeArea`** – avoid notch clipping. |
|128| **Consistent app bar** – same height, elevation, back button. |
|129| **Avoid nested scrollables** – use `CustomScrollView` with slivers. |
|130| **Micro‑animations** – subtle hover/press effects for premium feel. |

---

## 6️⃣ Testing & Coverage
| # | Check |
|---|-------|
|131| **Unit tests** – aim > 80 % coverage for services (`AuthService`, `OneSignalManager`). |
|132| **Widget tests** – test critical screens (Login, Visitor list, SOS). |
|133| **Integration tests** – use `integration_test` to simulate full flow. |
|134| **Mock Supabase** – use `mockito` or `http_mock_adapter`. |
|135| **Mock OneSignal** – ensure sync logic works without real push. |
|136| **CI runs tests on every PR** – fail fast. |
|137| **Test edge cases** – network loss, auth expiration, permission denial. |
|138| **Run `flutter test --coverage`** and generate `lcov`. |
|139| **Enforce coverage gate** – e.g., `min_coverage: 80`. |
|140| **Fuzz testing for JSON parsing** – ensure model `fromMap` never throws. |
|141| **Performance tests** – benchmark visitor list loading. |
|142| **Accessibility tests** – use `flutter_test` semantics. |
|143| **Snapshot tests for UI** – ensure design regressions are caught. |
|144| **Test background service** – ensure it stops when app is closed. |
|145| **Test notification handling** – simulate OneSignal callbacks. |

---

## 7️⃣ Build & Release Configuration
| # | Check |
|---|-------|
|146| **Versioning** – `version: X.Y.Z+N` matches `pubspec.yaml`. |
|147| **App icons** – include all required sizes for iOS/Android. |
|148| **Splash screen** – use `flutter_native_splash` for both platforms. |
|149| **Proguard/R8 rules** – enable for release builds. |
|150| **Code shrinking** – `--split-debug-info` and `--obfuscate`. |
|151| **Signing keys** – store securely, not in repo. |
|152| **Play Store metadata** – complete store listing, screenshots. |
|153| **iOS App Store** – proper `Info.plist` permissions (camera, notifications). |
|154| **Gradle build types** – `debug`, `release` with proper `minifyEnabled`. |
|155| **Fastlane** – automate build & upload. |
|156| **App bundle (`aab`)** – generate for Play Store. |
|157| **Validate `android/app/src/main/AndroidManifest.xml`** – correct permissions, `android:exported`. |
|158| **Check `Info.plist`** – `UIBackgroundModes` for notifications. |
|159| **Enable `android:allowBackup="false"`** for security. |
|160| **Verify `build.gradle`** – use latest stable Flutter SDK. |
|161| **Run `flutter doctor -v`** – ensure no warnings. |

---

## 8️⃣ CI/CD & Automation
| # | Check |
|---|-------|
|162| **GitHub Actions** – lint, test, build on push to `main`. |
|163| **Branch protection** – require PR reviews, status checks. |
|164| **Automated dependency updates** – Dependabot. |
|165| **Release tagging** – `git tag -a vX.Y.Z`. |
|166| **Deploy to Supabase** – run migration script on CI. |
|167| **Static analysis** – run `flutter analyze` in CI. |
|168| **Code coverage badge** – publish to README. |
|169| **Secret management** – use GitHub Secrets for API keys. |
|170| **Rollback strategy** – keep previous APK/AAB on Play Store. |
|171| **Automated UI tests** – run on Firebase Test Lab. |

---

## 9️⃣ Dependency Management
| # | Check |
|---|-------|
|172| **Upgrade all packages to latest stable** – run `flutter pub upgrade`. |
|173| **Remove unused dependencies** – `flutter pub deps --no-dev`. |
|174| **Pin critical packages** – avoid major version jumps without testing. |
|175| **Audit `pubspec.yaml` for duplicate entries** – e.g., `http` vs `dio`. |
|176| **Check for `path_provider` vs `shared_preferences` overlap**. |
|177| **Validate `google_mobile_ads` test IDs** – use test IDs in dev. |
|178| **Ensure `intl` locales are generated** – run `flutter pub run intl_translation:generate_from_arb`. |
|179| **Check for `flutter_lints` version compatibility**. |
|180| **Verify `onesignal_flutter` version supports iOS 16+**. |

---

## 🔟 Database & Schema Integrity
| # | Check |
|---|-------|
|181| **Run `pg_dump --schema-only`** – keep version‑controlled schema. |
|182| **Verify foreign key constraints** – e.g., `visitors.resident_id` → `profiles.id`. |
|183| **Check for nullable columns that should be NOT NULL**. |
|184| **Add indexes on frequently queried columns** – `wing`, `flat_number`. |
|185| **Audit `created_at`/`updated_at` triggers** – ensure they auto‑update. |
|186| **Validate `ON DELETE CASCADE` behavior** – no orphan rows. |
|187| **Review RLS policies for each table** – ensure least‑privilege. |
|188| **Test data migrations** – run `RESET_HISTORY.sql` on staging. |
|189| **Backup strategy** – daily automated backups, test restore. |
|190| **Check for `JSONB` usage** – ensure proper indexing (`GIN`). |
|191| **Audit `onesignal_player_id` column** – length, uniqueness. |
|192| **Ensure `profiles` has unique `email` constraint**. |
|193| **Add `UNIQUE` on `guest_passes.code`**. |
|194| **Validate `sos_alerts` status transitions** – trigger functions if needed. |
|195| **Add audit log table** – track critical changes. |

---

## 1️⃣1️⃣ API & Network Layer
| # | Check |
|---|-------|
|196| **Timeouts** – set reasonable HTTP timeout (≤ 10 s). |
|197| **Retry logic** – exponential backoff for transient failures. |
|198| **Error handling** – map Supabase errors to user‑friendly messages. |
|199| **Network connectivity detection** – use `connectivity_plus`. |
|200| **HTTPS only** – enforce `https://` scheme. |
|201| **Rate limit handling** – respect `Retry-After` header. |
|202| **Cache responses** – use `dio_cache_interceptor` or similar. |
|203| **Avoid sending large payloads** – compress images before upload. |
|204| **Validate query parameters** – prevent injection. |
|205| **Use `select` with column whitelist** – avoid `*`. |

---

## 1️⃣2️⃣ Notification System
| # | Check |
|---|-------|
|206| **OneSignal App ID stored securely** – not in source code. |
|207| **Player ID sync** – implemented via `OneSignalManager`. |
|208| **Foreground notification handling** – ensure `addForegroundWillDisplayListener` does not block UI. |
|209| **Background channel creation** – verify channel IDs match AndroidManifest. |
|210| **iOS permission request** – ask once, handle denial gracefully. |
|211| **Test notification payloads** – include data for deep linking. |
|212| **Handle notification tap** – navigate to correct screen based on payload. |
|213| **Badge count management** – update `profiles.unread_notifications`. |
|214| **Fallback local notification** – ensure SOS alerts fire when OneSignal fails. |
|215| **Audit duplicate notifications** – dedupe on client side. |

---

## 1️⃣3️⃣ Logging, Crash Reporting & Monitoring
| # | Check |
|---|-------|
|216| **Integrate Sentry or Firebase Crashlytics** – capture uncaught exceptions. |
|217| **Structured logging** – use `logger` package with JSON output. |
|218| **Do not log PII** – mask email/phone in logs. |
|219| **Performance monitoring** – enable `firebase_performance`. |
|220| **Custom events** – track visitor approvals, SOS triggers. |
|221| **Log rotation** – avoid unbounded file growth. |
|222| **Remote config for feature flags** – toggle new features without redeploy. |

---

## 1️⃣4️⃣ Internationalisation & Accessibility
| # | Check |
|---|-------|
|223| **Add `intl` ARB files** – at least English; plan for other locales. |
|224| **RTL support** – test with Arabic/Hebrew. |
|225| **Screen reader labels** – all interactive widgets have `semanticLabel`. |
|226| **Dynamic font scaling** – respects user settings. |
|227| **Contrast checks** – run `flutter_test` accessibility audit. |
|228| **VoiceOver / TalkBack testing** – ensure navigation order. |

---

## 1️⃣5️⃣ Documentation & On‑boarding
| # | Check |
|---|-------|
|229| **README** – includes setup, build, test, deploy steps. |
|230| **Architecture diagram** – high‑level component map. |
|231| **API contract docs** – Supabase tables, RLS policies. |
|232| **Contribution guide** – linting, commit message format. |
|233| **Changelog** – keep `CHANGELOG.md` up‑to‑date. |
|234| **Onboarding script** – `setup.sh` to install dependencies, generate keys. |
|235| **Code comments** – public classes/methods have docstrings. |

---

## 1️⃣6️⃣ Compliance & Legal
| # | Check |
|---|-------|
|236| **GDPR** – provide data‑export and delete endpoints. |
|237| **Privacy policy** – visible in app settings. |
|238| **Terms of Service** – link in onboarding. |
|239| **Cookie consent** – not applicable to mobile but note analytics opt‑out. |
|240| **License headers** – ensure third‑party libraries comply. |

---

# 📊 Summary
- **Total checklist items:** 240 (well over the requested 100). 
- **Priority categories:** Security (71‑90), Performance (91‑110), Testing (131‑145). 
- **Quick wins:**
  1. Run `flutter analyze` & fix all lint errors.
  2. Execute `RESET_HISTORY.sql` to clear stale data.
  3. Add CI pipeline with lint → test → build.
  4. Verify OneSignal Player ID sync (already added).
  5. Enable Crashlytics & Sentry for production monitoring.

---

## 🚀 Next Steps for You
1. **Run the static analysis**:
   ```bash
   flutter clean && flutter pub get
   flutter analyze
   ```
2. **Execute the reset script** in Supabase SQL editor (or via CLI):
   ```sql
   -- copy contents of RESET_HISTORY.sql and run
   ```
3. **Add CI workflow** (GitHub Actions) – see example in `.github/workflows/flutter.yml`.
4. **Run tests** and aim for > 80 % coverage.
5. **Review each checklist item** and mark as ✅ when fixed.
6. **Perform a full release build** (`flutter build appbundle` / `flutter build ipa`).
7. **Deploy to Play Store & App Store** using Fastlane.

Feel free to ask for any specific scripts, CI configs, or deeper dives into any of the items above. Happy polishing! 🎉
