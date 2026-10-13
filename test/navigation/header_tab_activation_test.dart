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

/// Header wrappers are the last 5: brand, Home, Movies, Shows, Search.
Finder _headerTab(WidgetTester tester, int index) {
  final total = find.byType(TvFocusWrapper).evaluate().length;
  return find.byType(TvFocusWrapper).at(total - 4 + index);
}

FocusNode _nodeOf(WidgetTester tester, Finder wrapper) => tester
    .widget<Focus>(
      find.descendant(of: wrapper, matching: find.byType(Focus)).first,
    )
    .focusNode!;

/// The selected tab is the one whose pill fill is the brand red.
int _selectedTabIndex(WidgetTester tester) {
  final wrappers = find.byType(TvFocusWrapper);
  final total = wrappers.evaluate().length;
  for (var i = 0; i < 4; i++) {
    final pill = find
        .descendant(
          of: wrappers.at(total - 4 + i),
          matching: find.byType(AnimatedContainer),
        )
        .evaluate();
    for (final e in pill) {
      final box = (e.widget as AnimatedContainer).decoration;
      if (box is BoxDecoration &&
          box.color == const Color(0xFFE50914)) {
        return i;
      }
    }
  }
  return -1;
}

int _visibleScreenIndex(WidgetTester tester) =>
    tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;

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

  testWidgets('select on a focused header tab switches the screen', (
    tester,
  ) async {
    await setup(tester);
    expect(_selectedTabIndex(tester), 0, reason: 'Home starts selected');
    expect(_visibleScreenIndex(tester), 0);

    // Focus the Movies tab while Home is still selected: the reported state
    // where the ring sits on Movies but the red fill sits on Home.
    _nodeOf(tester, _headerTab(tester, 1)).requestFocus();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      FocusManager.instance.primaryFocus,
      _nodeOf(tester, _headerTab(tester, 1)),
      reason: 'Movies tab must own primary focus',
    );

    await press(tester, LogicalKeyboardKey.select);

    expect(
      _selectedTabIndex(tester),
      1,
      reason: 'F2: select on the focused header tab must change selection',
    );
    expect(_visibleScreenIndex(tester), 1, reason: 'Movies screen must show');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('select with enter on a focused header tab switches the screen', (
    tester,
  ) async {
    await setup(tester);

    _nodeOf(tester, _headerTab(tester, 2)).requestFocus();
    await tester.pump(const Duration(milliseconds: 100));

    await press(tester, LogicalKeyboardKey.enter);

    expect(
      _selectedTabIndex(tester),
      2,
      reason: 'F2: enter must activate the focused header tab',
    );
    expect(_visibleScreenIndex(tester), 2);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('focus ring and selection stay in sync after activation', (
    tester,
  ) async {
    await setup(tester);

    _nodeOf(tester, _headerTab(tester, 3)).requestFocus();
    await tester.pump(const Duration(milliseconds: 100));
    await press(tester, LogicalKeyboardKey.select);

    expect(_selectedTabIndex(tester), 3);
    expect(
      FocusManager.instance.primaryFocus,
      _nodeOf(tester, _headerTab(tester, 3)),
      reason: 'F3: the tab holding focus must be the selected one',
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a selected tab paints a ring colour its fill can be read '
      'against', (tester) async {
    await setup(tester);

    // Home starts selected: its pill fill is brand red, so the focus ring
    // must not be red too — that is what made the two states unreadable.
    _nodeOf(tester, _headerTab(tester, 0)).requestFocus();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<TvFocusWrapper>(_headerTab(tester, 0)).focusColor,
      Colors.white,
      reason: 'F4: red ring on a red pill hides the focus state',
    );

    // An unselected tab still gets the brand-red ring.
    _nodeOf(tester, _headerTab(tester, 1)).requestFocus();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<TvFocusWrapper>(_headerTab(tester, 1)).focusColor,
      const Color(0xFFE50914),
    );

    await tester.pumpWidget(const SizedBox());
  });
}

