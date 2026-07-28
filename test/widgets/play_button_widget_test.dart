import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/widgets/play_button.dart';

class MockAudioPlayerService extends Fake implements AudioPlayerService {
  bool mockIsPlaying = false;
  bool mockIsLoading = false;

  @override
  bool get isPlaying => mockIsPlaying;

  @override
  bool get isLoading => mockIsLoading;
}

void main() {
  group('PlayButton Widget Tests', () {
    late MockAudioPlayerService mockService;

    setUp(() {
      mockService = MockAudioPlayerService();
    });

    testWidgets('Renders play icon when stopped and not loading', (WidgetTester tester) async {
      mockService.mockIsPlaying = false;
      mockService.mockIsLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayButton(
              service: mockService,
              countdown: 0,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
    });

    testWidgets('Renders pause icon when currently playing', (WidgetTester tester) async {
      mockService.mockIsPlaying = true;
      mockService.mockIsLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayButton(
              service: mockService,
              countdown: 0,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('Renders CircularProgressIndicator when loading stream', (WidgetTester tester) async {
      mockService.mockIsPlaying = true;
      mockService.mockIsLoading = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayButton(
              service: mockService,
              countdown: 0,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Renders countdown text when sleep timer is active', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayButton(
              service: mockService,
              countdown: 15,
            ),
          ),
        ),
      );

      expect(find.text('15'), findsOneWidget);
    });
  });
}
