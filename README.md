# Etherly

A modern Dutch radio streaming app built with Flutter, bringing the best of Dutch radio with a modern Material 3 design.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Material Design](https://img.shields.io/badge/Material%20Design%203-757575?style=flat&logo=material-design&logoColor=white)

## What is Etherly?

Etherly is a free, open-source radio streaming application designed specifically (for now) for Dutch radio enthusiasts. The end goal is to provide a seamless listening experience across multiple Android based platforms (Android, Web, Google TV, Fuchsia) with a clean, intuitive interface that follows Material 3 (Material You) design principles (and later Material 3 Expressive when official support is ever coming to Flutter).

Right now the app offers instant access to a curated collection of Dutch radio stations, but the end goal is to provide a very flexible application that can play any radio station lists (including M3U and M3U8) later.

## Key Features

### Core Functionality
- **🎵 High-Quality Streaming**: Crystal-clear audio streaming with automatic reconnection and buffering optimization
- **📱 Multi-Platform Support**: Native apps for Android, Web, (Google TV and Funchsia later)
- **🎨 Material 3 Design**: Beautiful, modern interface with dynamic theming support
- **🔄 Background Playback**: Continue listening while using other apps with full media controls
- **💫 Smooth Transitions**: Polished animations and seamless transitions between screens
- **📺 Cast support**: Cast to your favorite cast-enabled devices

### Organization & Discovery
- **⭐ Favorites**: Save your preferred stations for quick access
- **🔍 Search**: Quickly find stations by name

### Player Features
- **🎛️ Intuitive Controls**: Easy-to-use playback controls with visual feedback
- **📊 Now Playing Info**: Real-time display of current station and metadata
- **⏰ Sleep Timer**: Set automatic playback stop times
- **🎯 Quality Settings**: Adjust streaming quality based on your preferences

### Customization
- **🌓 Theme Modes**: Light, dark, or system-based theme selection
- **🎨 Dynamic color**: Choose between your OS dynamic color or force a readable default color
- **▶️ Auto-start**: Choose a default starting screen and start playing your most recent station automatically

## Why Was Etherly Made?

Etherly was created to address several needs in the Dutch radio streaming landscape:

1. **Accessibility**: Many radio apps are cluttered, ad-heavy, or require subscriptions. Etherly is completely free and open-source, making Dutch radio accessible to everyone.

2. **Modern Experience**: While many radio apps use outdated designs, Etherly embraces modern UI/UX principles with Material 3, providing a fresh and enjoyable user experience.

3. **Cross-Platform**: Dutch listeners use various devices, but few radio apps work seamlessly across all platforms. Etherly runs natively on mobile, web and in the future TV and Fuchsia (e.g. Nest Hub).

4. **Simplicity**: The app focuses on what matters: reliable streaming and easy station discovery, without unnecessary features or complexity.

5. **Community**: As an open-source project, Etherly can be improved and customized by the community, ensuring it evolves with user needs.

# Developing

To start developing Etherly, ensure you have the required tools installed (Flutter, Dart, and an IDE like Android Studio). The codebase follows a clean, single-service architecture with Provider for state management and a focus on Material 3 design. Clone the repository, install dependencies, and use the provided scripts to run or build the app for your target platform. Contributions should follow the established project structure and coding conventions for consistency and maintainability.

## Getting Started

### Prerequisites
- Flutter SDK (3.00 or higher)
- Dart SDK (3.0 or higher)
- For mobile development: Android Studio

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/etherly.git
   cd etherly
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For Android
   flutter run
   
   # For Web
   flutter run -d chrome
   ```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Web
flutter build web --release
```

## Architecture

### Tech Stack
- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: Provider pattern with ChangeNotifier
- **Audio Engine**: just_audio + audio_service packages
- **Storage**: SharedPreferences for local data persistence
- **Design**: Material 3 with custom theming

### Project Structure
```
lib/
├── main.dart               # App entry point
├── models/                 # Data models (Station, Device)
├── screens/                # Main app screens
├── services/               # Business logic (Audio, Chromecast)
├── widgets/                # Reusable UI components
└── localization/           # App translations

assets/
├── stations.json           # Radio station data
├── sounds/                 # UI sound effects
└── icon/                   # App icons
```

### Key Components
- **AudioPlayerService**: Central audio state management
- **MyAudioHandler**: Low-level audio processing and stream handling
- **Radio Player**: Draggable bottom sheet player interface
- **Station Management**: Favorites, recents, and category organization

## Contributing

Enthusiasts with sufficient development knowledge are welcome to contribute. You can:
- Fix bugs or improve performance
- Enhance UI/UX according to the Material 3 guidelines
- Add highly requested new features
- Add support for new platforms, especially help with Goopgle TV and Fuchsia is welcome!
- Improve documentation
- Translate the app

Please feel free to open issues or submit pull requests.

### Adding New Stations
Right now stations are highly currated and only the most common Dutch radio stations are supported. 
Support for M3U and M3U8 files and other sources is planned, but currently not available.
A station looks like this:

```json
{
  "ID": "uniqueStationId",
  "Name": "Station Name",
  "Album": "Station Tagline",
  "StreamMP3": "https://stream-url.example/stream",
  "StreamAAC": "https://stream-url.example/stream",
  "ArtURL": "https://artwork-url.example/logo.png",
  "Category": "Station Name",
  "Tags": ["Pop", "Top40"],
  "rank": null
}
```

## License

This project is open-source. See the LICENSE file for details.

## Disclaimer

- This project was created by an internet radio enthusiast without extensive developing experience
- Because of this this project heavily relies on code generated using Co-Pilot
- I barely know how GitHub, Visual Studio or developing works so forgive me for the lack of common structures and unit-tests
- This project was created out of a need for a modern radio app on Android without ads or subscriptions
- Art, station names and other copyrighted material are not included in this project, but saved seperately for obvious reasons

## Support & Contact

- **Issues**: Report bugs or request features via GitHub Issues
- **Discussions**: Join community discussions in GitHub Discussions