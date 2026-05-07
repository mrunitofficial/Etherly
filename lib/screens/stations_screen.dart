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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isInitialized) {
      return _showLoading
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink();
    }

    final audioPlayerService = context.watch<AudioPlayerService>();
    final stations = audioPlayerService.stations;

    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final sizes = theme.extension<Sizes>()!;
    final shapes = theme.extension<Shapes>()!;
    final loc = AppLocalizations.of(context);

    return CustomScrollView(
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
                    size: sizes.large,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: spacing.medium),
                  Text(
                    loc?.translate('stationsEmptyTitle') ?? 'No stations',
                    style: theme.textTheme.headlineMedium,
                  ),
                  SizedBox(height: spacing.small),
                  Text(
                    loc?.translate('stationsEmptySubtitle') ??
                        'No radio stations found',
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: spacing.large),
                ],
              ),
            ),
          )
        else if (_viewType == ViewType.list)
          ..._buildListSlivers(
            _getGroupedStations(stations),
            audioPlayerService,
            spacing,
            sizes,
          )
        else
          _buildSliverGrid(stations, audioPlayerService, spacing, shapes),

        SliverPadding(
          padding: EdgeInsets.only(
            bottom: widget.bottomPadding + spacing.medium,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildListSlivers(
    Map<String, List<Station>> grouped,
    AudioPlayerService service,
    Spacing spacing,
    Sizes sizes,
  ) {
    final slivers = <Widget>[];
    final artSize = widget.screenType.isLargeFormat
        ? sizes.large
        : sizes.normal;
    final cardHeight = artSize + spacing.medium;

    grouped.forEach((category, stations) {
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

    return slivers;
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
            borderRadius: shapes.medium,
          );
        },
      ),
    );
  }
}
