import 'package:flutter/widgets.dart';
import 'package:octopus/octopus.dart';
import 'package:octopus/src/widget/lazy_indexed_stack.dart';

/// Builds the UI for tabs, providing the current child widget
/// and control callbacks.
typedef OctopusTabsBuilder = Widget Function(
  BuildContext context,
  Widget child,
  int currentIndex,
  ValueChanged<int> onTabPressed,
);

/// Callback for back button pressed.
typedef OctopusOnBackButtonPressed = Future<bool> Function(
    BuildContext context, NavigatorState navigator);

/// Callback builder for rendering a stack of tabs.
typedef OctopusTabStackBuilder = Widget Function(
  BuildContext context,
  int index,
  List<OctopusRoute> tabs,
  String tabIdentifier,
  OctopusTabsVariant variant,
  OctopusTabBuilder tabBuilder,
  OctopusOnBackButtonPressed? onBackButtonPressed,
);

/// Callback builder for rendering a single tab.
typedef OctopusTabBuilder = Widget Function(
  BuildContext context,
  OctopusRoute route,
  String tabIdentifier,
  OctopusOnBackButtonPressed? onBackButtonPressed,
);

/// Callback when the tab is changed.
typedef OctopusOnTabChanged = void Function(int index, OctopusRoute tab);

/// Variant of tabs to use.
enum OctopusTabsVariant {
  /// Normal variant. Renders all tabs immediately.
  normal,

  /// Lazy variant. Renders tabs on demand.
  lazy,
}

/// {@template octopus_tabs}
/// Helper Widget to create tabs with internal navigators
/// {@endtemplate}
class OctopusTabs extends StatefulWidget {
  /// Creates an [OctopusTabs] widget.
  ///
  /// {@macro octopus_tabs}
  const OctopusTabs({
    required this.root,
    required this.tabs,
    required this.builder,
    this.variant = OctopusTabsVariant.normal,
    this.tabIdentifier = 'tab',
    this.clearStackOnDoubleTap = true,
    this.onBackButtonPressed,
    this.tabStackBuilder = _defaultTabStackBuilder,
    this.tabBuilder = _defaultTabBuilder,
    this.onTabChanged,
    super.key,
  }) : assert(tabs.length > 0, 'Tabs should contain at least 1 route');

  /// Creates an [OctopusTabs] widget with lazy tabs stack rendering.
  ///
  /// {@macro octopus_tabs}
  const OctopusTabs.lazy({
    required this.root,
    required this.tabs,
    required this.builder,
    this.tabIdentifier = 'tab',
    this.clearStackOnDoubleTap = true,
    this.onBackButtonPressed,
    this.tabStackBuilder = _defaultTabStackBuilder,
    this.tabBuilder = _defaultTabBuilder,
    this.onTabChanged,
    super.key,
  })  : assert(tabs.length > 0, 'Tabs should contain at least 1 route'),
        variant = OctopusTabsVariant.lazy;

  /// Unique key used to store and retrieve the active tab in router args.
  final String tabIdentifier;

  /// The base route node under which tab branches are managed.
  final OctopusRoute root;

  /// List of routes representing each tab branch.
  final List<OctopusRoute> tabs;

  /// Callback builder for rendering tabs and content.
  final OctopusTabsBuilder builder;

  /// Whether tapping the active tab twice clears its navigation stack.
  final bool clearStackOnDoubleTap;

  /// Callback for back button pressed.
  final OctopusOnBackButtonPressed? onBackButtonPressed;

  /// Callback builder for rendering tabs.
  final OctopusTabStackBuilder tabStackBuilder;

  /// Variant of tabs to use.
  final OctopusTabsVariant variant;

  /// Callback builder for rendering a single tab.
  final OctopusTabBuilder tabBuilder;

  /// Callback when the tab is changed.
  final OctopusOnTabChanged? onTabChanged;

  /// Default callback builder for rendering a single tab.
  static Widget _defaultTabBuilder(
          BuildContext context,
          OctopusRoute route,
          String tabIdentifier,
          OctopusOnBackButtonPressed? onBackButtonPressed) =>
      TabBucketNavigator(
        route: route,
        tabIdentifier: tabIdentifier,
        onBackButtonPressed: onBackButtonPressed,
      );

  /// Default callback builder for rendering a stack of tabs.
  static Widget _defaultTabStackBuilder(
          BuildContext context,
          int index,
          List<OctopusRoute> tabs,
          String tabIdentifier,
          OctopusTabsVariant variant,
          OctopusTabBuilder tabBuilder,
          OctopusOnBackButtonPressed? onBackButtonPressed) =>
      switch (variant) {
        OctopusTabsVariant.normal => IndexedStack(
            index: index,
            children: [
              for (final tab in tabs)
                tabBuilder(context, tab, tabIdentifier, onBackButtonPressed)
            ],
          ),
        OctopusTabsVariant.lazy => LazyIndexedStack(
            index: index,
            itemCount: tabs.length,
            itemBuilder: (index) => tabBuilder(
              context,
              tabs[index],
              tabIdentifier,
              onBackButtonPressed,
            ),
          ),
      };

  @override
  State<OctopusTabs> createState() => _OctopusTabsState();
}

class _OctopusTabsState extends State<OctopusTabs> {
  // Octopus state observer
  late final OctopusStateObserver _octopusStateObserver;

  // Current tab
  late OctopusRoute _tab;

  // Current tab index
  int get _activeIndex => widget.tabs.indexOf(_tab);

  // Generate unique bucket name for a route's navigator branch.
  String _tabRouteName(OctopusRoute route) =>
      '${route.name}-${widget.tabIdentifier}';

  @override
  void initState() {
    super.initState();
    _octopusStateObserver = context.octopus.observer;

    // Restore active tab from router args or default to first.
    _tab = widget.tabs.firstWhere(
      (t) =>
          t.name == _octopusStateObserver.value.arguments[widget.tabIdentifier],
      orElse: () => widget.tabs.first,
    );
    
    widget.onTabChanged?.call(_activeIndex, _tab);

    _octopusStateObserver.addListener(_onOctopusStateChanged);
  }

  @override
  void dispose() {
    _octopusStateObserver.removeListener(_onOctopusStateChanged);
    super.dispose();
  }

  // Pop to root tab at double tap on current tab
  void _clearNavigationStack() {
    context.octopus.setState((state) {
      final branch = state.findByName(_tabRouteName(_tab));
      if (branch == null || branch.children.length < 2) return state;
      branch.children.length = 1;
      return state;
    });
  }

  // Change tab
  void _switchTab(OctopusRoute tab) {
    if (!mounted) return;
    if (_tab == tab) return;
    context.octopus.setArguments(
      (args) => args[widget.tabIdentifier] = tab.name,
    );
    setState(() => _tab = tab);
    widget.onTabChanged?.call(_activeIndex, _tab);
  }

  // Tab item pressed
  void _onPressed(int index) {
    final newTab = widget.tabs[index];
    if (_tab == newTab) {
      // Double-tap: clear stack if enabled.
      if (widget.clearStackOnDoubleTap) _clearNavigationStack();
    } else {
      // Switch tab to new one
      _switchTab(newTab);
    }
  }

  // Router state changed
  void _onOctopusStateChanged() {
    final newTab = widget.tabs.firstWhere(
      (t) =>
          t.name == _octopusStateObserver.value.arguments[widget.tabIdentifier],
      orElse: () => widget.tabs.first,
    );
    _switchTab(newTab);
  }

  @override
  Widget build(BuildContext context) => widget.builder(
        context,
        widget.tabStackBuilder(
          context,
          _activeIndex,
          widget.tabs,
          widget.tabIdentifier,
          widget.variant,
          widget.tabBuilder,
          widget.onBackButtonPressed,
        ),
        _activeIndex,
        _onPressed,
      );
}

/// {@template tabs}
/// TabBucketNavigator widget.
/// {@endtemplate}
class TabBucketNavigator extends StatelessWidget {
  /// {@macro tabs}
  const TabBucketNavigator({
    required this.route,
    required this.tabIdentifier,
    this.onBackButtonPressed,
    super.key,
  });

  /// The root route of the tab branch navigator.
  final OctopusRoute route;

  /// The unique identifier for the tabs.
  final String tabIdentifier;

  /// Callback for back button pressed.
  final OctopusOnBackButtonPressed? onBackButtonPressed;

  @override
  Widget build(BuildContext context) => BucketNavigator(
        bucket: '${route.name}-$tabIdentifier',
        // Handle back button only if the route is within tab's branch
        shouldHandleBackButton: (_) =>
            Octopus.instance.state.arguments[tabIdentifier] == route.name,
        onBackButtonPressed: onBackButtonPressed,
      );
}
