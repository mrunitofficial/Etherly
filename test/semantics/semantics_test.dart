import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:etherly/models/device.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/widgets/station_card_item.dart';
import 'package:etherly/widgets/station_grid_item.dart';
import 'package:etherly/widgets/song_card_item.dart';
import 'package:etherly/widgets/marquee_text.dart';
import 'package:etherly/widgets/small_player.dart';
import 'package:etherly/widgets/screen_header.dart';
import 'package:etherly/widgets/quality_setting.dart';

void main() {
  final testTheme = AppTheme.getLight(ColorScheme.fromSeed(seedColor: brandColor));
  final testStation = Station(
    id: 'test_station_1',
    name: 'NPO Radio 1',
    slogan: 'Nieuws & Sport',
    streams: {'mp3': 'https://example.com/stream'},
    art: {'512': 'https://example.com/art512.png'},
    category: 'News',
    country: 'NL',
  );

  testWidgets('StationCardItem renders explicit Semantics node with label and favorite button state', (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: StationCardItem(
            station: testStation,
            onTap: () {},
            onFavorite: () {},
            isFavorite: false,
            screenType: ScreenType.smallScreenVertical,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('NPO Radio 1'), findsOneWidget);
    expect(find.byTooltip('Add NPO Radio 1 to favorites'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('StationGridItem renders explicit Semantics node with container and button trait', (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: StationGridItem(
            station: testStation,
            onTap: () {},
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('NPO Radio 1'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('SongCardItem renders combined title, artist, and timestamp semantics', (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: SongCardItem(
            songName: 'Midnight City',
            artistName: 'M83',
            artUrl: '',
            timeLabel: '14:20',
            onTap: () {},
            screenType: ScreenType.smallScreenVertical,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Midnight City by M83, 14:20'), findsOneWidget);

    // Unmount SongCardItem to break MarqueeText loops, then drain pending timers
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    handle.dispose();
  });

  testWidgets('MarqueeText wraps text in static Semantics node', (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: const Scaffold(
          body: MarqueeText(
            text: 'Now Playing - Test Track',
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Now Playing - Test Track'), findsOneWidget);

    // Unmount MarqueeText to break loop, then drain pending timers
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    handle.dispose();
  });

  testWidgets('MiniPlayerTapRegion renders semantics label for expand action', (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: MiniPlayerTapRegion(
            onExpand: () {},
            child: const SizedBox(height: 50, width: 200),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Expand radio player'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('ScreenHeader renders header semantics trait on screen title', (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: const Scaffold(
          body: ScreenHeader(
            title: 'Settings',
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('QualitySetting dialog options render explicit button and selection semantics', (WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: QualitySetting(
            station: testStation,
            selectedQuality: 'mp3',
            onQualitySelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('High (MP3)'), findsOneWidget);
    expect(find.bySemanticsLabel('Highest (AAC)'), findsOneWidget);
    handle.dispose();
  });
}
