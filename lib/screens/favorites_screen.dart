import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:etherly/localization/app_localizations.dart';

import 'package:etherly/models/device.dart';
import 'package:etherly/models/station.dart';

import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/services/theme_data.dart';

import 'package:etherly/widgets/screen_header.dart';
import 'package:etherly/widgets/station_card_item.dart';
import 'package:etherly/widgets/station_grid_item.dart';

const String _favoritesViewTypeKey = 'favorites_view_type';

/// Favorites display layout representation options.
enum ViewType { list, grid }

class FavoritesScreen extends StatefulWidget {
  final ScreenType screenType;
  final double bottomPadding;
  const FavoritesScreen({
    super.key,
    required this.screenType,
    this.bottomPadding = 0.0,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with AutomaticKeepAliveClientMixin {
  ViewType _viewType = ViewType.list;
  bool _isInitialized = false;
  bool _showLoading = false;
  Timer? _loadingTimer;
  Future<void>? _initializationFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializationFuture = context
        .read<AudioPlayerService>()
        .initializationFuture;

    _loadingTimer = Timer(Speed().short1, () {
      if (mounted) {
        setState(() => _showLoading = true);
      }
    });

    _initScreen();
  }

  Future<void> _initScreen() async {
    await _loadViewType();
    await _initializationFuture;

    _loadingTimer?.cancel();

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<ViewType> _loadViewType() async {
    final prefs = await SharedPreferences.getInstance();
    final viewTypeName =
        prefs.getString(_favoritesViewTypeKey) ?? ViewType.list.name;

    final loadedViewType = ViewType.values.firstWhere(
      (e) => e.name == viewTypeName,
      orElse: () => ViewType.list,
    );

    _viewType = loadedViewType;
    return loadedViewType;
  }

  Future<void> _saveViewType(ViewType viewType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritesViewTypeKey, viewType.name);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isInitialized) {
      return _showLoading
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink();
    }

    final audioPlayerService = context.watch<AudioPlayerService>();
    final favoriteStations = audioPlayerService.favoriteStations;

    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final sizes = theme.extension<Sizes>()!;
    final loc = AppLocalizations.of(context);

    return CustomScrollView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(1000.0),
      slivers: [
        SliverToBoxAdapter(
          child: ScreenHeader(
            title: loc?.favoritesTitle ?? 'Favorites',
            actions: favoriteStations.isEmpty
                ? null
                : SegmentedButton<ViewType>(
                    segments: const [
                      ButtonSegment(
                        value: ViewType.list,
                        icon: Icon(Icons.list),
                      ),
                      ButtonSegment(
                        value: ViewType.grid,
                        icon: Icon(Icons.grid_view),
                      ),
                    ],
                    selected: {_viewType},
                    onSelectionChanged: (Set<ViewType> newSelection) {
                      final newViewType = newSelection.first;
                      setState(() => _viewType = newViewType);
                      _saveViewType(newViewType);
                    },
                  ),
          ),
        ),
        if (favoriteStations.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.bottomPadding),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: sizes.large,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(height: spacing.medium),
                    Text(
                      loc?.favoritesEmptyTitle ?? 'No favorite stations yet',
                      style: theme.textTheme.headlineMedium,
                    ),
                    SizedBox(height: spacing.small),
                    Text(
                      loc?.favoritesEmptySubtitle ??
                          'Favorite a radio station first',
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: spacing.large),
                  ],
                ),
              ),
            ),
          )
        else ...[
          if (_viewType == ViewType.list)
            _FavoritesListSliver(
              stations: favoriteStations,
              service: audioPlayerService,
              screenType: widget.screenType,
              onReorder: () => setState(() {}),
            )
          else
            _FavoritesGridSliver(
              stations: favoriteStations,
              service: audioPlayerService,
              onReorder: () => setState(() {}),
            ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: widget.bottomPadding + spacing.medium,
            ),
          ),
        ],
      ],
    );
  }
}

/// Reorderable list sliver for favorite stations.
class _FavoritesListSliver extends StatelessWidget {
  final List<Station> stations;
  final AudioPlayerService service;
  final ScreenType screenType;
  final VoidCallback onReorder;

  const _FavoritesListSliver({
    required this.stations,
    required this.service,
    required this.screenType,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final sizes = theme.extension<Sizes>()!;

    final artSize = screenType.isLargeFormat
        ? sizes.large
        : sizes.normal;
    final cardHeight = artSize + spacing.medium;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        spacing.medium,
        spacing.extraSmall,
        spacing.medium,
        0,
      ),
      sliver: SliverReorderableGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 600.0,
          mainAxisExtent: cardHeight,
          crossAxisSpacing: spacing.small,
          mainAxisSpacing: spacing.small,
        ),
        itemCount: stations.length,
        onReorderStart: (index) => HapticFeedback.heavyImpact(),
        onReorder: (oldIndex, newIndex) {
          service.reorderFavorites(oldIndex, newIndex);
          onReorder();
        },
        itemBuilder: (context, index) {
          final station = stations[index];
          final bool useQuickDrag =
              kIsWeb ||
              defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.windows;

          final item = StationCardItem(
            key: ValueKey(station.id),
            station: station,
            isFavorite: station.isFavorite,
            onTap: () => service.playMediaItem(station),
            onFavorite: () => service.toggleFavorite(station),
            screenType: screenType,
          );

          if (useQuickDrag) {
            return ReorderableGridDragStartListener(
              key: ValueKey(station.id),
              index: index,
              child: item,
            );
          }

          return ReorderableGridDelayedDragStartListener(
            key: ValueKey(station.id),
            index: index,
            child: item,
          );
        },
      ),
    );
  }
}

/// Reorderable grid sliver for favorite stations.
class _FavoritesGridSliver extends StatelessWidget {
  final List<Station> stations;
  final AudioPlayerService service;
  final VoidCallback onReorder;

  const _FavoritesGridSliver({
    required this.stations,
    required this.service,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final shapes = theme.extension<Shapes>()!;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        spacing.medium,
        spacing.extraSmall,
        spacing.medium,
        0,
      ),
      sliver: SliverReorderableGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 128.0,
          crossAxisSpacing: spacing.small,
          mainAxisSpacing: spacing.small,
        ),
        itemCount: stations.length,
        onReorderStart: (index) => HapticFeedback.heavyImpact(),
        onReorder: (oldIndex, newIndex) {
          service.reorderFavorites(oldIndex, newIndex);
          onReorder();
        },
        itemBuilder: (context, index) {
          final station = stations[index];
          final bool useQuickDrag =
              kIsWeb ||
              defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.windows;

          final item = StationGridItem(
            key: ValueKey(station.id),
            station: station,
            onTap: () => service.playMediaItem(station),
            borderRadius: shapes.medium,
          );

          if (useQuickDrag) {
            return ReorderableGridDragStartListener(
              key: ValueKey(station.id),
              index: index,
              child: item,
            );
          }

          return ReorderableGridDelayedDragStartListener(
            key: ValueKey(station.id),
            index: index,
            child: item,
          );
        },
      ),
    );
  }
}
