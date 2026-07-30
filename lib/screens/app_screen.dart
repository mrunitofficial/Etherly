import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:etherly/localization/app_localizations.dart';

import 'package:etherly/models/device.dart';

import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/services/chrome_cast_service.dart';
import 'package:etherly/services/theme_data.dart';

import 'package:etherly/screens/favorites_screen.dart';
import 'package:etherly/screens/home_screen.dart';
import 'package:etherly/screens/radio_player.dart';
import 'package:etherly/screens/search_screen.dart';
import 'package:etherly/screens/settings_screen.dart';
import 'package:etherly/screens/stations_screen.dart';

import 'package:etherly/widgets/cast_devices.dart';
import 'package:etherly/widgets/station_art.dart';

/// A destination for the app's main navigation.
class _AppDestination {
  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function(BuildContext, ScreenType, double, bool) builder;

  const _AppDestination({
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });
}

class AppScreen extends StatefulWidget {
  final int startingTab;
  final VoidCallback? onHomeContentLoaded;

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
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final List<_AppDestination> _destinations;

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

    _destinations = [
      _AppDestination(
        labelKey: 'navHome',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        builder: (context, _, padding, isActive) => HomeScreen(
          bottomPadding: padding,
          isActive: isActive,
        ),
      ),
      _AppDestination(
        labelKey: 'navStations',
        icon: Icons.radio_outlined,
        selectedIcon: Icons.radio,
        builder: (context, screenType, padding, _) => StationsScreen(
          screenType: screenType,
          bottomPadding: padding,
        ),
      ),
      _AppDestination(
        labelKey: 'navFavorites',
        icon: Icons.favorite_outline,
        selectedIcon: Icons.favorite,
        builder: (context, screenType, padding, _) => FavoritesScreen(
          screenType: screenType,
          bottomPadding: padding,
        ),
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<AudioPlayerService>();
      if (!mounted) return;

      void triggerPrecache() {
        StationArt.precacheStations(context, service.stations).then((_) {
          if (mounted) {
            widget.onHomeContentLoaded?.call();
          }
        });
      }

      if (service.stations.isNotEmpty) {
        triggerPrecache();
      } else {
        void onReady() {
          if (service.isReady.value) {
            service.isReady.removeListener(onReady);
            triggerPrecache();
          }
        }

        service.isReady.addListener(onReady);
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
      // Ensure player collapses when switching tabs
      context.read<AudioPlayerService>().radioPlayerShouldClose.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenType = ScreenType.fromContext(context);
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final shapes = theme.extension<Shapes>()!;
    final loc = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTooShort =
            !screenType.isLargeFormat &&
            constraints.maxHeight < RadioPlayer.maxPlayerHeight;

        final playerBottomPadding =
            (screenType == ScreenType.smallScreenVertical && !isTooShort)
            ? RadioPlayer.minPlayerHeight + spacing.small
            : spacing.small;

        // Common AppBar widget logic
        final appBar = AppBar(
          backgroundColor: screenType.isLargeFormat
              ? theme.colorScheme.surfaceContainer
              : null,
          scrolledUnderElevation: screenType.isLargeFormat ? 0 : null,
          actionsPadding: EdgeInsets.symmetric(horizontal: spacing.small),
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
          leading: screenType.isLargeFormat
              ? null
              : Center(child: _LogoButton(onPressed: () => _onTabSelected(0))),
          title: const StationSearchBar(),
          actions: [
            if (context.read<ChromeCastService>().isCastSupported())
              const _CastButton(),
            IconButton(
              icon: Icon(
                Icons.settings,
                size: screenType.isLargeFormat
                    ? spacing.extraLarge
                    : spacing.large,
              ),
              tooltip: loc?.mainTooltipSettings ?? 'Settings',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(themeNotifier: themeNotifier),
                ),
              ),
            ),
          ],
        );

        final mainContent = Align(
          alignment: Alignment.topCenter,
          child: ClipRRect(
            borderRadius: screenType.isLargeFormat
                ? shapes.large
                : BorderRadius.zero,
            child: Container(
              color: theme.colorScheme.surface,
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: IndexedStack(
                    index: _selectedIndex,
                    sizing: StackFit.expand,
                    children: List.generate(_destinations.length, (index) {
                      final d = _destinations[index];
                      return d.builder(
                        context,
                        screenType,
                        playerBottomPadding,
                        _selectedIndex == index,
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );

        // Navigation logic
        if (screenType.isLargeFormat) {
          final Widget bodyRow = Row(
            children: [
              FocusTraversalGroup(
                child: NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onTabSelected,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: EdgeInsets.only(
                      top: spacing.small,
                      bottom: spacing.medium,
                    ),
                    child: _LogoButton(
                      onPressed: () => _onTabSelected(0),
                      size: spacing.extraLarge,
                    ),
                  ),
                  destinations: _destinations.map((d) {
                    String label = d.labelKey;
                    if (loc != null) {
                      if (d.labelKey == 'navHome') label = loc.navHome;
                      if (d.labelKey == 'navStations') label = loc.navStations;
                      if (d.labelKey == 'navFavorites') label = loc.navFavorites;
                    }
                    return NavigationRailDestination(
                      selectedIcon: Icon(d.selectedIcon),
                      icon: Icon(d.icon),
                      label: Text(label),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: Scaffold(
                  appBar: appBar,
                  body: Row(
                    children: [
                      Expanded(
                        child: FocusTraversalGroup(
                          child: mainContent,
                        ),
                      ),
                      SizedBox(
                        width: 360,
                        child: FocusTraversalGroup(
                          child: RadioPlayer(screenType: screenType),
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: SizedBox(height: spacing.medium),
                ),
              ),
            ],
          );

          if (screenType == ScreenType.tv) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.large,
                vertical: spacing.medium,
              ),
              child: bodyRow,
            );
          }

          return bodyRow;
        }

        // Small layout (Mobile)
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: appBar,
          body: Stack(
            children: [
              mainContent,
              RadioPlayer(screenType: screenType),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onTabSelected,
            destinations: _destinations.map((d) {
              String label = d.labelKey;
              if (loc != null) {
                if (d.labelKey == 'navHome') label = loc.navHome;
                if (d.labelKey == 'navStations') label = loc.navStations;
                if (d.labelKey == 'navFavorites') label = loc.navFavorites;
              }
              return NavigationDestination(
                selectedIcon: Icon(d.selectedIcon),
                icon: Icon(d.icon),
                label: label,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _LogoButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double? size;

  const _LogoButton({required this.onPressed, this.size});

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<Spacing>()!;
    final effectiveSize = size ?? spacing.large;

    return IconButton(
      iconSize: effectiveSize,
      icon: SvgPicture.asset(
        'assets/icon_base.svg',
        width: effectiveSize,
        height: effectiveSize,
      ),
      tooltip: AppLocalizations.of(context)?.navHome ?? 'Home',
      onPressed: onPressed,
    );
  }
}

class _CastButton extends StatelessWidget {
  const _CastButton();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return IconButton(
      icon: const Icon(Icons.cast_rounded),
      tooltip: loc?.mainTooltipCast ?? 'Cast to device',
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => const CastDevices(),
        );
      },
    );
  }
}
