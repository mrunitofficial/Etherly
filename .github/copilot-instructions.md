# Repository Guidelines & AI Context

## 1. Core Engineering Philosophy

* **Think Before Coding & Refactor at the Root**: Step back and analyze the surrounding architecture before making changes. Never create "band-aid" code, duplicate state, or tack secondary variables onto existing logic just to satisfy a new consumer, view, or integration. If a new component or platform target requires data in a specific format, refactor the root domain model (`lib/models/`) or central state service (`lib/services/`) so all targets consume the exact same canonical state representation.

* **Minimal Code & Framework Defaults**: Omit optional parameters whenever Flutter or Material 3 defaults suffice (e.g., standard animation durations, elevations, shape defaults). Do not explicitly pass custom parameters or theme tokens if default widget behavior achieves the desired look.

* **Single Source of Truth (SSOT)**: Never duplicate state, data models, or design constants. App state belongs in dedicated services managed via `Provider` or `ValueNotifier`. Data models must strictly encapsulate their own formatting and fallbacks.

* **Resource Safety**: Always clean up subscriptions, controllers (`StreamSubscription`, `AnimationController`, `TextEditingController`), and timers in `dispose()`.

## 2. Material 3 & Design System Standards

* **Native Material 3**: Rely on Flutter's native M3 widgets (`Card`, `Dialog`, `IconButton`, `NavigationBar`, etc.) and preserve framework defaults without extra configuration unless necessary.

* **Zero Hardcoded Design Values**:

  * ❌ **Prohibited**: Hardcoded colors (`Color(...)`), static padding (`EdgeInsets.all(...)`), fixed border radii (`BorderRadius.circular(...)`), or explicit animation durations (`Duration(...)`).

  * ✅ **Mandatory**: When custom parameters are required, retrieve visual/motion properties strictly via `Theme.of(context)` or custom `ThemeExtension` tokens (`lib/services/theme_data.dart`).

## 3. Strict Single-Line Commenting Standards

* **Single-Line Limitation**: All comments must strictly be a single line. Multi-line comments are prohibited.

* **Public & Major API Documentation**: All major declarations (classes, top-level methods, state classes, public methods) must include a 1-line doc comment using `///`.

* **Deviations & Exceptions**: Any intentional divergence from general project conventions or framework defaults must be explicitly annotated with a 1-line comment using `//`.

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
