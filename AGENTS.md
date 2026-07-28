# Repository Guidelines & AI Context

## 1. Core Engineering Philosophy

* **Think Before Coding & Refactor at the Root**: Step back and analyze the surrounding architecture before making changes. Never create "band-aid" code, duplicate state, or tack secondary variables onto existing logic just to satisfy a new consumer, view, or integration. If a new component or platform target requires data in a specific format, refactor the root domain model (`lib/models/`) or central state service (`lib/services/`) so all targets consume the exact same canonical state representation.

* **Minimal Code & Framework Defaults**: Omit optional parameters whenever Flutter or Material 3 defaults suffice (e.g., standard animation durations, elevations, shape defaults). Do not explicitly pass custom parameters or theme tokens if default widget behavior achieves the desired look.

* **Single Source of Truth (SSOT)**: Never duplicate state, data models, or design constants. App state belongs in dedicated services managed via `Provider` or `ValueNotifier`. Data models must strictly encapsulate their own formatting and fallbacks.

* **Keep It Simple & Future-Proof**: Avoid deeply nested `if`/`else` trees, artificial hardcoded threshold logic, or complex inline conditionals inside UI components. Delegate data resolution and formatting directly to domain models (`lib/models/`) to ensure code remains clean, readable, scalable, and resilient to future schema or database updates.

* **Resource Safety**: Always clean up subscriptions, controllers (`StreamSubscription`, `AnimationController`, `TextEditingController`), and timers in `dispose()`.

## 2. Material 3 & Design System Standards

* **Native Material 3**: Rely on Flutter's native M3 widgets (`Card`, `Dialog`, `IconButton`, `NavigationBar`, etc.) and preserve framework defaults without extra configuration unless necessary.

* **Explicit Semantics & Accessibility**: When custom UI components or widgets do not provide native accessibility support by default (e.g. `GestureDetector`, custom containers, interactive icons without default labels), wrap them in an explicit `Semantics` widget with descriptive labels, buttons, or state flags.

* **Zero Hardcoded Design Values**:

  * ❌ **Prohibited**: Hardcoded colors (`Color(...)`), static padding (`EdgeInsets.all(...)`), fixed border radii (`BorderRadius.circular(...)`), or explicit animation durations (`Duration(...)`).

  * ✅ **Mandatory**: When custom parameters are required, retrieve visual/motion properties strictly via `Theme.of(context)` or custom `ThemeExtension` tokens (`lib/services/theme_data.dart`).

## 3. Strict Code Structure, Ordering & Commenting Standards

* **Single-Line Limitation**: All comments must strictly be a single line. Multi-line comments are prohibited.

* **Public & Major API Documentation**: All major declarations (classes, top-level methods, state classes, public methods) must include a 1-line doc comment using `///`.

* **Deviations & Exceptions**: Any intentional divergence from general project conventions or framework defaults must be explicitly annotated with a 1-line comment using `//`.

* **Absolute Imports & Strict Import Ordering**: All imports must use absolute package paths (`package:etherly/...`) instead of relative paths (`../`). Imports must be strictly grouped and ordered as follows:
  1. External Packages (`dart:` and `package:` third-party dependencies)
  2. Localization (`package:etherly/localization/...`)
  3. Models (`package:etherly/models/...`)
  4. Services & Handlers (`package:etherly/services/...`)
  5. Screens (`package:etherly/screens/...`)
  6. Widgets (`package:etherly/widgets/...`)

* **Standard Member Ordering**: All Dart files and classes must adhere to standard ordering:
  1. Top-Level Directives & Constants
  2. Class Static Fields & Constants (`static const`, `static final`)
  3. Class Instance Fields (public properties $\rightarrow$ private `_` properties)
  4. Constructors (`const`, named, factory)
  5. Lifecycle & State Overrides (`initState()`, `didChangeDependencies()`, `dispose()`)
  6. Widget `build()` Method
  7. Public Methods & Action Handlers
  8. Private Helper Methods

* **Avoid In-Class Helper Methods**: Inline helper functions (e.g. `_buildHeader()`) inside class bodies are discouraged. Prefer keeping logic clean inline within `build()`, or extract reusable UI into a dedicated widget in `lib/widgets/` if substantial or repeated.

* **Professional Automation Messages**: All automated GitHub Actions PR comments, workflow summaries, and release notes must be written in clean, professional tone without emojis.


## 4. UI Consistency & Interactive Experience

* **Visual & Motion Parity**: Similar UI elements (dialogs, bottom sheets, cards, buttons, marquee displays, typography, route transitions) must maintain identical styling and feel across the application.

* **Tactile Feedback**: Integrate standardized haptic feedback (`HapticFeedback.lightImpact()` / `mediumImpact()`) on key user interactions across controls.

* **Modular Widgets**: Keep `build()` methods concise. Extract repeated UI patterns into modular widgets under `lib/widgets/`.

## 5. Interactive Refactoring & Design Protocol (For Coding Sessions)

* **Concise & Scannable Communication**: Keep chat explanations brief, direct, and readable. Avoid verbose preamble, unnecessary theory, or book-length breakdowns. Present options, trade-offs, and questions using concise, high-signal bullet points so the developer can make decisions quickly.

* **Architectural Pause & Option Exploration**: When prompted to design, implement, or explore a new concept, solution, or feature:

  * First explore available design options mentally or in a brief overview.

  * If no single option stands out as the absolute cleanest/best, or if the optimal path requires refactoring existing root models/services (as outlined in Section 1), **stop and ask the user for direction before generating implementation code**.

  * Clearly lay out the options and trade-offs to let the user decide whether to proceed with a root refactor or a specific implementation strategy.

## 6. Code Review Checklist (For Automated PR Reviewers)

* **Architecture & Band-Aid State**: Flag any parallel or secondary state variables created to support new consumers, views, or integrations. Require refactoring the root model or service instead.

* **Minimal Boilerplate**: Flag unnecessary overrides of widget default values (e.g., specifying default animation durations or shapes explicitly when native defaults are already used).

* **Hardcoded Literals**: Flag raw `Color`, `EdgeInsets`, `BorderRadius`, or `Duration` literals in UI files that bypass `Theme.of(context)` or framework defaults.

* **Comment Compliance**: Flag missing 1-line doc comments (`///`) on classes/methods, multi-line comments, or unannotated architectural deviations (`//`).

* **Resource Leaks**: Flag business logic inside UI `build()` methods or undisposed controllers/subscriptions.

## 7. Audio Architecture & Control Routing Standards

* **Single Source of Truth (`AudioPlayerService`)**: `AudioPlayerService` (`lib/services/audio_player_service.dart`) wraps `Just_Audio` and is the single source of truth for all playback state, station management, timers, and live-stream reload logic. All UI widgets, screens, and home screen shortcuts must call `AudioPlayerService` methods strictly (`playMediaItem`, `pause`, `stop`).
* **Platform Media Handler (`AppAudioHandler`)**: `AppAudioHandler` (`lib/services/app_audio_handler.dart`) handles OS-level integrations (`audio_service` for lock screen/headsets/car headunits and `audio_session` for phone interruptions).
* **Control Routing**: All UI widgets and shortcuts call `AudioPlayerService`. `AudioPlayerService` delegates low-level stream playback to `AppAudioHandler` (`_audioHandler.playMediaItem(item)`, `_audioHandler.pause()`, `_audioHandler.stop()`), which directly controls `just_audio`.

## 8. Essential Dart & Flutter Best Practices

* **Null Safety & Immutability**: Write soundly null-safe code; avoid raw `!` forced unwrapping unless non-null is strictly guaranteed. Prefer `const` constructors and immutable structures.

* **Async & Isolate Safety**: Handle `Future`s with `async`/`await` and explicit error handling (`try-catch`). Use `compute()` for heavy CPU operations (e.g., large JSON parsing) to avoid blocking the main UI thread.

* **Explicit Error Logging**: All `catch` blocks must include debug prints wrapped in `if (kDebugMode) print(...)` or `log()`. Silent empty catch blocks (`catch (_) {}`) are prohibited.

* **Performance & List Optimization**: Avoid performing computations or side effects inside `build()`. Use `ListView.builder` or `SliverList` for lazy-loaded long lists.

* **Code Hygiene & Naming**: Use `PascalCase` for classes, `camelCase` for members/variables, and `snake_case` for files. Keep functions short with single responsibilities. Use `dart:developer` `log()` instead of raw `print()`.




