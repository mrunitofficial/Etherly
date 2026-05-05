import 'dart:async';
import 'package:etherly/models/device.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/widgets/screen_header.dart';
import 'package:etherly/widgets/station_card_item.dart';
import 'package:etherly/widgets/station_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:etherly/services/theme_data.dart';

const String _radioViewTypeKey = 'radio_view_type';

enum ViewType { list, grid }

typedef ContentLoadedCallback = void Function();

/// A screen that displays a list or grid of all radio stations.
class StationsScreen extends StatefulWidget {
  final ContentLoadedCallback? onContentLoaded;
  final ScreenType screenType;
  final double bottomPadding;
  const StationsScreen({
    super.key,
    this.onContentLoaded,
    required this.screenType,
    this.bottomPadding = 0.0,
  });

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen>
    with AutomaticKeepAliveClientMixin {
  ViewType _viewType = ViewType.list;
  bool _isInitialized = false;
  bool _showLoading = false;
  Timer? _loadingTimer;
  Future<void>? _initializationFuture;

  @override
  bool get wantKeepAlive => true;

  /// Initializes and disposes resources.
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

  Map<String, List<Station>> _getGroupedStations(List<Station> stations) {
    final Map<String, List<Station>> grouped = {};
    for (final station in stations) {
      (grouped[station.category] ??= []).add(station);
    }
    return grouped;
  }

  /// Builds the station screen UI.
  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isInitialized) {
      return _showLoading
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink();
    }

    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final audioPlayerService = context.watch<AudioPlayerService>();
    final stations = audioPlayerService.stations;
    final spacing = Theme.of(context).extension<Spacing>()!;

    final loc = AppLocalizations.of(context);
    final contentPadding = EdgeInsets.symmetric(horizontal: spacing.medium);

    return SafeArea(
      child: CustomScrollView(
        cacheExtent: 4000.0,
        slivers: [
          SliverToBoxAdapter(
            child: ScreenHeader(
              title: loc?.translate('stationsTitle') ?? 'All channels',
              actions: stations.isEmpty
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
          if (stations.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.radio,
                      size: Theme.of(context).extension<Sizes>()!.large * 1.5,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(128), // 0.5 opacity
                    ),
                    SizedBox(height: spacing.medium),
                    Text(
                      loc?.translate('stationsEmptyTitle') ?? 'No stations',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: spacing.small),
                    Text(
                      loc?.translate('stationsEmptySubtitle') ??
                          'No radio stations found',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    // Add bottom padding to balance the vertical center
                    SizedBox(height: spacing.large * 2),
                  ],
                ),
              ),
            )
          else if (_viewType == ViewType.list)
            ..._buildListSlivers(
              _getGroupedStations(stations),
              audioPlayerService,
              contentPadding,
              spacing,
            )
          else
            _buildSliverGrid(
              stations,
              audioPlayerService,
              contentPadding,
              spacing,
            ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: widget.bottomPadding + spacing.medium,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a list of slivers for the categorized stations.
  List<Widget> _buildListSlivers(
    Map<String, List<Station>> grouped,
    AudioPlayerService service,
    EdgeInsets padding,
    Spacing spacing,
  ) {
    final slivers = <Widget>[];

    final sizes = Theme.of(context).extension<Sizes>()!;
    final artSize = widget.screenType.isLargeFormat
        ? sizes.large
        : sizes.normal;
    final cardHeight = artSize + (spacing.medium);

    grouped.forEach((category, stations) {
      // Category Header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(spacing.medium),
            child: Text(
              category,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );

      // Stations responsive Grid (acts as a list on mobile)
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: spacing.medium),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 600.0,
              mainAxisExtent: cardHeight,
              mainAxisSpacing: spacing.small,
              crossAxisSpacing: spacing.small,
            ),
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];
              return StationCardItem(
                key: ValueKey(station.id),
                station: station,
                isFavorite: station.isFavorite,
                onTap: () => service.playMediaItem(station),
                onFavorite: () => service.toggleFavorite(station),
                screenType: widget.screenType,
              );
            },
          ),
        ),
      );
    });

    // Add final padding

    return slivers;
  }

  /// Builds a sliver grid with station items.
  Widget _buildSliverGrid(
    List<Station> stations,
    AudioPlayerService service,
    EdgeInsets padding,
    Spacing spacing,
  ) {
    return SliverPadding(
      padding: padding.copyWith(top: spacing.extraSmall),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 128.0,
          crossAxisSpacing: spacing.small,
          mainAxisSpacing: spacing.small,
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
            borderRadius: Theme.of(context).extension<Shapes>()!.medium,
          );
        },
      ),
    );
  }
}
