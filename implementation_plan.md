# Goal Description

The objective is to thoroughly update, refactor and clean the radio player logic implementation to greatly improve maintainability and adherence to Dart/Flutter best practices. 
Currently, `audio_service` takes a central role in both playback execution and UI interaction, while in modern setups `just_audio` handles media natively and UI binds to it, using `audio_service` purely to hook into OS-level media notifications and controls (like Android lock screen or Bluetooth controls).

The key changes entail:
1. **Separation of Concerns:** Moving `MyAudioHandler` and `AudioPlayerService` into two separate files (`my_audio_handler.dart` and `audio_player_service.dart`).
2. **Inversion of Control:** Let `AudioPlayerService` manage and expose `just_audio`'s `AudioPlayer` directly. Redundant wrapper functions for standard playback commands (play, pause, stop, etc.) will be eliminated where possible, allowing the UI to interact directly with the player's streams or streamlined getters.
3. **Dead Code Cleanup:** Remove unused or redundant properties and simplified checks (like manual processing states if `just_audio`'s internal streams are adequate).
4. **Best Practices:** Use cleaner syntax, reduce boilerplate, remove unnecessary custom streaming logics if `just_audio` handles them natively (e.g. `icyMetadataStream`), and introduce Material 3 token usage if UI updates are needed alongside this.

## User Review Required

> [!IMPORTANT]
> The architectural shift means that the UI will now mostly interact with streams directly coming from `just_audio` via `AudioPlayerService`, instead of manually transformed streams through `audio_service`. This guarantees less latency and fewer synchronization bugs between the audio engine and the UI elements, but represents a foundational change in how state is read.

> [!WARNING]
> Because we are switching the "source of truth" to `just_audio`, any custom UI widgets (like `small_player.dart`, `full_player.dart`, etc.) will be updated to consume `player.playingStream`, `player.playbackEventStream`, etc., directly or via refined service getters. Are there any custom behaviors relying specifically on `audio_service`'s `PlaybackState` in the UI that I should be mindful of?

## Proposed Changes

---

### Audio Framework

Refactoring and splitting the main logic file into two distinct, focused files.

#### [NEW] `lib/services/my_audio_handler.dart`
- Will contain only the `MyAudioHandler` extending `BaseAudioHandler`.
- Responsibilities: Listen to the provided `AudioPlayer` instance to emit `PlaybackState` and `MediaItem` updates for OS notifications. Receive intents from the OS (Bluetooth clicks, Lock Screen interactions) and trigger the corresponding methods on `AudioPlayer` or `AudioPlayerService`.

#### [MODIFY] `lib/services/audio_player_service.dart` 
*(Was `radio_player_service.dart`)*
- Will contain `AudioPlayerService`.
- Will instantiate and hold the `AudioPlayer`.
- Features like `autoPlay`, `stations` list, `favoriteStationIds`, `recentStationIds` will remain here.
- Double-functions like `play()`, `pause()`, `stop()` will just delegate directly to the player, or be replaced by allowing the UI to call `service.player.play()`. We will keep minimal wrapper methods where multiple subsystems (like `ChromeCastService` + `AudioPlayer`) need coordinating.

#### [DELETE] `lib/services/radio_player_service.dart`
- File will be removed and imports across the codebase updated.

---

### UI Components & Service Imports

Since the file has been renamed and potentially part of its API simplified, several widget files will require updates to their imports and state interactions.

#### [MODIFY] Home, Search, Station, and Radio Player UI Screens
- e.g. `lib/screens/home_screen.dart`, `lib/widgets/full_player.dart`, `lib/widgets/small_player.dart`, `lib/widgets/play_button.dart`, etc.
- **Change:** Rename import to `audio_player_service.dart`.
- **Change:** Refactor to listen to `just_audio` player streams where previously listening to `AudioPlayerService.playbackState` manually if needed. 

## Open Questions

> [!NOTE]
> 1. Should I retain the `AudioPlayerService.playbackState` getter to mimic the old behaviour to lower the rewrite scope on the UI, or migrate the UI components directly to `audioPlayerService.player.playingStream` and `processingStateStream` for better reactivity? By migrating, we use what `just_audio` offers out of the box.
> 2. ChromeCast support currently intercepts `play()`, `pause()`, `stop()`. Is it acceptable for `AudioPlayerService` to keep simple wrapper methods (e.g. `Future<void> play()`) so it can divert the command to Google Cast if active, rather than the UI interacting with the `AudioPlayer` completely untouched?

## Verification Plan

### Automated Tests
- Syntax verification via `flutter analyze`.
- Compilation verification to ensure no broken imports exist using `flutter build core`.

### Manual Verification
- Testing normal playback, toggling standard play/pause, validating whether ICY metadata populates successfully on the screen, and seeing if skipping tracks works natively.
- Observing standard Android media notifications update and control appropriately now that their logic is inverted.
