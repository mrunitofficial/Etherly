# Etherly - AI Coding Instructions

## Project Overview
Etherly is a Dutch radio streaming app built with Flutter, featuring Material 3 design, multi-platform support, and sophisticated audio streaming capabilities. The app provides a clean interface for browsing and playing Dutch radio stations with favorites, recents, and category-based organization.

## Architecture Patterns

### Core Structure
- **Single-service architecture**: `AudioPlayerService` is the central hub using Provider pattern for state management
- **Audio service integration**: Uses `audio_service` package for background playback with OS media controls
- **Responsive design**: Widget structure organized by screen size (`small_screen/`, `medium_screen/`, `large_screen/`)
- **Asset-driven content**: Radio stations loaded from `assets/stations.json` with GitHub-hosted artwork

### State Management
```dart
// Provider pattern with ChangeNotifier
ChangeNotifierProvider(
  create: (context) => AudioPlayerService(audioHandler),
  child: const MyApp(),
)

// Global theme state using ValueNotifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
```

### Audio Architecture
- **Two-layer audio system**: `MyAudioHandler` (low-level) + `AudioPlayerService` (UI-facing)
- **Reconnection logic**: Automatic stream reconnection with 30s buffering timeout + 10s retry intervals
- **Stream communication**: Custom event system for UI notifications (e.g., `ReconnectingEvent`)

## Key Components

### Radio Player (`lib/widgets/small_screen/radio_player.dart`)
- **Draggable bottom sheet**: Seamless transition between mini/full player modes
- **Dynamic sizing**: Uses `DraggableScrollableSheet` with calculated size ratios
- **Dual UI states**: Mini player (opacity-based) and full player with smooth transitions
- **Autoplay countdown**: Timer-based with cancellation capabilities

### Station Management
- **Station model**: `lib/models/station.dart` with favorites support and JSON serialization
- **Category-based organization**: Dynamic category display with minimum 8 categories
- **Popular stations**: Hardcoded list in `home_screen.dart` for featured content
- **Persistence**: SharedPreferences for favorites, recents, last played, and settings

### UI Patterns
- **Consistent theming**: Material 3 with dynamic color support (currently disabled)
- **Custom components**: `StationArt`, `StationCardItem`, `StationGridItem` for reusable station display
- **Error handling**: Safe URL parsing, graceful image loading with fallbacks
- **Navigation**: Bottom navigation with settings in app bar

## Development Conventions

### Code Style
- **No comments**: Do not add comments when generating code. Code should be self-documenting with clear variable and function names.
- **Clean code**: Focus on readable, idiomatic Dart/Flutter code without explanatory comments.

```yaml
# analysis_options.yaml - Relaxed linting
avoid_print: false
prefer_const_constructors: false
prefer_const_literals_to_create_immutables: false
```

### Asset Management
- **Station data**: `assets/stations.json` with standardized schema (ID, Name, Album, StreamURL, ArtURL, Category)
- **Station artwork**: External GitHub repository (`mrunitofficial/EtherlyArt`)
- **App icons**: Adaptive icons with Material You theming support

### Dependencies
- **Audio**: `just_audio` + `audio_service` + `audio_session` for comprehensive audio handling
- **State**: `provider` for reactive state management
- **Storage**: `shared_preferences` for user preferences and app state
- **UI**: `dynamic_color`, `cached_network_image` for enhanced Material 3 experience

## Critical Implementation Details

### Audio Service Integration
```dart
// Initialize audio service in main()
final audioHandler = await initAudioService();

// Stream URL handling with reconnection
await _player.setAudioSource(AudioSource.uri(sourceUrl, tag: mediaItem));
```

### Theme System
- Global `themeNotifier` for app-wide theme changes
- Settings screen directly modifies theme state
- Dynamic color support prepared but disabled (`_useDynamicColor = false`)

### Data Flow
1. Stations loaded from `assets/stations.json` on app start
2. User preferences loaded from `SharedPreferences`
3. Audio handler initialized with station list
4. UI components consume state via Provider pattern
5. User interactions flow through `AudioPlayerService` to `MyAudioHandler`

## Common Tasks

### Adding New Features
- Extend `AudioPlayerService` for business logic
- Create widgets in appropriate screen size directory
- Update `Station` model if new properties needed
- Add settings to `SharedPreferences` management

### Debugging Audio Issues
- Check `MyAudioHandler._handleProcessingState()` for state transitions
- Monitor reconnection logic via debug prints
- Verify stream URLs in `assets/stations.json`
- Test with different network conditions for buffering behavior

### UI Modifications
- Follow Material 3 design system patterns
- Use `Theme.of(context).colorScheme` for consistent colors
- Implement responsive design across screen sizes
- Test drag interactions in radio player component

This architecture prioritizes audio reliability, smooth user experience, and maintainable Dutch radio content management.