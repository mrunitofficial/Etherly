import 'package:etherly/models/device.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/services/history_service.dart';
import 'package:etherly/widgets/clear_history.dart';
import 'package:etherly/widgets/song_card_item.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:etherly/models/song.dart';
import 'package:etherly/localization/app_localizations.dart';

/// A screen that displays the history of played songs.
class HistoryScreen extends StatelessWidget {
  final ScreenType screenType;
  const HistoryScreen({super.key, required this.screenType});

  String _getDateHeader(DateTime timestamp, AppLocalizations? loc) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final songDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (songDate == today) {
      return loc?.historyToday ?? 'Today';
    } else if (songDate == yesterday) {
      return loc?.historyYesterday ?? 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(timestamp);
    }
  }

  Map<String, List<Song>> _groupSongsByDate(List<Song> songs, AppLocalizations? loc) {
    final Map<String, List<Song>> grouped = {};
    for (final song in songs) {
      final header = _getDateHeader(song.timestamp, loc);
      (grouped[header] ??= []).add(song);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainer,
        title: Text(loc?.historyTitle ?? 'History'),
        actionsPadding: EdgeInsets.symmetric(horizontal: spacing.small),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: loc?.historyClear ?? 'Clear History',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => const ClearHistoryDialog(),
              );
              if (confirm == true) {
                HistoryService().clearHistory();
              }
            },
          ),
        ],
      ),
      body: Consumer<HistoryService>(
        builder: (context, historyService, _) {
          final history = historyService.history;

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc?.historyEmptyTitle ?? 'No songs played yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final groupedSongs = _groupSongsByDate(history, loc);
          final headers = groupedSongs.keys.toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.medium,
                  vertical: spacing.medium,
                ),
                itemCount: history.length + headers.length,
                itemBuilder: (context, index) {
                  // Calculate flat index mapping for headers and song items
                  int currentFlatIndex = 0;
                  for (final header in headers) {
                    final songsForHeader = groupedSongs[header]!;
                    
                    if (currentFlatIndex == index) {
                      // Render Category/Date Header in same style as stations categories
                      return Padding(
                        padding: EdgeInsets.only(
                          top: spacing.medium,
                          bottom: spacing.small,
                        ),
                        child: Text(
                          header,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    currentFlatIndex++; // increment for header index

                    if (index < currentFlatIndex + songsForHeader.length) {
                      final songIndex = index - currentFlatIndex;
                      final item = songsForHeader[songIndex];
                      return Padding(
                        padding: EdgeInsets.only(bottom: spacing.small),
                        child: SongCardItem(
                          songName: item.title,
                          artistName: item.artist.isNotEmpty ? item.artist : 'Unknown Artist',
                          artUrl: item.stationArtUrl,
                          screenType: screenType,
                          onTap: () {},
                          onShare: () {},
                        ),
                      );
                    }
                    currentFlatIndex += songsForHeader.length; // increment for items
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
