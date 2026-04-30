import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/device.dart';
import '../localization/app_localizations.dart';
import '../services/audio_player_service.dart';
import '../services/chrome_cast_service.dart';
import '../services/theme_data.dart';
import 'home_screen.dart';
import 'radio_player.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'stations_screen.dart';
import 'favorites_screen.dart';
import '../widgets/cast_devices.dart';

typedef HomeContentLoadedCallback = void Function();

class AppScreen extends StatefulWidget {
  final int startingTab;
  final HomeContentLoadedCallback? onHomeContentLoaded;

  const AppScreen({
    super.key,
    required this.startingTab,
    this.onHomeContentLoaded,
  });

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.startingTab;

    _fadeController = AnimationController(
      duration: Speed().medium1,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Easing.standard,
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
    final screenType = ScreenType.fromContext(context);

    // Common AppBar widget
    final appBar = AppBar(
      backgroundColor: screenType.isLargeFormat
          ? Theme.of(context).colorScheme.surfaceContainer
          : null,
      scrolledUnderElevation: screenType.isLargeFormat ? 0 : null,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 4.0),
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
      // Logo in AppBar only for small screens (it's in the Rail for large screens)
      leading: screenType.isLargeFormat
          ? null
          : IconButton(
              icon: SvgPicture.asset(
                'assets/icon_base.svg',
                width: 24,
                height: 24,
              ),
              tooltip:
                  AppLocalizations.of(context)?.translate('navHome') ?? 'Home',
              onPressed: () {
                _onTabSelected(0);
                context
                        .read<AudioPlayerService>()
                        .radioPlayerShouldClose
                        .value =
                    true;
              },
            ),
      title: const StationSearchBar(),
      actions: [
        if (context.read<ChromeCastService>().isCastSupported())
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.cast_rounded),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'BETA',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
          icon: Icon(Icons.settings, size: screenType.isLargeFormat ? 32 : 24),
          tooltip:
              AppLocalizations.of(context)?.translate('mainTooltipSettings') ??
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
    );

    // Shared content area for both layouts
    final contentArea = () {
      final mainContent = Align(
        alignment: Alignment.topCenter,
        child: ClipRRect(
          borderRadius: screenType.isLargeFormat
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

      if (screenType.isLargeFormat) {
        return Row(
          children: [
            Expanded(child: mainContent),
            SizedBox(width: 360, child: RadioPlayer(screenType: screenType)),
          ],
        );
      }

      return Stack(
        children: [
          mainContent,
          RadioPlayer(screenType: screenType),
        ],
      );
    }();

    // Large layout: Rail + Content Scaffold
    if (screenType.isLargeFormat) {
      return Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              _onTabSelected(index);
              context.read<AudioPlayerService>().radioPlayerShouldClose.value =
                  true;
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/icon_base.svg',
                  width: 36,
                  height: 36,
                ),
                tooltip:
                    AppLocalizations.of(context)?.translate('navHome') ??
                    'Home',
                onPressed: () {
                  _onTabSelected(0);
                  context
                          .read<AudioPlayerService>()
                          .radioPlayerShouldClose
                          .value =
                      true;
                },
              ),
            ),
            destinations: [
              NavigationRailDestination(
                selectedIcon: const Icon(Icons.home),
                icon: const Icon(Icons.home_outlined),
                label: Text(
                  AppLocalizations.of(context)?.translate('navHome') ?? 'Home',
                ),
              ),
              NavigationRailDestination(
                selectedIcon: const Icon(Icons.radio),
                icon: const Icon(Icons.radio_outlined),
                label: Text(
                  AppLocalizations.of(context)?.translate('navStations') ??
                      'All stations',
                ),
              ),
              NavigationRailDestination(
                selectedIcon: const Icon(Icons.favorite),
                icon: const Icon(Icons.favorite_outline),
                label: Text(
                  AppLocalizations.of(context)?.translate('navFavorites') ??
                      'Favorites',
                ),
              ),
            ],
          ),
          Expanded(
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: appBar,
              body: contentArea,
              bottomNavigationBar: Container(height: 16),
            ),
          ),
        ],
      );
    }

    // Small layout: Single Scaffold
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: appBar,
      body: contentArea,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          _onTabSelected(index);
          context.read<AudioPlayerService>().radioPlayerShouldClose.value =
              true;
        },
        destinations: [
          NavigationDestination(
            selectedIcon: const Icon(Icons.home),
            icon: const Icon(Icons.home_outlined),
            label: AppLocalizations.of(context)?.translate('navHome') ?? 'Home',
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
