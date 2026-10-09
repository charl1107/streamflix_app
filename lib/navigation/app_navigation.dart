import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streamflix_tv/screens/home_screen.dart';
import 'package:streamflix_tv/screens/movies_screen.dart';
import 'package:streamflix_tv/screens/shows_screen.dart';
import 'package:streamflix_tv/screens/search_screen.dart';
import 'package:streamflix_tv/widgets/tv_focus_wrapper.dart';
import 'package:streamflix_tv/config/tv_layout.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedIndex = 0;

  // Externally-owned focus nodes for the floating header. They let the D-pad
  // UP handler below recognize "focus is in the header" and hand focus to the
  // brand node when the default traversal cannot reach it.
  late final List<FocusNode> _headerFocusNodes;

  @override
  void initState() {
    super.initState();
    _headerFocusNodes = [
      FocusNode(debugLabel: 'header-brand'),
      for (var i = 0; i < _destinations.length; i++)
        FocusNode(debugLabel: 'header-tab-$i'),
    ];
  }

  @override
  void dispose() {
    for (final node in _headerFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool _isHeaderNode(FocusNode node) => _headerFocusNodes.contains(node);

  /// D-pad UP escape hatch for the floating header overlay.
  ///
  /// The header is a [Positioned] overlay *outside* the content's vertical
  /// [Scrollable], while every focusable screen element is *inside* one.
  /// Flutter's [DirectionalTraversalPolicy] therefore (a) restricts UP
  /// candidates to the same scrollable whenever any exist, and (b) only
  /// considers nodes whose center is strictly above the focused node's top
  /// edge. Once the content scrolls under the header, the header is
  /// geometrically no longer "above", so the default traversal stops and UP
  /// goes dead.
  ///
  /// This handler only takes over in exactly that case; every other key press
  /// is returned to the framework untouched.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.ignored;
    }
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null || primary.context == null || _isHeaderNode(primary)) {
      return KeyEventResult.ignored;
    }
    final contentScrollable = Scrollable.maybeOf(
      primary.context!,
      axis: Axis.vertical,
    );
    if (contentScrollable == null) {
      // Not inside a vertical scroll view (e.g. the search field): leave the
      // default behavior alone.
      return KeyEventResult.ignored;
    }

    bool traversable(FocusNode n) =>
        n.canRequestFocus && !n.skipTraversal && n.context != null;

    final scope = primary.nearestScope;
    if (scope == null) {
      return KeyEventResult.ignored;
    }

    // Focusable content still above us inside the same scrollable? Then the
    // default traversal walks the content rows correctly - stay out of the way.
    final contentAbove = scope.traversalDescendants.any(
      (n) =>
          n != primary &&
          traversable(n) &&
          Scrollable.maybeOf(n.context!, axis: Axis.vertical) ==
              contentScrollable &&
          n.rect.center.dy <= primary.rect.top,
    );
    if (contentAbove) {
      return KeyEventResult.ignored;
    }

    // We are at the top of the content. The default traversal can still reach
    // the header if any header node is geometrically above us - let it.
    final headerAbove = _headerFocusNodes.any(
      (n) => traversable(n) && n.rect.center.dy <= primary.rect.top,
    );
    if (headerAbove || !_headerFocusNodes.any(traversable)) {
      return KeyEventResult.ignored;
    }

    // Content is scrolled under the header: nothing is geometrically above,
    // so the framework would stop here. Hand focus to the header explicitly.
    _headerFocusNodes.first.requestFocus();
    return KeyEventResult.handled;
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    MoviesScreen(),
    ShowsScreen(),
    SearchScreen(),
  ];

  final List<_NavDestination> _destinations = const [
    _NavDestination(title: 'Home', icon: Icons.home_rounded),
    _NavDestination(title: 'Movies', icon: Icons.movie_rounded),
    _NavDestination(title: 'Shows', icon: Icons.tv_rounded),
    _NavDestination(title: 'Search', icon: Icons.search_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Focus(
        // Non-focusable, traversal-invisible interceptor: key events bubble
        // through it on their way to the app-level Shortcuts.
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          children: [
            // Content screen occupying 100% width and height
            Positioned.fill(
              child: IndexedStack(index: _selectedIndex, children: _screens),
            ),

            // Floating Frosted Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  TvLayout.horizontalInset(context),
                  TvLayout.headerTopInset(context),
                  TvLayout.horizontalInset(context),
                  TvLayout.headerTopInset(context) + 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.95),
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                ),
                child: Row(
                  children: [
                    // Cineko Brand Header (Focusable — takes user to Home screen)
                    TvFocusWrapper(
                      focusNode: _headerFocusNodes.first,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 0;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Cineko Red Playback Ring Logo
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF141417),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE50914),
                                  width: 2.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFE50914,
                                    ).withValues(alpha: 0.45),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: Color(0xFFE50914),
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'CINEKO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  'YOUR OPEN CINEMA',
                                  style: TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: TvLayout.sectionGap(context) * 2),

                    // Navigation Tabs (Pill style matching streamflix-cf)
                    Expanded(
                      child: Row(
                        children: List.generate(_destinations.length, (index) {
                          final dest = _destinations[index];
                          final isSelected = _selectedIndex == index;

                          return Padding(
                            padding: const EdgeInsets.only(right: 14.0),
                            child: TvFocusWrapper(
                              focusNode: _headerFocusNodes[index + 1],
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE50914)
                                      : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFE50914)
                                        : const Color(0x2EFFFFFF),
                                    width: 1.2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFE50914,
                                            ).withValues(alpha: 0.45),
                                            blurRadius: 14,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 9,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        dest.icon,
                                        size: 17,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        dest.title,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white70,
                                          fontSize: 14.5,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavDestination {
  final String title;
  final IconData icon;

  const _NavDestination({required this.title, required this.icon});
}
