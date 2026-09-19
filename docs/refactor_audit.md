# Hajicare Complete Engineering Audit & Baseline Report

**Date**: September 19, 2026  
**Project**: Hajicare (Flutter Cross-Platform Mobile Application)  
**Auditor**: Senior Flutter Software Architect, Android Build Engineer & Security Reviewer  
**Branch**: `refactor/hajicare-clean-code`  
**Base Commit**: `9b8dbfcf752c0dfb62faad4e1eb84ef062b9fef1`  

---

## 1. Executive Summary & Toolchain Inspection

Prior documentation suggested the project environment was Flutter 3 / Dart 3.11. The actual verified toolchain inspection revealed:

| Component | Actual Installed Version | Target / Configuration |
| :--- | :--- | :--- |
| **Flutter SDK** | **3.47.2** (Channel stable) | Supports Built-in Kotlin (`android.builtInKotlin=true`) |
| **Dart SDK** | **3.13.2** | Modern null safety & records |
| **Java / JDK** | **OpenJDK 17.0.20.1+1** (Temurin 64-Bit) | Fully compatible with Gradle 9+ and AGP 9+ |
| **Android SDK** | **36.0.0** (Platforms: android-37.0) | Emulator: API 37 |
| **Android Gradle Plugin (AGP)** | **9.0.1** | Configured in `android/settings.gradle.kts` |
| **Gradle Wrapper** | **9.1.0-all** | `gradle/wrapper/gradle-wrapper.properties` |
| **Kotlin Gradle Plugin (KGP)** | **2.3.20** | Applied via `id("kotlin-android")` in `app/build.gradle.kts` |
| **compileSdk / targetSdk / minSdk** | `compileSdk = 36`, `targetSdk = flutter.targetSdkVersion`, `minSdk = flutter.minSdkVersion` | Enforced consistently across subprojects |

---

## 2. Baseline Verification Findings

The baseline commands were run prior to modifying any source code:

### 2.1 Static Analysis (`flutter analyze`)
* **Result**: `No issues found!` (0 errors, 0 warnings, 0 infos).

### 2.2 Code Formatting (`dart format`)
* **Result**: 158 files formatted (0 changed).

### 2.3 Automated Fixes (`dart fix --dry-run`)
* **Result**: Nothing to fix.

### 2.4 Test Suite (`flutter test`)
* **Total Tests Executed**: 137
* **Passed**: 116
* **Failed**: 21
* **Root Cause Breakdown**:
  1. **20 Failures**: Eager instantiation of `FirebaseFirestore.instance` inside `RoomService` constructor (`final RoomService _roomService = RoomService();` inside `HajiCareController`). When unit and widget tests instantiate controllers or services in isolation without a mocked Firebase App, `MethodChannelFirebase.app` throws:
     `[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()`.
  2. **1 Failure**: `test/room_session_persistence_test.dart:71` failed expectation (`Expected: '/join_room', Actual: '/dashboard_jamaah'`). In `AppStartupController.resolveUserRoleDestination`, the fallback logic unconditionally returned `AppRoutes.dashboardJamaah` instead of verifying if an active room ID exists.

### 2.5 Android Build (`flutter build apk --debug`)
* **Build Status**: Built successfully in 49.8s (`build\app\outputs\flutter-apk\app-debug.apk`).
* **Active Diagnostics & Build Warnings**:
  ```text
  WARNING: Your Android app project: app located at: C:\Users\hafiz\hajicare\android\app\build.gradle.kts
  applies the Kotlin Gradle Plugin, which will cause build failures in future versions of Flutter.
  Please migrate your app to Built-in Kotlin using this guide: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers

  WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP):
  device_info_plus, firebase_auth, firebase_core, flutter_tts, geocoding_android, google_mlkit_commons,
  google_mlkit_translation, package_info_plus, rive_native, shared_preferences_android, speech_to_text,
  ultralytics_yolo, url_launcher_android, wakelock_plus
  ```

---

## 3. Dependency & Built-in Kotlin Plugin Inventory

The 14 plugins flagged by the Flutter build tool were audited individually to determine their dependency source, resolved version, and Built-in Kotlin status:

| Plugin | Source / Origin | Resolved Version | Latest Compatible | Built-in Kotlin Migration Status | Action Planned |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **device_info_plus** | Transitive (via `vibration`) | 11.5.0 | 13.2.0 | Supported in 13.2.0+ (AGP 9+ DSL migration) | Upgrade `vibration` / resolution to 13.2.0 |
| **package_info_plus** | Transitive (via `wakelock_plus`) | 9.0.1 | 10.2.1 | Supported in 10.2.1+ | Upgrade dependency tree |
| **shared_preferences_android** | Direct (`shared_preferences: ^2.5.5`) | 2.4.23 | 2.4.28 | Migrated | Update lockfile / version |
| **url_launcher_android** | Transitive (via `ultralytics_yolo`) | 6.3.30 | 6.3.33 | Migrated | Update lockfile |
| **geocoding_android** | Direct (`geocoding: ^5.0.0`) | 5.0.2 | 5.1.0 | Migrated | Upgrade plugin |
| **google_mlkit_translation** | Direct (`google_mlkit_translation: 0.14.0`) | 0.14.0 | 0.15.1 | Partial / updated DSL | Upgrade to 0.15.1 and verify |
| **google_mlkit_commons** | Transitive (via `google_mlkit_translation`) | 0.12.0 | 0.13.0 | Partial / updated DSL | Upgraded with translation |
| **speech_to_text** | Direct (`speech_to_text: 7.4.0`) | 7.4.0 | 7.5.0 | Migrated | Upgrade to 7.5.0 |
| **firebase_core** | Direct (`firebase_core: ^4.14.0`) | 4.14.0 | 4.15.0 | Active upstream migration | Upgrade to 4.15.0 |
| **firebase_auth** | Direct (`firebase_auth: ^6.6.1`) | 6.6.1 | 6.7.0 | Active upstream migration | Upgrade to 6.7.0 |
| **vibration** | Direct (`vibration: ^2.0.0`) | 2.1.0 | 3.2.1 | Migrated in 3.x series | Upgrade to 3.2.1 |
| **flutter_tts** | Direct (`flutter_tts: ^4.2.2`) | 4.2.5 | 4.2.5 | Pending upstream release | Retain & document |
| **ultralytics_yolo** | Direct (`ultralytics_yolo: ^0.6.14`) | 0.6.14 | 0.6.14 | Upstream plugin applies KGP | Retain & document |
| **rive_native** | Transitive (`awesome_dialog: 3.3.0` -> `rive`) | 0.1.11 | 0.1.11 | Upstream plugin applies KGP | Retain & document |

---

## 4. Current Architecture & Clean Code Audit

### 4.1 Architecture Overview
The application is organized under a modular feature-oriented layout:
```text
lib/
├── core/
│   ├── config/          # App runtime configuration (ORS API key, etc.)
│   ├── constants/       # Asset paths, Carto basemap URLs, shared keys
│   ├── locales/         # Multi-language translation dictionaries
│   ├── models/          # Core domain models
│   ├── routes/          # Central GetX route table & bindings
│   ├── services/        # Platform & networking adapters
│   ├── state/           # Global SSOT controllers (HajiCareController, AppStartupController)
│   ├── theme/           # AppTheme light & dark color schemes
│   ├── utils/           # Helper utilities
│   └── widgets/         # Shared presentation widgets
├── features/
│   ├── auth/            # Login, registration, reset password
│   ├── communication/   # Arabic-Indonesian gesture phrases dialog
│   ├── dashboard/       # Jamaah & Pendamping dashboards
│   ├── map/             # Interactive map, real OSM POIs, routing, search
│   ├── money/           # Smart multi-pass SAR bill detector
│   ├── notification/    # Push notifications & broadcast alerts
│   ├── onboarding/      # First-launch onboarding carousel
│   ├── prayer/          # Prayer times, compass Qibla, countdown
│   ├── profile/         # User profile, health metrics, emergency contact
│   ├── room/            # Room management, live member tracking, SOS
│   ├── smartband/       # BLE integration for vital monitoring
│   ├── sos/             # Emergency SOS alert broadcast
│   ├── splash/          # App bootstrap & auth state resolver
│   └── translator/      # ML Kit offline Arabic-Indonesian translator
├── firebase_options.dart# Firebase client configuration
└── main.dart            # Application bootstrap & dependency registration
```

### 4.2 Code Smells & Refactor Opportunities
1. **Eager Platform Initialization**:
   - `RoomService` eagerly assigns `_firestore = firestore ?? FirebaseFirestore.instance;` in its initializer list.
   - `HajiCareController` eagerly creates `_roomService = RoomService();` as a field.
   - **Fix**: Make `_firestore` a lazy getter (`FirebaseFirestore get firestore => _customFirestore ?? FirebaseFirestore.instance;`) or lazy initialization. This decouples unit/widget tests from live Firebase bindings without altering runtime production behavior.
2. **God Controller Responsibilities**:
   - `HajiCareController` (~1,035 lines) manages room membership, GPS broadcast, SOS alerts, active room state, and profile caching.
   - Sub-services (`RoomService`, `LocationService`) are already separated, but controller logic can be cleaned up into cohesive, well-documented helper methods.
3. **Stream Subscription Lifecycles**:
   - Controllers listening to GPS streams, compass events, and BLE characteristics must ensure deterministic cancellation in `onClose()`.
4. **Hardcoded API Keys in Source Code**:
   - `AppConstants.cartoApiKey`: hardcoded in `lib/core/constants/app_constants.dart`.
   - **Fix**: Integrate with `String.fromEnvironment('CARTO_API_KEY', defaultValue: ...)` so production keys can be injected securely via build configuration while maintaining fallback for development.

---

## 5. Security Audit Findings

1. **API Credentials**:
   - `AppConfig.orsApiKey` correctly uses `String.fromEnvironment('ORS_API_KEY', defaultValue: '')` with fallback to public OSRM.
   - `AppConstants.cartoApiKey` is currently hardcoded in source. It will be refactored to support secure environment injection.
   - `firebase_options.dart` contains standard public web/mobile client IDs (no service account or private keys).
2. **Network Security**:
   - Zero unencrypted HTTP (`http://`) endpoints in `lib/`. All network requests use TLS (`https://`).
3. **Sensitive Logging**:
   - Zero raw `print(` statements in `lib/`.
   - `debugPrint` statements do not log passwords or auth tokens.
4. **Permissions**:
   - Permissions in `AndroidManifest.xml` (Location, Camera, Bluetooth, Microphone) correspond directly to core app features (Map, SAR detection, BLE Smartband, Speech-to-Text).

---

## 6. Planned Migration Strategy

1. **Phase 1: Baseline Test Repair**:
   - Implement lazy `firestore` getter in `RoomService` to eliminate 20 test failures caused by `[core/no-app]`.
   - Fix `AppStartupController.resolveUserRoleDestination` fallback to check for `effectiveCachedRoom` before routing to dashboard vs. join room.
   - Verify `flutter test` achieves 100% pass rate.
2. **Phase 2: Dependency Upgrades**:
   - Update `pubspec.yaml` to upgrade compatible Built-in Kotlin packages (`device_info_plus`, `package_info_plus`, `shared_preferences`, `vibration`, `speech_to_text`, `google_mlkit_translation`, `geocoding`).
   - Run `flutter pub get` and verify dependency tree.
3. **Phase 3: Android App Built-in Kotlin Migration**:
   - In `android/app/build.gradle.kts`: remove legacy `id("kotlin-android")`.
   - In `android/settings.gradle.kts`: remove `id("org.jetbrains.kotlin.android")` application if built-in Kotlin is active.
   - In `android/gradle.properties`: update `android.builtInKotlin=true`.
   - Test `flutter build apk --debug`.
4. **Phase 4: Clean Code & Architecture Polishing**:
   - Enhance security on `AppConstants.cartoApiKey`.
   - Ensure clean resource disposal and async safety across all controllers.
   - Verify zero warnings across `flutter analyze` and `flutter test`.
5. **Phase 5: Release Build Validation & Final Report**:
   - Run `flutter build apk --release`.
   - Update `docs/kotlin_migration_report.md` and `docs/refactor_audit.md`.
