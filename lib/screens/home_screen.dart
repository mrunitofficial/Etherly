import 'dart:async';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/widgets/screen_header.dart';
import 'package:etherly/widgets/category_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/services/theme_data.dart';

const int _minTotalCategories = 8;

typedef ContentLoadedCallback = void Function();

class HomeScreen extends StatefulWidget {
  final ContentLoadedCallback? onContentLoaded;
  final double bottomPadding;
  const HomeScreen({super.key, this.onContentLoaded, this.bottomPadding = 0.0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isInitialized) {
      return _showLoading
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink();
    }

    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final sizes = theme.extension<Sizes>()!;

    final audioService = context.watch<AudioPlayerService>();
    final sections = _getSections(context, audioService.stations, audioService);

    return CustomScrollView(
      cacheExtent: 4000.0,
      slivers: [
        SliverToBoxAdapter(
          child: ScreenHeader(
            title: loc?.translate('homeWelcome') ?? 'Etherly',
          ),
        ),
        if (sections.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.radio_outlined,
                    size: sizes.large,
                    color: theme.colorScheme.primary.withAlpha(128),
                  ),
                  SizedBox(height: spacing.medium),
                  Text(
                    loc?.translate('homeEmptyTitle') ?? 'No stations',
                    style: theme.textTheme.headlineMedium,
                  ),
                  SizedBox(height: spacing.small),
                  Text(
                    loc?.translate('homeEmptySubtitle') ??
                        'No radio stations available',
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: spacing.large),
                ],
              ),
            ),
          )
        else
          ...sections.map(
            (section) => SliverToBoxAdapter(
              child: CategoryRow(
                title: section.title,
                stations: section.stations,
              ),
            ),
          ),
        // Unified bottom padding sliver
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: widget.bottomPadding + spacing.medium,
          ),
        ),
      ],
    );
  }

  List<({String title, List<Station> stations})> _getSections(
    BuildContext context,
    List<Station> allStations,
    AudioPlayerService audioService,
  ) {
    final loc = AppLocalizations.of(context);
    final List<({String title, List<Station> stations})> sections = [];
    final Set<String> displayedCategories = {};

    // 1. Favorites
    final favorites = audioService.favoriteStations;
    if (favorites.isNotEmpty) {
      sections.add((
        title: loc?.translate('homeFavoritesTitle') ?? 'Favorites',
        stations: favorites,
      ));
    }

    // 2. Recents
    final recents = audioService.recentStations;
    if (recents.isNotEmpty) {
      sections.add((
        title: loc?.translate('homeRecentsTitle') ?? 'Recents',
        stations: recents,
      ));
    }

    // 3. Popular
    final popular = allStations.where((s) => s.rank != null).toList()
      ..sort((a, b) => (a.rank ?? 999).compareTo(b.rank ?? 999));
    if (popular.isNotEmpty) {
      sections.add((
        title: loc?.translate('homeCategoriesTitle') ?? 'Popular',
        stations: popular,
      ));
    }

    // 4. Dynamic Categories
    final sourceStations = recents.isNotEmpty ? recents : popular;
    final recentIds = recents.map((s) => s.id).toSet();
    final String moreFromPrefix = loc?.translate('homeMoreFrom') ?? 'More from';

    for (final station in sourceStations) {
      final category = station.category;
      if (displayedCategories.contains(category)) continue;

      final categoryStations = allStations
          .where((s) => s.category == category && !recentIds.contains(s.id))
          .toList();

      if (categoryStations.length > 2) {
        sections.add((
          title: '$moreFromPrefix $category',
          stations: categoryStations,
        ));
        displayedCategories.add(category);
      }
    }

    // 5. Fallback Categories
    if (sections.length < _minTotalCategories) {
      final allCategories = allStations.map((s) => s.category).toSet().toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      for (final category in allCategories) {
        if (sections.length >= _minTotalCategories) break;
        if (displayedCategories.contains(category)) continue;

        final stations = allStations
            .where((s) => s.category == category)
            .toList();
        if (stations.length > 1) {
          sections.add((
            title: '$moreFromPrefix $category',
            stations: stations,
          ));
          displayedCategories.add(category);
        }
      }
    }

    return sections;
  }
}
