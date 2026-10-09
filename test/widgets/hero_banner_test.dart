import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamflix_tv/models/media_item.dart';
import 'package:streamflix_tv/widgets/hero_banner.dart';
import 'package:streamflix_tv/widgets/tv_focus_wrapper.dart';

MediaItem _item(int i) => MediaItem.fromTmdbJson({
  'id': i,
  'title': 'Title $i',
  'poster_path': '/p$i.jpg',
  'backdrop_path': '/b$i.jpg',
  'overview': 'Overview $i',
  'vote_average': 8.0,
  'release_date': '2024-05-10',
  'media_type': 'movie',
});

void main() {
  Future<void> pumpBanner(
    WidgetTester tester, {
    required void Function(MediaItem) onItemTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeroBanner(items: [_item(1), _item(2)], onItemTap: onItemTap),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('Play pill shows the browse-only snackbar instead of navigating', (
    tester,
  ) async {
    var navigated = false;
    await pumpBanner(tester, onItemTap: (_) => navigated = true);

    final play = find.widgetWithText(TvFocusWrapper, 'Play');
    expect(play, findsOneWidget);

    await tester.tap(play);
    await tester.pump(); // start snackbar animation

    expect(find.text('Playback is not available yet.'), findsOneWidget);
    expect(navigated, isFalse, reason: 'Play must not navigate in browse-only mode');

    // Let the snackbar dismiss timer fire, then tear down the hero autoplay
    // timer by unmounting.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Details pill still opens the detail screen', (tester) async {
    MediaItem? opened;
    await pumpBanner(tester, onItemTap: (item) => opened = item);

    await tester.tap(find.widgetWithText(TvFocusWrapper, 'Details'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(opened, isNotNull, reason: 'Details must keep navigating');

    await tester.pumpWidget(const SizedBox());
  });
}
