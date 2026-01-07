import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'models/device.dart';
import 'localization/app_localizations.dart';
import 'services/radio_player_service.dart';
import 'screens/settings_screen.dart';
import 'screens/stations_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/radio_player.dart';
import 'screens/search_screen.dart';
import 'services/chrome_cast_service.dart';
import 'widgets/cast_devices.dart';

/// Global ValueNotifier for ThemeMode, allowing deep widgets to change the theme
/// and trigger a rebuild of the main application widget.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
final ValueNotifier<bool> dynamicColorNotifier = ValueNotifier(false);
const _brandColor = Colors.blue;
const _navigationRailWidth = 96.0;

/// Entry point of the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  PaintingBinding.instance.imageCache.maximumSize = 4000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1000 << 20;
  
  final prefs = await SharedPreferences.getInstance();
  final themeString = prefs.getString('theme');
  final theme = (ThemeMode.values.firstWhere(
    (e) => e.toString() == themeString,
    orElse: () => ThemeMode.system,
  ));
  themeNotifier.value = theme;
  final forceDefaultColor = prefs.getBool('forceDefaultColor') ?? false;
  dynamicColorNotifier.value = !forceDefaultColor;
  final startingTab = prefs.getInt('startingTab') ?? 0;

  runApp(MyApp(startingTab: startingTab));
}

/// The root widget of the application.
/// Initializes theme, localization, and audio service.
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
      Future.delayed(const Duration(milliseconds: 400), () {
        setState(() {
          _showApp = true;
        });
      });
    }
  }

  Future<void> _initAudioService(BuildContext context) async {
    if (_localizationsLoaded || _initializingAudio) return;
    _initializingAudio = true;
    final loc = AppLocalizations.of(context);
    final channelName =
        loc?.translate('notification_channel_name') ?? 'Radio playback';

    try {
      _chromeCastService ??= ChromeCastService();

      // Only initialize Chromecast if not web
      if (!kIsWeb) {
        await _chromeCastService!.init();
      }

      final audioHandler = await initAudioService(
        channelName: channelName,
        castService: _chromeCastService,
      );

      _audioPlayerService = AudioPlayerService(
        audioHandler,
        castService: _chromeCastService,
      );

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
                seedColor: _brandColor,
                brightness: Brightness.light,
              );
              darkColorScheme = ColorScheme.fromSeed(
                seedColor: _brandColor,
                brightness: Brightness.dark,
              );
            }

            Widget appContent = MaterialApp(
              title: 'Etherly',
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('nl')],

              /// Light theme data
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: lightColorScheme,
                scaffoldBackgroundColor: lightColorScheme.surfaceContainer,
                appBarTheme: AppBarTheme(
                  toolbarHeight: 80,
                  titleSpacing: 0.0,
                  surfaceTintColor: lightColorScheme.surfaceContainer,
                  shadowColor: lightColorScheme.surfaceContainerLowest,
                  backgroundColor: kIsWeb
                      ? lightColorScheme.surfaceContainer
                      : null,
                  scrolledUnderElevation: kIsWeb ? 0 : null,
                ),
                navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: lightColorScheme.surfaceContainer,
                ),
                navigationRailTheme: NavigationRailThemeData(
                  backgroundColor: lightColorScheme.surfaceContainer,
                ),
                tooltipTheme: const TooltipThemeData(
                  waitDuration: Duration(milliseconds: 500),
                ),
              ),

              /// Dark theme data
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: darkColorScheme,
                scaffoldBackgroundColor: darkColorScheme.surfaceContainer,
                appBarTheme: AppBarTheme(
                  toolbarHeight: 80,
                  titleSpacing: 0.0,
                  surfaceTintColor: darkColorScheme.surfaceContainer,
                  shadowColor: darkColorScheme.surfaceContainerLowest,
                  backgroundColor: kIsWeb
                      ? darkColorScheme.surfaceContainer
                      : null,
                  scrolledUnderElevation: kIsWeb ? 0 : null,
                ),
                navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: darkColorScheme.surfaceContainer,
                ),
                navigationRailTheme: NavigationRailThemeData(
                  backgroundColor: darkColorScheme.surfaceContainer,
                ),
                tooltipTheme: const TooltipThemeData(
                  waitDuration: Duration(seconds: 1),
                ),
              ),

              /// Initialize audio service
              themeMode: themeNotifier.value,
              home: Builder(
                builder: (context) {
                  if (!_localizationsLoaded) {
                    _initAudioService(context);
                    return const SizedBox.shrink();
                  }
                  return MultiProvider(
                    providers: [
                      ChangeNotifierProvider<AudioPlayerService>(
                        create: (_) => _audioPlayerService!,
                      ),
                      ChangeNotifierProvider<ChromeCastService>(
                        create: (_) => _chromeCastService!,
                      ),
                    ],
                    child: MyHomePage(
                      startingTab: widget.startingTab,
                      onHomeContentLoaded: _triggerFadeIn,
                    ),
                  );
                },
              ),
            );

            return AnimatedOpacity(
              opacity: _showApp ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeIn,
              child: appContent,
            );
          },
        );
      },
    );
  }
}

/// The main structure of the app, containing the AppBar, the main content (screens),
/// the persistent radio player, and the bottom NavigationBar.
typedef HomeContentLoadedCallback = void Function();

class MyHomePage extends StatefulWidget {
  final int startingTab;
  final HomeContentLoadedCallback? onHomeContentLoaded;

  const MyHomePage({
    super.key,
    required this.startingTab,
    this.onHomeContentLoaded,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.startingTab;
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<AudioPlayerService>();
      if (service.stations.isNotEmpty) {
        service.precacheAllStationArt(context);
      } else {
        service.isReady.addListener(() {
          if (service.isReady.value) {
            service.precacheAllStationArt(context);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedIndex != index) {
      _fadeController.forward(from: 0.0);
      setState(() => _selectedIndex = index);
    }
  }

  /// Determines the screen type based on device size and orientation.
  ScreenType _getScreenType(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    if (size.height >= 800 && size.width >= 800) {
      return ScreenType.largeScreen;
    }

    if (orientation == Orientation.landscape) {
      return ScreenType.smallScreenHorizontal;
    }

    return ScreenType.smallScreenVertical;
  }

  /// Builds the appropriate screen widget based on the selected index.
  Widget _buildScreen(int index, ScreenType screenType) {
    switch (index) {
      case 0:
        return HomeScreen(onContentLoaded: widget.onHomeContentLoaded);
      case 1:
        return StationsScreen(
          onContentLoaded: widget.onHomeContentLoaded,
          screenType: screenType,
        );
      case 2:
        return FavoritesScreen(
          onContentLoaded: widget.onHomeContentLoaded,
          screenType: screenType,
        );
      default:
        return HomeScreen(onContentLoaded: widget.onHomeContentLoaded);
    }
  }

  /// Builds the main Scaffold with AppBar, body, and NavigationBar.
  @override
  Widget build(BuildContext context) {
    final screenType = _getScreenType(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,

      /// Appbar with leading icon, search bar and action buttons.
      appBar: AppBar(
        actionsPadding: EdgeInsets.symmetric(horizontal: 4.0),
        animateColor: true,
        notificationPredicate: (notification) {
          final context = notification.context;
          bool insideSheet = false;
          context?.visitAncestorElements((element) {
            if (element.widget is DraggableScrollableSheet) {
              insideSheet = true;
              return false;
            }
            return true;
          });
          return !insideSheet;
        },
        leadingWidth: screenType == ScreenType.largeScreen
            ? _navigationRailWidth
            : null,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icon_base.svg',
            width: screenType == ScreenType.largeScreen ? 36 : 24,
            height: screenType == ScreenType.largeScreen ? 36 : 24,
          ),
          tooltip: AppLocalizations.of(context)?.translate('navHome') ?? 'Home',
          onPressed: () {
            _onTabSelected(0);
            context.read<AudioPlayerService>().radioPlayerShouldClose.value =
                true;
          },
        ),
        title: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.search,
                  color: Theme.of(context).hintColor,
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: context.read<AudioPlayerService>(),
                      child: const SearchScreen(),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<AudioPlayerService>(),
                        child: const SearchScreen(),
                      ),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(
                          context,
                        )?.translate('searchPanelHint') ??
                        'Search stations',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.mic_none),
                tooltip:
                    AppLocalizations.of(
                      context,
                    )?.translate('mainTooltipVoiceSearch') ??
                    'Voice search',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: context.read<AudioPlayerService>(),
                      child: const SearchScreen(startListening: true),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (context.read<ChromeCastService>().isCastSupported())
            IconButton(
              icon: const Icon(Icons.cast_rounded),
              tooltip:
                  AppLocalizations.of(context)?.translate('mainTooltipCast') ??
                  'Cast to device',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(
                        value: context.read<AudioPlayerService>(),
                      ),
                      ChangeNotifierProvider.value(
                        value: context.read<ChromeCastService>(),
                      ),
                    ],
                    child: const CastDevices(),
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(
              Icons.settings,
              size: screenType == ScreenType.largeScreen ? 32 : 24,
            ),
            tooltip:
                AppLocalizations.of(
                  context,
                )?.translate('mainTooltipSettings') ??
                'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(themeNotifier: themeNotifier),
                ),
              );
            },
          ),
        ],
      ),

      // Main content area with animated screen transitions.
      body: () {
        final content = Align(
          alignment: Alignment.topCenter,
          child: ClipRRect(
            borderRadius: screenType == ScreenType.largeScreen
                ? const BorderRadius.all(Radius.circular(16))
                : BorderRadius.zero,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: IndexedStack(
                  index: _selectedIndex,
                  sizing: StackFit.expand,
                  children: [
                    _buildScreen(0, screenType),
                    _buildScreen(1, screenType),
                    _buildScreen(2, screenType),
                  ],
                ),
              ),
            ),
          ),
        );

        // Large screen layout: NavigationRail with side player
        if (screenType == ScreenType.largeScreen) {
          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    NavigationRail(
                      minWidth: _navigationRailWidth,
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) {
                        _onTabSelected(index);
                        context
                                .read<AudioPlayerService>()
                                .radioPlayerShouldClose
                                .value =
                            true;
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        NavigationRailDestination(
                          selectedIcon: const Icon(Icons.home),
                          icon: const Icon(Icons.home_outlined),
                          label: Text(
                            AppLocalizations.of(
                                  context,
                                )?.translate('navHome') ??
                                'Home',
                          ),
                        ),
                        NavigationRailDestination(
                          selectedIcon: const Icon(Icons.radio),
                          icon: const Icon(Icons.radio_outlined),
                          label: Text(
                            AppLocalizations.of(
                                  context,
                                )?.translate('navStations') ??
                                'All stations',
                          ),
                        ),
                        NavigationRailDestination(
                          selectedIcon: const Icon(Icons.favorite),
                          icon: const Icon(Icons.favorite_outline),
                          label: Text(
                            AppLocalizations.of(
                                  context,
                                )?.translate('navFavorites') ??
                                'Favorites',
                          ),
                        ),
                      ],
                    ),
                    Expanded(child: content),
                    SizedBox(
                      width: 360,
                      child: RadioPlayer(screenType: screenType),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // Small screen layout: Stack with bottom player
        return Stack(
          children: [
            content,
            RadioPlayer(screenType: screenType),
          ],
        );
      }(),

      // Bottom navigation bar for small screens or border for large screens
      bottomNavigationBar: screenType == ScreenType.largeScreen
          ? Container(
              height: 16,
            )
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                _onTabSelected(index);
                context
                        .read<AudioPlayerService>()
                        .radioPlayerShouldClose
                        .value =
                    true;
              },
              destinations: [
                NavigationDestination(
                  selectedIcon: const Icon(Icons.home),
                  icon: const Icon(Icons.home_outlined),
                  label:
                      AppLocalizations.of(context)?.translate('navHome') ??
                      'Home',
                ),
                NavigationDestination(
                  selectedIcon: const Icon(Icons.radio),
                  icon: const Icon(Icons.radio_outlined),
                  label:
                      AppLocalizations.of(context)?.translate('navStations') ??
                      'All stations',
                ),
                NavigationDestination(
                  selectedIcon: const Icon(Icons.favorite),
                  icon: const Icon(Icons.favorite_outline),
                  label:
                      AppLocalizations.of(context)?.translate('navFavorites') ??
                      'Favorites',
                ),
              ],
            ),
    );
  }
}
