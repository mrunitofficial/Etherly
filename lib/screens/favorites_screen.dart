import 'dart:async';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/models/device.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/widgets/screen_header.dart';
import 'package:etherly/widgets/station_card_item.dart';
import 'package:etherly/widgets/station_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _favoritesViewTypeKey = 'favorites_view_type';

enum ViewType { list, grid }

typedef ContentLoadedCallback = void Function();

class FavoritesScreen extends StatefulWidget {
  final ContentLoadedCallback? onContentLoaded;
  final ScreenType screenType;
  final double bottomPadding;
  const FavoritesScreen({
    super.key,
    this.onContentLoaded,
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
      widget.onContentLoaded?.call();
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
    final shapes = theme.extension<Shapes>()!;
    final loc = AppLocalizations.of(context);

    return CustomScrollView(
      cacheExtent: 1000.0,
      slivers: [
        SliverToBoxAdapter(
          child: ScreenHeader(
            title: loc?.translate('favoritesTitle') ?? 'Favorites',
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: sizes.large,
                    color: theme.colorScheme.primary.withAlpha(128),
                  ),
                  SizedBox(height: spacing.medium),
                  Text(
                    loc?.translate('favoritesEmptyTitle') ??
                        'No favorite stations yet',
                    style: theme.textTheme.headlineMedium,
                  ),
                  SizedBox(height: spacing.small),
                  Text(
                    loc?.translate('favoritesEmptySubtitle') ??
                        'Favorite a radio station first',
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: spacing.large),
                ],
              ),
            ),
          )
        else if (_viewType == ViewType.list)
          _buildListSlivers(
            favoriteStations,
            audioPlayerService,
            spacing,
          )
        else
          _buildSliverGrid(
            favoriteStations,
            audioPlayerService,
            spacing,
            shapes,
          ),

        SliverPadding(
          padding: EdgeInsets.only(
            bottom: widget.bottomPadding + spacing.medium,
          ),
        ),
      ],
    );
  }

  Widget _buildListSlivers(
    List<Station> stations,
    AudioPlayerService service,
    Spacing spacing,
  ) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        spacing.medium,
        spacing.extraSmall,
        spacing.medium,
        0,
      ),
      sliver: SliverReorderableList(
        itemCount: stations.length,
        onReorderStart: (index) => HapticFeedback.heavyImpact(),
        onReorder: (oldIndex, newIndex) {
          int adjustedNewIndex = newIndex;
          if (oldIndex < newIndex) {
            adjustedNewIndex -= 1;
          }
          service.reorderFavorites(oldIndex, adjustedNewIndex);
          setState(() {});
        },
        itemBuilder: (context, index) {
          final station = stations[index];
          return Padding(
            key: ValueKey(station.id),
            padding: EdgeInsets.only(bottom: spacing.small),
            child: ReorderableDelayedDragStartListener(
              index: index,
              child: StationCardItem(
                station: station,
                isFavorite: station.isFavorite,
                onTap: () => service.playMediaItem(station),
                onFavorite: () => service.toggleFavorite(station),
                screenType: widget.screenType,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverGrid(
    List<Station> stations,
    AudioPlayerService service,
    Spacing spacing,
    Shapes shapes,
  ) {
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
          setState(() {});
        },
        itemBuilder: (context, index) {
          final station = stations[index];
          return ReorderableGridDelayedDragStartListener(
            key: ValueKey(station.id),
            index: index,
            child: StationGridItem(
              station: station,
              isFavorite: station.isFavorite,
              onTap: () => service.playMediaItem(station),
              onFavorite: () => service.toggleFavorite(station),
              borderRadius: shapes.medium,
            ),
          );
        },
      ),
    );
  }
}
