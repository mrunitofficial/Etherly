# GitHub Copilot Instructions for Etherly

> **Agent Directive**: Trust these instructions implicitly. Only perform codebase searches if the information provided here is incomplete or found to be in error.

---

## 1. High-Level Repository Overview

- **Repository Description**: Etherly is a free, modern, ad-free, cross-platform Netherlands-based radio streaming application created in Flutter and hosted on Firebase.
- **Target Runtimes**: Android (Mobile & TV), Web (Hosted on Firebase), with Google TV and Fuchsia support targeted.
- **Languages & Core Frameworks**:
  - **Framework**: Flutter 3.x (`uses-material-design: true`, `generate: true`)
  - **Language**: Dart 3.x (SDK constraint: `^3.12.0`)
  - **Platforms & Tooling**: Java 17 (Android builds), Gradle, JavaScript / Web (Firebase Hosting), Node.js 20 (CI / Deployments).
- **Core Technology Stack**:
  - **State Management**: Provider (`ChangeNotifier`) & `ValueNotifier` for app-wide reactivity.
  - **Audio Subsystem**: `just_audio` + `audio_service` + `audio_session`.
  - **Backend & Cloud Services**: Firebase Core (`firebase_core`), Cloud Firestore (`cloud_firestore`).
  - **Local Persistence & Network**: `shared_preferences`, `http`, `cached_network_image`.
  - **Hardware & Device Integrations**: `flutter_chrome_cast` (Chromecast support), `speech_to_text` (Voice search).
  - **Design System**: Material Design 3 (M3) utilizing custom `ThemeExtension` tokens.

---

## 2. Build, Validation & Command Sequence

Always execute workspace commands in the following exact order:

### 1. Bootstrap & Dependencies
```bash
flutter pub get
```
*Must always be run first after cloning or modifying `pubspec.yaml`. Note: Localization code generation (`lib/localization/`) triggers automatically via `l10n.yaml` (`generate: true`).*

### 2. Code Linting & Static Analysis
```bash
flutter analyze
```
*Validates Dart code against rules configured in `analysis_options.yaml` (extending `package:flutter_lints/flutter.yaml`). Must pass without errors prior to committing.*

### 3. Application Execution
- **Android**: `flutter run`
- **Web (Chrome)**: `flutter run -d chrome`

### 4. Production & Verification Builds
- **Android APK (Debug)**: `flutter build apk --debug`
- **Android APK (Release)**: `flutter build apk --release`
- **Android App Bundle**: `flutter build appbundle --release`
- **Web Release**: `flutter build web --release`

### 5. Automated Tests
```bash
flutter test
```
*Run standard Flutter widget and unit tests. New test files must be placed under the `/test` directory following standard Flutter package structure.*

### Build Failure Preconditions & Mitigation Steps
- **Java Runtime**: Android Gradle builds require **Java 17** (Temurin distribution in CI). Lower or higher unsupported Java versions will cause build failures.
- **Android Signing Keystore**: Release APK/Bundle builds require keystore environment variables (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`) and `android/app/upload-keystore.jks`. Use `flutter build apk --debug` for local build validation without release secrets.
- **Web Multi-Tab Firestore**: Web persistence requires `WebPersistentMultipleTabManager()` on `FirebaseFirestore.instance.settings` in `lib/main.dart` to prevent web tab lock deadlocks.

---

## 3. Project Architecture & Layout

### Codebase Organization (`lib/`)
```
lib/
├── main.dart               # Entry point, Firebase & service initializations, Theme & Locale providers
├── firebase_options.dart   # Generated Firebase configuration options
├── models/                 # Strongly-typed data models
│   ├── station.dart        # Radio station representation & metadata
│   ├── device.dart         # Output device & screen type helpers (Android TV detection)
│   ├── song.dart           # ICY track metadata model
│   ├── music_app.dart      # External music player integration model
│   └── country.dart        # Country classification model
├── services/               # Business logic, state containers & system services
│   ├── audio_player_service.dart   # Primary audio playback manager & Provider
│   ├── my_audio_handler.dart       # AudioService background notification handler
│   ├── chrome_cast_service.dart    # Google Cast device discovery & stream sync manager
│   ├── history_service.dart        # Played station history persistence
│   ├── shortcut_service.dart       # Native quick actions & platform app shortcuts
│   ├── music_app_service.dart      # Integration helper for external music apps
│   └── theme_data.dart             # M3 design system tokens & ThemeExtensions
├── screens/                # Top-level view screens
│   ├── app_screen.dart             # App shell scaffold with NavigationBar / NavigationRail
│   ├── home_screen.dart            # Main overview & featured station categories
│   ├── stations_screen.dart        # All stations grid/list screen
│   ├── favorites_screen.dart       # User favorited stations screen
│   ├── history_screen.dart         # Played station history screen
│   ├── search_screen.dart          # Text and speech voice search screen
│   ├── settings_screen.dart        # Preferences (Theme, Quality, Autoplay, Language)
│   └── radio_player.dart           # Expanded radio player screen
├── widgets/                # Reusable, modular UI components
│   ├── full_player.dart / small_player.dart   # Audio player UI representations
│   ├── play_button.dart / station_art.dart    # Standardized UI controls & artwork
│   ├── station_card_item.dart / grid_item.dart # Station item views
│   └── marquee_text.dart / icy_text_display.dart # Dynamic metadata displays
└── l10n/                   # ARB localization template files (`app_en.arb`, `app_nl.arb`)
```

### GitHub CI Workflows & PR Pipeline
- **Branch Flow**: `feature/*` -> `develop` -> `preview` -> `main`.
- **Workflow Configurations** (`.github/workflows/`):
  1. `pull-request-verification.yml`: Validates PR source/target branch constraints, auto-generates versioned PR titles (`v<version>`), and runs `flutter analyze`.
  2. `deploy-preview.yml`: Triggers on push to `preview`. Runs `flutter analyze`, compiles Android Debug APK and Web release, deploys web app to Firebase Hosting (`preview` channel), and posts artifact download links to the PR.
  3. `deploy-production.yml`: Triggers on push to `main`. Deploys production build.

---

## 4. Code Quality, Single Source of Truth & Material 3 Best Practices

### Code Quality & Single Source of Truth (SSOT)
- **Maintain a Single Source of Truth**: Never duplicate station lists, player state, colors, or constant values across multiple components. Store app state in dedicated services (`AudioPlayerService`, `HistoryService`) and retrieve models directly.
- **Code Minimization & Readability**: Keep widget code modular, clean, and expandable. Avoid bloated, deeply nested inline widget trees—extract repeated UI elements into dedicated components under `lib/widgets/`.
- **State Management Discipline**: State must be managed via `Provider` (`ChangeNotifier`) or `ValueNotifier`. Do not call global `setState()` high up in the tree when targeted reactive rebuilds can be used.
- **Resource & Lifecycle Safety**: Always clean up resources (`StreamSubscription`, `AnimationController`, `TextEditingController`, `Timer`) in the `dispose()` lifecycle method.

### Material 3 Design System & Theme Standards
- **Strict Material 3 Adherence**: The codebase enforces Material 3 design principles via `ThemeData` and custom `ThemeExtension` tokens defined in `lib/services/theme_data.dart`.
- **NEVER HARDCODE DESIGN VALUES**:
  - ❌ **Prohibited**: Hardcoded colors (`Color(0xFF123456)`), static padding (`EdgeInsets.all(16.0)`), fixed border radii (`BorderRadius.circular(12)`), explicit animation durations (`Duration(milliseconds: 300)`), or raw size dimensions.
  - ✅ **Mandatory**: Access design tokens exclusively through `Theme.of(context)` and `Theme.of(context).extension<T>()`.

#### Theme Extension Token Usage Reference (`lib/services/theme_data.dart`)
- **Colors**: `Theme.of(context).colorScheme` (`primary`, `surfaceContainer`, `onSurface`, `secondaryContainer`, etc.)
- **Spacing**: `Theme.of(context).extension<Spacing>()!`
  - `extraExtraSmall` (2.0), `extraSmall` (4.0), `small` (8.0), `medium` (16.0), `large` (24.0), `extraLarge` (32.0).
- **Shapes (Border Radius)**: `Theme.of(context).extension<Shapes>()!`
  - `extraSmall` (4px), `small` (8px), `medium` (12px), `large` (16px), `largeIncreased` (20px), `extraLarge` (28px), `extraLargeIncreased` (32px), `extraExtraLarge` (48px).
- **Animation Durations / Speed**: `Theme.of(context).extension<Speed>()!`
  - `short1` (50ms) to `short4` (200ms), `medium1` (250ms) to `medium4` (400ms), `long1` (450ms) to `long4` (600ms), `extraLong1` (700ms) to `extraLong4` (1000ms).
- **Sizes**: `Theme.of(context).extension<Sizes>()!`
  - `extraSmall` (16.0), `small` (40.0), `normal` (56.0), `medium` (80.0), `large` (96.0), `largeIncreased` (120.0), `extraLarge` (136.0), `extraLargeIncreased` (160.0).

### Visual & Interactive Consistency
- **Dialog Consistency**: Every dialog must use M3 `DialogThemeData`, standard `Spacing` margins, unified button types (`TextButton`, `FilledButton`, `TonalButton`), and localized text (`AppLocalizations.of(context)!`).
- **Tactile Feedback**: Use `HapticFeedback.lightImpact()` or `HapticFeedback.mediumImpact()` consistently across interactive controls (station selections, play/pause toggles, favorite actions).
- **Widget Uniformity**: Component layouts (`StationCardItem`, `StationGridItem`, `SmallPlayer`, `FullPlayer`) must share common design tokens and building blocks (`StationArt`, `PlayButton`, `MarqueeText`) to maintain a cohesive visual identity across mobile and web viewports.
