import 'dart:async';
import 'package:etherly/models/device.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/services/radio_player_service.dart';
import 'package:etherly/widgets/screen_header.dart';
import 'package:etherly/widgets/station_card_item.dart';
import 'package:etherly/widgets/station_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _miniPlayerHeight = 120.0;
const String _favoritesViewTypeKey = 'favorites_view_type';

enum ViewType { list, grid }

typedef ContentLoadedCallback = void Function();

class FavoritesScreen extends StatefulWidget {
  final ContentLoadedCallback? onContentLoaded;
  final ScreenType screenType;
  const FavoritesScreen({
    super.key,
    this.onContentLoaded,
    required this.screenType,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final Future<ViewType> _viewTypeFuture;
  ViewType _viewType = ViewType.list;

  bool _showLoading = false;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _viewTypeFuture = _loadViewType();

    _loadingTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _showLoading = true);
      }
    });
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
    return FutureBuilder<ViewType>(
      future: _viewTypeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return _buildContent(context, ViewType.list);
        }
        return _buildContent(context, _viewType);
      },
    );
  }

  Widget _buildContent(BuildContext context, ViewType viewType) {
    final audioPlayerService = context.watch<AudioPlayerService>();
    final stations = audioPlayerService.stations;
    final favoriteStations = stations.where((s) => s.isFavorite).toList();

    if (stations.isEmpty) {
      return _showLoading
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink();
    }
    if (widget.onContentLoaded != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onContentLoaded?.call();
      });
    }

    _loadingTimer?.cancel();

    if (favoriteStations.isEmpty) {
      final loc = AppLocalizations.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc?.translate('favoritesEmptyTitle') ??
                  'No favorite stations yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              loc?.translate('favoritesEmptySubtitle') ??
                  'Favorite a radio station first',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final loc = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = EdgeInsets.only(
      bottom: widget.screenType == ScreenType.largeScreen && screenWidth >= 1400 ? 8.0 : (_miniPlayerHeight + 8.0),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(
        key: ValueKey<ViewType>(_viewType),
        child: SafeArea(
          child: _viewType == ViewType.list
              ? CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: ScreenHeader(
                        title: loc?.translate('favoritesTitle') ?? 'Favorites',
                        actions: SegmentedButton<ViewType>(
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
                    _buildSliverList(
                      favoriteStations,
                      audioPlayerService,
                      bottomPadding,
                    ),
                  ],
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: ScreenHeader(
                        title: loc?.translate('favoritesTitle') ?? 'Favorites',
                        actions: SegmentedButton<ViewType>(
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
                    _buildSliverGrid(
                      favoriteStations,
                      audioPlayerService,
                      bottomPadding,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSliverList(
    List<dynamic> stations,
    AudioPlayerService service,
    EdgeInsets padding,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (widget.screenType != ScreenType.largeScreen || screenWidth < 1400) {
      // Small screen: single-column layout
      return SliverPadding(
        padding: padding,
        sliver: SliverList.builder(
          itemCount: stations.length,
          itemBuilder: (context, index) {
            final station = stations[index];
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Padding(
                key: ValueKey(station.id),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: StationCardItem(
                  station: station,
                  isFavorite: station.isFavorite,
                  onTap: () => service.playMediaItem(station),
                  onFavorite: () => service.toggleFavorite(station),
                ),
              ),
            );
          },
        ),
      );
    }

    // Large screen: 2-column layout
    final rowCount = (stations.length / 2).ceil();
    return SliverPadding(
      padding: padding,
      sliver: SliverList.builder(
        itemCount: rowCount,
        itemBuilder: (context, rowIndex) {
          final leftIndex = rowIndex * 2;
          final rightIndex = leftIndex + 1;
          final leftStation = stations[leftIndex];
          final rightStation = rightIndex < stations.length
              ? stations[rightIndex]
              : null;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: SizedBox(
              height: 80.0,
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: StationCardItem(
                        key: ValueKey(leftStation.id),
                        station: leftStation,
                        isFavorite: leftStation.isFavorite,
                        onTap: () => service.playMediaItem(leftStation),
                        onFavorite: () => service.toggleFavorite(leftStation),
                      ),
                    ),
                  ),
                  if (rightStation != null) ...[
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeIn,
                        switchOutCurve: Curves.easeOut,
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: StationCardItem(
                          key: ValueKey(rightStation.id),
                          station: rightStation,
                          isFavorite: rightStation.isFavorite,
                          onTap: () => service.playMediaItem(rightStation),
                          onFavorite: () =>
                              service.toggleFavorite(rightStation),
                        ),
                      ),
                    ),
                  ] else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverGrid(
    List<dynamic> stations,
    AudioPlayerService service,
    EdgeInsets padding,
  ) {
    return SliverPadding(
      padding: padding.copyWith(left: 8.0, right: 8.0, top: 4.0),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 128.0,
          childAspectRatio: 1.0,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final station = stations[index];
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: StationGridItem(
              key: ValueKey(station.id),
              station: station,
              isFavorite: station.isFavorite,
              onTap: () => service.playMediaItem(station),
              onFavorite: () => service.toggleFavorite(station),
              borderRadius: BorderRadius.circular(12.0),
            ),
          );
        },
      ),
    );
  }
}
