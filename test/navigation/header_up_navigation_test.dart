import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:streamflix_tv/models/media_item.dart';
import 'package:streamflix_tv/navigation/app_navigation.dart';
import 'package:streamflix_tv/providers/media_provider.dart';
import 'package:streamflix_tv/providers/search_provider.dart';
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

List<MediaItem> _items(int n) => [for (var i = 0; i < n; i++) _item(i)];

/// Pumps the real AppNavigation with preset data (network calls fail fast in
/// tests and leave preset data untouched).
Future<void> _pumpApp(WidgetTester tester) async {
  final media = MediaProvider()
    ..trendingMovies = _items(8)
    ..trendingTv = _items(8)
    ..popularMovies = _items(8)
    ..popularTv = _items(8)
    ..topRatedMovies = _items(8)
    ..topRatedTv = _items(8)
    ..isHomeLoading = false
    ..isMoviesLoading = false
    ..isShowsLoading = false;

  await tester.pumpWidget(
    MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<MediaProvider>.value(value: media),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
        ],
        child: const AppNavigation(),
      ),
    ),
  );
  // Bounded pumps: hero autoplay timer + shimmer animations never settle.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _focusOn(WidgetTester tester, Finder wrapper) {
  final focusWidget = tester.widget<Focus>(
    find.descendant(of: wrapper, matching: find.byType(Focus)).first,
  );
  focusWidget.focusNode!.requestFocus();
}

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump(const Duration(milliseconds: 300));
}

FocusNode _nodeOf(WidgetTester tester, Finder wrapper) => tester
    .widget<Focus>(
      find.descendant(of: wrapper, matching: find.byType(Focus)).first,
    )
    .focusNode!;

bool _focusInHeader(WidgetTester tester) {
  final focus = FocusManager.instance.primaryFocus;
  if (focus == null) return false;
  final wrappers = find.byType(TvFocusWrapper);
  final total = wrappers.evaluate().length;
  // The header is the last 5 TvFocusWrappers (brand + 4 nav tabs).
  for (var i = total - 5; i < total; i++) {
    if (_nodeOf(tester, wrappers.at(i)) == focus) return true;
  }
  return false;
}

void main() {
  Future<void> setup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await _pumpApp(tester);
  }

  testWidgets('UP from hero Play at scroll offset 0 reaches the header', (
    tester,
  ) async {
    await setup(tester);
    final wrappers = find.byType(TvFocusWrapper);
    _focusOn(tester, wrappers.first); // hero Play button (autofocus target)
    await tester.pump(const Duration(milliseconds: 100));

    await _press(tester, LogicalKeyboardKey.arrowUp);

    expect(_focusInHeader(tester), isTrue, reason: 'UP from hero must focus header');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'UP from content scrolled under the floating header still reaches it',
    (tester) async {
      await setup(tester);
      final wrappers = find.byType(TvFocusWrapper);
      _focusOn(tester, wrappers.first); // hero Play button
      await tester.pump(const Duration(milliseconds: 100));

      // Scroll the home content down so the focused widget sits under the
      // floating header overlay (this is the reported failure state).
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 400));

      final focus = FocusManager.instance.primaryFocus!;
      debugPrint('after drag: focus rect=${focus.rect}');

      // Press UP repeatedly: navigation through content rows must eventually
      // hand focus to the floating header instead of stalling.
      var reached = false;
      for (var i = 0; i < 8 && !reached; i++) {
        await _press(tester, LogicalKeyboardKey.arrowUp);
        reached = _focusInHeader(tester);
        debugPrint('UP#$i reachedHeader=$reached focus=${FocusManager.instance.primaryFocus?.rect}');
      }

      expect(
        reached,
        isTrue,
        reason:
            'UP must hand focus to the floating header when content has scrolled under it; '
            'focus ended at ${FocusManager.instance.primaryFocus?.rect}',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
