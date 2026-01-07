import 'dart:async';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/radio_player_service.dart';
import 'package:etherly/widgets/screen_header.dart';
import 'package:etherly/widgets/category_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:etherly/localization/app_localizations.dart';

const int _minTotalCategories = 8;

typedef ContentLoadedCallback = void Function();

class HomeScreen extends StatefulWidget {
  final ContentLoadedCallback? onContentLoaded;
  const HomeScreen({super.key, this.onContentLoaded});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  bool _showLoading = false;
  Timer? _loadingTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadingTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _showLoading = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool stationsAreEmpty = context.select(
      (AudioPlayerService s) => s.stations.isEmpty,
    );

    if (!stationsAreEmpty && widget.onContentLoaded != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onContentLoaded?.call();
      });
    }

    if (stationsAreEmpty && _showLoading) {
      return const SizedBox.shrink();
    } else if (stationsAreEmpty) {
      return const SizedBox.shrink();
    }

    final AppLocalizations? loc = AppLocalizations.of(context);
    final List<Widget> categorySlivers = _buildContentSlivers(context);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ScreenHeader(
              title: loc?.translate('homeWelcome') ?? 'Welcome to Etherly!',
            ),
          ),
          ...categorySlivers,
          const SliverPadding(padding: EdgeInsets.only(bottom: 128.0)),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(BuildContext context) {
    final audioPlayerService = context.read<AudioPlayerService>();
    final AppLocalizations? loc = AppLocalizations.of(context);
    final double screenWidth = MediaQuery.sizeOf(context).width;

    final List<Station> allStations = context.select(
      (AudioPlayerService s) => List<Station>.from(s.stations),
    );
    final List<Station> favoriteStations = allStations
        .where((s) => s.isFavorite)
        .toList();
    final List<Station> recentStations = audioPlayerService.recentStations;
    final List<Station> popularStations =
        allStations.where((s) => s.rank != null).toList()
          ..sort((a, b) => (a.rank ?? 999).compareTo(b.rank ?? 999));

    final List<Widget> contentSlivers = [];
    final Set<String> displayedCategoryNames = {};

    _addFavorites(
      contentSlivers: contentSlivers,
      favoriteStations: favoriteStations,
      audioPlayerService: audioPlayerService,
      screenWidth: screenWidth,
      loc: loc,
    );

    _addRecents(
      contentSlivers: contentSlivers,
      recentStations: recentStations,
      audioPlayerService: audioPlayerService,
      screenWidth: screenWidth,
      loc: loc,
    );

    _addPopular(
      contentSlivers: contentSlivers,
      popularStations: popularStations,
      audioPlayerService: audioPlayerService,
      screenWidth: screenWidth,
      loc: loc,
    );

    _addDynamicCategories(
      contentSlivers: contentSlivers,
      displayedCategoryNames: displayedCategoryNames,
      recentStations: recentStations,
      popularStations: popularStations,
      allStations: allStations,
      audioPlayerService: audioPlayerService,
      screenWidth: screenWidth,
      loc: loc,
    );

    _addFallbackCategories(
      contentSlivers: contentSlivers,
      displayedCategoryNames: displayedCategoryNames,
      allStations: allStations,
      audioPlayerService: audioPlayerService,
      screenWidth: screenWidth,
      loc: loc,
    );

    return contentSlivers;
  }

  void _addFavorites({
    required List<Widget> contentSlivers,
    required List<Station> favoriteStations,
    required AudioPlayerService audioPlayerService,
    required double screenWidth,
    required AppLocalizations? loc,
  }) {
    if (favoriteStations.isNotEmpty) {
      contentSlivers.add(
        SliverToBoxAdapter(
          child: CategoryRow(
            title: loc?.translate('homeFavoritesTitle') ?? 'Favorites',
            stations: favoriteStations,
            audioPlayerService: audioPlayerService,
            screenWidth: screenWidth,
          ),
        ),
      );
    }
  }

  void _addRecents({
    required List<Widget> contentSlivers,
    required List<Station> recentStations,
    required AudioPlayerService audioPlayerService,
    required double screenWidth,
    required AppLocalizations? loc,
  }) {
    if (recentStations.isNotEmpty) {
      contentSlivers.add(
        SliverToBoxAdapter(
          child: CategoryRow(
            title: loc?.translate('homeRecentsTitle') ?? 'Recents',
            stations: recentStations,
            audioPlayerService: audioPlayerService,
            screenWidth: screenWidth,
          ),
        ),
      );
    }
  }

  void _addPopular({
    required List<Widget> contentSlivers,
    required List<Station> popularStations,
    required AudioPlayerService audioPlayerService,
    required double screenWidth,
    required AppLocalizations? loc,
  }) {
    if (popularStations.isNotEmpty) {
      contentSlivers.add(
        SliverToBoxAdapter(
          child: CategoryRow(
            title: loc?.translate('homeCategoriesTitle') ?? 'Popular',
            stations: popularStations,
            audioPlayerService: audioPlayerService,
            screenWidth: screenWidth,
          ),
        ),
      );
    }
  }

  void _addDynamicCategories({
    required List<Widget> contentSlivers,
    required Set<String> displayedCategoryNames,
    required List<Station> recentStations,
    required List<Station> popularStations,
    required List<Station> allStations,
    required AudioPlayerService audioPlayerService,
    required double screenWidth,
    required AppLocalizations? loc,
  }) {
    final Set<String> sourceCategories =
        (recentStations.isNotEmpty ? recentStations : popularStations)
            .map((s) => s.category)
            .toSet();

    final Set<String> recentStationIds = recentStations
        .map((s) => s.id)
        .toSet();

    for (final category in sourceCategories) {
      if (displayedCategoryNames.contains(category)) continue;

      final suggestedStations = allStations
          .where(
            (s) => s.category == category && !recentStationIds.contains(s.id),
          )
          .toList();

      if (suggestedStations.length > 2) {
        final String moreFrom = loc?.translate('homeMoreFrom') ?? 'More from';
        contentSlivers.add(
          SliverToBoxAdapter(
            child: CategoryRow(
              title: '$moreFrom $category',
              stations: suggestedStations,
              audioPlayerService: audioPlayerService,
              screenWidth: screenWidth,
            ),
          ),
        );
        displayedCategoryNames.add(category);
      }
    }
  }

  void _addFallbackCategories({
    required List<Widget> contentSlivers,
    required Set<String> displayedCategoryNames,
    required List<Station> allStations,
    required AudioPlayerService audioPlayerService,
    required double screenWidth,
    required AppLocalizations? loc,
  }) {
    if (contentSlivers.length >= _minTotalCategories) return;

    final List<String> allOtherCategories =
        allStations.map((s) => s.category).toSet().toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final String moreFrom = loc?.translate('homeMoreFrom') ?? 'More from';

    for (final category in allOtherCategories) {
      if (contentSlivers.length >= _minTotalCategories) break;
      if (displayedCategoryNames.contains(category)) continue;

      final stations = allStations
          .where((s) => s.category == category)
          .toList();

      if (stations.length > 1) {
        contentSlivers.add(
          SliverToBoxAdapter(
            child: CategoryRow(
              title: '$moreFrom $category',
              stations: stations,
              audioPlayerService: audioPlayerService,
              screenWidth: screenWidth,
            ),
          ),
        );
        displayedCategoryNames.add(category);
      }
    }
  }
}
