import 'dart:ui';
import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'localization/app_localizations.dart';
import 'services/audio_player_service.dart';
import 'services/chrome_cast_service.dart';
import 'services/history_service.dart';
import 'services/theme_data.dart';
import 'screens/app_screen.dart';
import 'models/device.dart';

/// Entry point of the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if device is Android TV
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      const channel = MethodChannel('com.mrunit.etherly/device_info');
      ScreenType.isTv = await channel.invokeMethod<bool>('isTv') ?? false;
    } catch (e) {
      debugPrint('Failed to check isTv: $e');
    }
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization issue: $e');
  }

  // Initialize HistoryService
  await HistoryService().init();

  try {
    // Enable Firestore persistence for web (Firebase).
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        webPersistentTabManager: WebPersistentMultipleTabManager(),
      );
    }
  } catch (e) {
    debugPrint('Firebase feature initialization failed: $e');
  }
  // Configure image cache.
  PaintingBinding.instance.imageCache.maximumSize = 4000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1000 << 20;

  // Load preferences.
  final prefs = await SharedPreferences.getInstance();
  final themeString = prefs.getString('theme');
  final theme =
      ThemeMode.values.asNameMap()[themeString?.replaceFirst(
        'ThemeMode.',
        '',
      )] ??
      ThemeMode.system;
  themeNotifier.value = theme;
  final forceDefaultColor = prefs.getBool('forceDefaultColor') ?? false;
  dynamicColorNotifier.value = !forceDefaultColor;
  final startingTab = prefs.getInt('startingTab') ?? 0;
  final language = prefs.getString('language') ?? 'system';
  languageNotifier.value = language;

  // Run the app.
  runApp(MyApp(startingTab: startingTab));
}

/// The root widget of the application.
class MyApp extends StatefulWidget {
  final int startingTab;

  const MyApp({super.key, required this.startingTab});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AudioPlayerService? _audioPlayerService;
  ChromeCastService? _chromeCastService;
  bool _localizationsLoaded = false;
  bool _showApp = false;
  bool _initializingAudio = false;

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChange);
    _initAudioService();
    Future.delayed(const Duration(seconds: 3), _triggerFadeIn);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    setState(() {});
  }

  void _triggerFadeIn() {
    if (!_showApp) {
      Future.delayed(const Duration(milliseconds: 450), () {
        setState(() {
          _showApp = true;
        });
      });
    }
  }

  Future<void> _initAudioService() async {
    if (_localizationsLoaded || _initializingAudio) return;
    _initializingAudio = true;
    try {
      _chromeCastService ??= ChromeCastService();

      // Initialize Chromecast in the background so it doesn't block UI rendering.
      if (!kIsWeb) {
        _chromeCastService!.init().catchError((e) {
          debugPrint('Chromecast initialization error: $e');
        });
      }

      _audioPlayerService = AudioPlayerService(_chromeCastService);

      if (!mounted) return;
      setState(() {
        _localizationsLoaded = true;
      });
    } finally {
      _initializingAudio = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: dynamicColorNotifier,
      builder: (context, useDynamicColor, _) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            ColorScheme lightColorScheme;
            ColorScheme darkColorScheme;

            if (lightDynamic != null &&
                darkDynamic != null &&
                useDynamicColor) {
              lightColorScheme = lightDynamic;
              darkColorScheme = darkDynamic;
            } else {
              lightColorScheme = ColorScheme.fromSeed(
                seedColor: brandColor,
                brightness: Brightness.light,
              );
              darkColorScheme = ColorScheme.fromSeed(
                seedColor: brandColor,
                brightness: Brightness.dark,
              );
            }

            if (!_localizationsLoaded ||
                _audioPlayerService == null ||
                _chromeCastService == null) {
              return const SizedBox.shrink();
            }

            Widget appContent = ValueListenableBuilder<String>(
              valueListenable: languageNotifier,
              builder: (context, currentLanguage, _) {
                Locale? appLocale;
                if (kIsWeb && currentLanguage != 'system') {
                  appLocale = Locale(currentLanguage);
                }

                return MultiProvider(
                  providers: [
                    ChangeNotifierProvider<AudioPlayerService>(
                      create: (_) => _audioPlayerService!,
                    ),
                    ChangeNotifierProvider<ChromeCastService>(
                      create: (_) => _chromeCastService!,
                    ),
                    ChangeNotifierProvider<HistoryService>.value(
                      value: HistoryService(),
                    ),
                  ],
                  child: MaterialApp(
                    title: 'Etherly',
                    locale: appLocale,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: const [Locale('en'), Locale('nl')],
                    theme: AppTheme.getLight(lightColorScheme),
                    darkTheme: AppTheme.getDark(darkColorScheme),
                    themeMode: themeNotifier.value,
                    scrollBehavior: AppScrollBehavior(),
                    builder: (context, child) {
                      if (ScreenType.isTv) {
                        const targetScale = 0.7;
                        final mediaQuery = MediaQuery.of(context);
                        final newSize = mediaQuery.size / targetScale;
                        return MediaQuery(
                          data: mediaQuery.copyWith(
                            size: newSize,
                          ),
                          child: FractionallySizedBox(
                            widthFactor: 1 / targetScale,
                            heightFactor: 1 / targetScale,
                            child: Transform.scale(
                              scale: targetScale,
                              child: child,
                            ),
                          ),
                        );
                      }
                      return child!;
                    },
                    home: AppScreen(
                      startingTab: widget.startingTab,
                      onHomeContentLoaded: _triggerFadeIn,
                    ),
                  ),
                );
              },
            );

            return AnimatedOpacity(
              opacity: _showApp ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.linear,
              child: appContent,
            );
          },
        );
      },
    );
  }
}

/// Custom scroll behavior to enable mouse drag scrolling on web and desktop.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
