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

/// A destination for the app's main navigation.
class _AppDestination {
  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function(BuildContext, ScreenType, double) builder;

  const _AppDestination({
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });
}

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
        builder: (context, _, padding) => HomeScreen(
          onContentLoaded: widget.onHomeContentLoaded,
          bottomPadding: padding,
        ),
      ),
      _AppDestination(
        labelKey: 'navStations',
        icon: Icons.radio_outlined,
        selectedIcon: Icons.radio,
        builder: (context, screenType, padding) => StationsScreen(
          onContentLoaded: widget.onHomeContentLoaded,
          screenType: screenType,
          bottomPadding: padding,
        ),
      ),
      _AppDestination(
        labelKey: 'navFavorites',
        icon: Icons.favorite_outline,
        selectedIcon: Icons.favorite,
        builder: (context, screenType, padding) => FavoritesScreen(
          onContentLoaded: widget.onHomeContentLoaded,
          screenType: screenType,
          bottomPadding: padding,
        ),
      ),
    ];

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

    final playerBottomPadding = screenType.isLargeFormat
        ? spacing.small
        : RadioPlayer.minPlayerHeight + spacing.small;

    // Common AppBar widget logic
    final appBar = AppBar(
      backgroundColor: screenType.isLargeFormat
          ? theme.colorScheme.surfaceContainer
          : null,
      scrolledUnderElevation: screenType.isLargeFormat ? 0 : null,
      actionsPadding: EdgeInsets.symmetric(horizontal: spacing.extraSmall),
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
          : _LogoButton(onPressed: () => _onTabSelected(0)),
      title: const StationSearchBar(),
      actions: [
        if (context.read<ChromeCastService>().isCastSupported())
          _CastButton(spacing: spacing),
        IconButton(
          icon: Icon(
            Icons.settings,
            size: screenType.isLargeFormat ? spacing.extraLarge : spacing.large,
          ),
          tooltip: loc?.translate('mainTooltipSettings') ?? 'Settings',
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
                children: _destinations
                    .map(
                      (d) =>
                          d.builder(context, screenType, playerBottomPadding),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );

    // Navigation logic
    if (screenType.isLargeFormat) {
      return Row(
        children: [
          NavigationRail(
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
              return NavigationRailDestination(
                selectedIcon: Icon(d.selectedIcon),
                icon: Icon(d.icon),
                label: Text(loc?.translate(d.labelKey) ?? d.labelKey),
              );
            }).toList(),
          ),
          Expanded(
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: appBar,
              body: Row(
                children: [
                  Expanded(child: mainContent),
                  SizedBox(
                    width: 360,
                    child: RadioPlayer(screenType: screenType),
                  ),
                ],
              ),
              // Bottom spacer for large format
              bottomNavigationBar: SizedBox(height: spacing.medium),
            ),
          ),
        ],
      );
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
          return NavigationDestination(
            selectedIcon: Icon(d.selectedIcon),
            icon: Icon(d.icon),
            label: loc?.translate(d.labelKey) ?? d.labelKey,
          );
        }).toList(),
      ),
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

    return Center(
      child: IconButton(
        iconSize: effectiveSize,
        icon: SvgPicture.asset(
          'assets/icon_base.svg',
          width: effectiveSize,
          height: effectiveSize,
        ),
        tooltip: AppLocalizations.of(context)?.translate('navHome') ?? 'Home',
        onPressed: onPressed,
      ),
    );
  }
}

class _CastButton extends StatelessWidget {
  final Spacing spacing;

  const _CastButton({required this.spacing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final shapes = theme.extension<Shapes>()!;

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.cast_rounded),
          Positioned(
            right: -spacing.extraExtraSmall,
            top: -spacing.extraExtraSmall,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.extraExtraSmall * 1.5,
                vertical: spacing.extraExtraSmall / 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: shapes.extraSmall,
              ),
              child: Text(
                'BETA',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
      tooltip: loc?.translate('mainTooltipCast') ?? 'Cast to device',
      onPressed: () {
        showDialog(
          context: context,
          builder: (dialogContext) => MultiProvider(
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
    );
  }
}
