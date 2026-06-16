import 'package:url_launcher/url_launcher.dart';

class MusicApp {
  final String id;
  final String name;

  const MusicApp({
    required this.id,
    required this.name,
  });

  /// Returns the launch URI for a given search query on this music app.
  Uri getSearchUri(String queryText) {
    final query = Uri.encodeComponent(queryText);
    return switch (id) {
      'youtube' => Uri.parse('vnd.youtube://results?search_query=$query'),
      'ytmusic' => Uri.parse('https://music.youtube.com/search?q=$query'),
      'spotify' => Uri.parse('spotify:search:$query'),
      'apple_music' => Uri.parse('https://music.apple.com/search?term=$query'),
      'tidal' => Uri.parse('tidal://search/$query'),
      'soundcloud' => Uri.parse('soundcloud://search?q=$query'),
      'amazon' => Uri.parse('https://music.amazon.com/search/$query'),
      'internet_search' || _ => Uri.parse('https://www.google.com/search?q=$query'),
    };
  }

  /// Returns the fallback launch URI if the primary deep link fails (mostly web fallbacks).
  Uri? getFallbackUri(String queryText) {
    final query = Uri.encodeComponent(queryText);
    return switch (id) {
      'youtube' => Uri.parse('https://www.youtube.com/results?search_query=$query'),
      'internet_search' => Uri.parse('https://www.google.com/search?q=$query'),
      _ => null,
    };
  }

  /// Launches the search query on the specific music app.
  Future<bool> launchSearch(String queryText) async {
    final primaryUri = getSearchUri(queryText);
    
    // Attempt primary app deep link
    try {
      final success = await launchUrl(
        primaryUri,
        mode: id == 'internet_search'
            ? LaunchMode.platformDefault
            : LaunchMode.externalNonBrowserApplication,
      );
      if (success) return true;
    } catch (_) {}

    // Attempt fallback web-based URI if primary deep link failed
    final fallbackUri = getFallbackUri(queryText);
    if (fallbackUri != null) {
      try {
        return await launchUrl(fallbackUri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }

    return false;
  }
}
