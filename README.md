# Etherly

A modern Netherlands-based radio streaming app built with Flutter.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Material Design](https://img.shields.io/badge/Material%20Design%203-757575?style=flat&logo=material-design&logoColor=white)

## What is Etherly?

Etherly is a free, open-source radio streaming application designed specifically for radio enthusiasts who like an experience that "just works". The end goal is to provide a seamless listening experience across multiple Android based platforms (Android, Web, Google TV, Fuchsia) with a clean, intuitive interface that follows Material 3 design principles (and later Material 3 Expressive when official support is ever coming to Flutter).

Right now the app offers instant access to a curated collection of Dutch radio stations, but the end goal is to provide a very flexible application that can play any radio station lists (including M3U and M3U8) at some point. Etherly is hosted on Firebase.

## Key Features

### Core Functionality
- Multi-Platform Support: Native apps for Android and Web (Google TV and Funchsia coming later).
- Background Playback: Continue listening while using other apps with full media controls.
- Search and find stations: use the (voice)search function to find your favorite stations easily.
- Set and sort favorites: set your own favorites stations and access them easily.
- Cast support: Cast to your favorite google-cast-enabled devices.
- Extensive settings: Autoplay, theme, preffered stream quality, etc..

### Player Features
- Now Playing Info: Real-time display of current station and (ICY) metadata.
- Sleep Timer: Set automatic playback stop times.
- Quality Settings: Adjust streaming quality based on your preferences (AAC, MP3).

### Design
- Simple and easy to understand layout that follows all the official Material 3 principles.
- Dynamic color: Choose between your OS dynamic color or force a readable default color.
- Theme Modes: Light, dark, or system-based theme selection.

## Why Was Etherly Made?

Etherly was created to address several needs in the radio streaming app landscape. Many radio apps are ad-heavy or require subscriptions, while most free alternatives offer outdated desings. Etherly embraces Material 3 to its core, providing a fresh and enjoyable user experience. Etherly is designed in FLutter to be cross-platform on all Android and web based devices including Google TV and Nest Hub (Fuchsia). Etherly focuses on what matters: reliable streaming and easy listening. There is no room for videos, short-form content or podcasts.

## Developing

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

### Tech Stack
- Framework: Flutter 3.x
- Language: Dart 3.x
- State Management: Provider pattern with ChangeNotifier
- Audio Engine: just_audio + audio_service packages
- Local storage: SharedPreferences
- Cloud storage: Firebase
- Design: Material 3 to the core

### Project Structure
```
lib/
├── main.dart               # App entry point
├── models/                 # Data models (Station, Device)
├── screens/                # Main app screens
├── services/               # Business logic (Audio, Chromecast)
├── widgets/                # UI components
└── localization/           # App translations
```

## Adding New Stations
Right now stations are highly currated and only the most common Dutch radio stations are supported. 
Support for M3U and M3U8 files and other sources is planned, but currently not available. 
The option to suggest stations using the official website might come in the future.

## License
This project is open-source. See the LICENSE file for details.

## Disclaimer
- This project was created by an internet radio enthusiast without extensive developing experience
- This project relies on code partly generated using modern llm-based tools
- This project was created out of a need for a modern radio app on Android without ads or subscriptions

## Support & Contact
Report bugs or request features via GitHub issues.