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
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _allWrappers() => find.byType(TvFocusWrapper);

FocusNode _nodeAt(WidgetTester tester, int i) => tester.widget<Focus>(
  find
      .descendant(of: _allWrappers().at(i), matching: find.byType(Focus))
      .first,
).focusNode!;

/// Header = last 5 wrappers: brand, Home, Movies, Shows, Search.
int _headerIndex(int i) => _allWrappers().evaluate().length - 5 + i;

bool _focusInHeader(WidgetTester tester) {
  final primary = FocusManager.instance.primaryFocus;
  if (primary == null) return false;
  for (var i = 0; i < 5; i++) {
    if (_nodeAt(tester, _headerIndex(i)) == primary) return true;
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

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('RIGHT from brand keeps focus in the header when content is '
      'scrolled under it', (tester) async {
    await setup(tester);

    // Focus the hero Play button, then scroll content under the floating
    // header — the state the bug report was captured in.
    _nodeAt(tester, 0).requestFocus();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -500),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await press(tester, LogicalKeyboardKey.arrowUp); // escape hatch -> brand
    expect(_focusInHeader(tester), isTrue, reason: 'UP must reach the header');

    await press(tester, LogicalKeyboardKey.arrowRight);

    expect(
      _focusInHeader(tester),
      isTrue,
      reason:
          'RIGHT from the brand must stay in the header and focus the Home tab, '
          'but focus escaped to ${FocusManager.instance.primaryFocus?.rect}',
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('RIGHT from the Search tab does not escape the header', (
    tester,
  ) async {
    await setup(tester);

    _nodeAt(tester, _headerIndex(4)).requestFocus(); // Search
    await tester.pump(const Duration(milliseconds: 100));

    await press(tester, LogicalKeyboardKey.arrowRight);

    expect(
      _focusInHeader(tester),
      isTrue,
      reason:
          'RIGHT at the end of the header must not drop focus into the content, '
          'but focus escaped to ${FocusManager.instance.primaryFocus?.rect}',
    );

    await tester.pumpWidget(const SizedBox());
  });
}
