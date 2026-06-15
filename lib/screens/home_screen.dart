import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/widgets/screen_header.dart';
import 'package:etherly/widgets/category_row.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int _minTotalCategories = 8;

typedef ContentLoadedCallback = void Function();

class HomeScreen extends StatefulWidget {
  final ContentLoadedCallback? onContentLoaded;
  final double bottomPadding;
  final bool isActive;
  const HomeScreen({
    super.key,
    this.onContentLoaded,
    this.bottomPadding = 0.0,
    this.isActive = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isInitialized = false;
  bool _showLoading = false;
  Timer? _loadingTimer;
  Future<void>? _initializationFuture;

  static bool _hasFetchedThisSession = false;

  List<Station> _stations = [];
  List<Station> _favoriteStations = [];
  List<Station> _recentStations = [];
  List<Station> _regionalStations = [];
  List<String> _topRegionalNames = [];
  bool _loadingRegional = false;

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
      _updateData();
      await _loadCachedRegionalStations();
      _fetchRegionalStations();
      setState(() => _isInitialized = true);
      widget.onContentLoaded?.call();
    }
  }

  Future<void> _loadCachedRegionalStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedNames = prefs.getStringList('cached_top_regional_names');
      if (cachedNames != null && cachedNames.isNotEmpty && mounted) {
        setState(() {
          _topRegionalNames = cachedNames;
        });
        _updateRegionalStations();
      }
    } catch (_) {}
  }

  void _updateData() {
    if (!mounted) return;
    final audioService = context.read<AudioPlayerService>();
    setState(() {
      _stations = List.from(audioService.stations);
      _favoriteStations = List.from(audioService.favoriteStations);
      _recentStations = List.from(audioService.recentStations);
    });
    _updateRegionalStations();
  }

  void _updateRegionalStations() {
    final List<Station> matchedStations = [];
    final Set<String> matchedIds = {};

    for (final apiName in _topRegionalNames) {
      final match = _stations.cast<Station?>().firstWhere((s) {
        if (s == null) return false;
        final cleanApi = apiName
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
            .toLowerCase();
        final cleanLocal = s.name
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
            .toLowerCase();
        return cleanLocal == cleanApi ||
            cleanLocal.contains(cleanApi) ||
            cleanApi.contains(cleanLocal);
      }, orElse: () => null);

      if (match != null && !matchedIds.contains(match.id)) {
        matchedStations.add(match);
        matchedIds.add(match.id);
      }
    }

    setState(() {
      _regionalStations = matchedStations;
    });
  }

  Future<void> _fetchRegionalStations() async {
    if (_hasFetchedThisSession) return;
    if (_loadingRegional) return;
    setState(() {
      _loadingRegional = true;
    });

    try {
      String? countryCode;

      // 1. Try system preferred locale country code from OS
      try {
        countryCode = ui.PlatformDispatcher.instance.locale.countryCode;
      } catch (_) {}

      // 2. Try Flutter context-based country code
      if (countryCode == null || countryCode.isEmpty) {
        final locale = Localizations.maybeLocaleOf(context);
        countryCode = locale?.countryCode;
      }

      // 3. Try IP geolocation API (fast fallback with 3-second timeout)
      if (countryCode == null || countryCode.isEmpty) {
        try {
          final geoResponse = await http
              .get(Uri.parse('https://ipapi.co/json/'))
              .timeout(const Duration(seconds: 3));
          if (geoResponse.statusCode == 200) {
            final geoData = jsonDecode(geoResponse.body);
            countryCode = geoData['country_code'] as String?;
          }
        } catch (_) {}
      }

      // 4. Default fallback
      countryCode = (countryCode == null || countryCode.isEmpty)
          ? 'NL'
          : countryCode.toUpperCase();

      final response = await http
          .get(
            Uri.parse(
              'https://all.api.radio-browser.info/json/stations/search?countrycode=$countryCode&order=clickcount&reverse=true&limit=15',
            ),
            headers: {'User-Agent': 'Etherly/1.0'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final names = data
            .map((json) => (json['name'] ?? '') as String)
            .where((name) => name.isNotEmpty)
            .toList();

        _hasFetchedThisSession = true;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('cached_top_regional_names', names);
        } catch (_) {}

        if (mounted) {
          setState(() {
            _topRegionalNames = names;
          });
          _updateRegionalStations();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching regional stations: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingRegional = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _updateData();
      _fetchRegionalStations();
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

    final sections = _getSections(
      context,
      _stations,
      _favoriteStations,
      _recentStations,
    );

    return CustomScrollView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(4000.0),
      slivers: [
        SliverToBoxAdapter(
          child: ScreenHeader(title: loc?.homeWelcome ?? 'Etherly'),
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
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: spacing.medium),
                  Text(
                    loc?.homeEmptyTitle ?? 'No stations',
                    style: theme.textTheme.headlineMedium,
                  ),
                  SizedBox(height: spacing.small),
                  Text(
                    loc?.homeEmptySubtitle ?? 'No radio stations available',
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
    List<Station> favoriteStations,
    List<Station> recentStations,
  ) {
    final loc = AppLocalizations.of(context);
    final List<({String title, List<Station> stations})> sections = [];
    final Set<String> displayedCategories = {};

    // 1. Favorites
    if (favoriteStations.isNotEmpty) {
      sections.add((
        title: loc?.homeFavoritesTitle ?? 'Favorites',
        stations: favoriteStations,
      ));
    }

    // 2. Recents
    if (recentStations.isNotEmpty) {
      sections.add((
        title: loc?.homeRecentsTitle ?? 'Recents',
        stations: recentStations,
      ));
    }

    final popular = allStations.where((s) => s.rank != null).toList()
      ..sort((a, b) => (a.rank ?? 999).compareTo(b.rank ?? 999));

    // 3. Regional Popular Stations
    if (_regionalStations.isNotEmpty) {
      sections.add((
        title: loc?.homeCategoriesTitle ?? 'Popular',
        stations: _regionalStations,
      ));
    }

    // Fallback Popular (from database ranks)
    if (_regionalStations.isEmpty && popular.isNotEmpty) {
      sections.add((
        title: loc?.homeCategoriesTitle ?? 'Popular',
        stations: popular,
      ));
    }

    // 4. Dynamic Categories
    final sourceStations = recentStations.isNotEmpty ? recentStations : popular;
    final recentIds = recentStations.map((s) => s.id).toSet();
    final String moreFromPrefix = loc?.homeMoreFrom ?? 'More from';

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
