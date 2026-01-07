import 'dart:async';
import 'package:etherly/models/device.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/radio_player_service.dart';
import 'package:etherly/widgets/screen_header.dart';
import 'package:etherly/widgets/station_card_item.dart';
import 'package:etherly/widgets/station_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _miniPlayerHeight = 120.0;
const String _radioViewTypeKey = 'radio_view_type';

enum ViewType { list, grid }

typedef ContentLoadedCallback = void Function();

/// A screen that displays a list or grid of all radio stations.
class StationsScreen extends StatefulWidget {
  final ContentLoadedCallback? onContentLoaded;
  final ScreenType screenType;
  const StationsScreen({
    super.key,
    this.onContentLoaded,
    required this.screenType,
  });

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  late final Future<ViewType> _viewTypeFuture;
  ViewType _viewType = ViewType.list;

  bool _showLoading = false;
  Timer? _loadingTimer;

  /// Initializes and disposes resources.
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

  /// Loads the saved view type from shared preferences.
  Future<ViewType> _loadViewType() async {
    final prefs = await SharedPreferences.getInstance();
    final viewTypeName =
        prefs.getString(_radioViewTypeKey) ?? ViewType.list.name;

    final loadedViewType = ViewType.values.firstWhere(
      (e) => e.name == viewTypeName,
      orElse: () => ViewType.list,
    );

    _viewType = loadedViewType;
    return loadedViewType;
  }

  Future<void> _saveViewType(ViewType viewType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_radioViewTypeKey, viewType.name);
  }

  List<dynamic> _buildCategorizedItems(List<Station> stations) {
    final items = <dynamic>[];
    final Map<String, List<Station>> groupedStations = {};

    for (final station in stations) {
      (groupedStations[station.category] ??= []).add(station);
    }

    groupedStations.forEach((category, stationList) {
      items.add(category);
      items.addAll(stationList);
    });

    return items;
  }

  /// Builds the station screen UI.
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
                  cacheExtent: 4000.0,
                  slivers: [
                    SliverToBoxAdapter(
                      child: ScreenHeader(
                        title:
                            loc?.translate('stationsTitle') ?? 'All channels',
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
                      _buildCategorizedItems(stations),
                      audioPlayerService,
                      bottomPadding,
                    ),
                  ],
                )
              : CustomScrollView(
                cacheExtent: 4000.0,
                  slivers: [
                    SliverToBoxAdapter(
                      child: ScreenHeader(
                        title:
                            loc?.translate('stationsTitle') ?? 'All channels',
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
                      stations,
                      audioPlayerService,
                      bottomPadding,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Builds a sliver list with categorized items.
  Widget _buildSliverList(
    List<dynamic> items,
    AudioPlayerService service,
    EdgeInsets padding,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Small screen: single-column layout
    if (widget.screenType != ScreenType.largeScreen || screenWidth < 1400) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item is String) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0.0),
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            if (item is Station) {
              return Padding(
                key: ValueKey(item.id),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: StationCardItem(
                  station: item,
                  isFavorite: item.isFavorite,
                  onTap: () => service.playMediaItem(item),
                  onFavorite: () => service.toggleFavorite(item),
                  screenType: widget.screenType,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );
    }

    // Large screen: 2-column layout
    return SliverPadding(
      padding: padding,
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is String) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0.0),
              child: Text(
                item,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            );
          }
          if (item is Station) {
            int stationCountBefore = 0;
            for (int i = index - 1; i >= 0; i--) {
              if (items[i] is String) break;
              if (items[i] is Station) stationCountBefore++;
            }

            if (stationCountBefore % 2 != 0) {
              return const SizedBox.shrink();
            }

            Station? nextStation;
            if (index + 1 < items.length && items[index + 1] is Station) {
              nextStation = items[index + 1] as Station;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Row(
                children: [
                    Expanded(
                      child: StationCardItem(
                        key: ValueKey(item.id),
                        station: item,
                        isFavorite: item.isFavorite,
                        onTap: () => service.playMediaItem(item),
                        onFavorite: () => service.toggleFavorite(item),
                        screenType: widget.screenType,
                      ),
                    ),
                    if (nextStation != null) ...[    
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: StationCardItem(
                          key: ValueKey(nextStation.id),
                          station: nextStation,
                          isFavorite: nextStation.isFavorite,
                          onTap: () => service.playMediaItem(nextStation!),
                          onFavorite: () =>
                              service.toggleFavorite(nextStation!),
                          screenType: widget.screenType,
                        ),
                      ),
                    ] else
                      const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              );
            }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Builds a sliver grid with station items.
  Widget _buildSliverGrid(
    List<Station> stations,
    AudioPlayerService service,
    EdgeInsets padding,
  ) {
    return SliverPadding(
      padding: padding.copyWith(left: 12.0, right: 12.0, top: 4.0),
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
          return StationGridItem(
            key: ValueKey(station.id),
            station: station,
            isFavorite: station.isFavorite,
            onTap: () => service.playMediaItem(station),
            onFavorite: () => service.toggleFavorite(station),
            borderRadius: BorderRadius.circular(12.0),
          );
        },
      ),
    );
  }
}
