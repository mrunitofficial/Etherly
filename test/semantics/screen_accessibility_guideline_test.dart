import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:etherly/models/device.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/widgets/station_card_item.dart';
import 'package:etherly/widgets/station_grid_item.dart';

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

  testWidgets('StationCardItem complies with labeled tap target accessibility guidelines', (WidgetTester tester) async {
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

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('StationGridItem complies with labeled tap target accessibility guidelines', (WidgetTester tester) async {
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

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
