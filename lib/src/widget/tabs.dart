import 'package:flutter/widgets.dart';
import 'package:octopus/octopus.dart';

/// Builds the UI for tabs, providing the current child widget
/// and control callbacks.
typedef OctopusTabsBuilder = Widget Function(
  BuildContext context,
  Widget child,
  int currentIndex,
  ValueChanged<int> onTabPressed,
);

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
    this.tabIdentifier = 'tab',
    this.clearStackOnDoubleTap = true,
    this.onBackButtonPressed,
    super.key,
  }) : assert(tabs.length > 0, 'Tabs should contain at least 1 route');

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
  final Future<bool> Function(BuildContext context, NavigatorState navigator)?
      onBackButtonPressed;

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

    // Initialize the root branch structure after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.octopus.setState((state) {
        final root = state.findByName(widget.root.name);

        if (root == null) return state; // Do nothing if `root` not found.

        // Keep only branches matching our tabs, remove others.
        final validNames = widget.tabs.map(_tabRouteName).toSet();
        root.removeWhere(
          (node) => !validNames.contains(node.name),
          recursive: true,
        );

        // Ensure each tab branch exists under root.
        for (final tab in widget.tabs) {
          final bucketName = _tabRouteName(tab);
          final branch = root.putIfAbsent(
              bucketName, () => OctopusNode.mutable(bucketName));
          if (!branch.hasChildren) branch.add(OctopusNode.mutable(tab.name));
        }

        return state;
      });
    });

    _octopusStateObserver = context.octopus.observer;

    // Restore active tab from router args or default to first.
    _tab = widget.tabs.firstWhere(
      (t) =>
          t.name == _octopusStateObserver.value.arguments[widget.tabIdentifier],
      orElse: () => widget.tabs.first,
    );

    _octopusStateObserver.addListener(_onOctopusStateChanged);
  }

  @override
  void dispose() {
    _octopusStateObserver.removeListener(_onOctopusStateChanged);
    super.dispose();
  }

  // Pop to catalog at double tap on catalog tab
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
        IndexedStack(
          index: _activeIndex,
          children: widget.tabs
              .map(
                (tab) => _TabBucketNavigator(
                  route: tab,
                  tabIdentifier: widget.tabIdentifier,
                  onBackButtonPressed: widget.onBackButtonPressed,
                ),
              )
              .toList(),
        ),
        _activeIndex,
        _onPressed,
      );
}

/// {@template tabs}
/// _TabBucketNavigator widget.
/// {@endtemplate}
class _TabBucketNavigator extends StatelessWidget {
  /// {@macro tabs}
  const _TabBucketNavigator({
    required this.route,
    required this.tabIdentifier,
    this.onBackButtonPressed,
  });

  /// The root route of the tab branch navigator.
  final OctopusRoute route;

  /// The unique identifier for the tabs.
  final String tabIdentifier;

  /// Callback for back button pressed.
  final Future<bool> Function(BuildContext context, NavigatorState navigator)?
      onBackButtonPressed;

  @override
  Widget build(BuildContext context) => BucketNavigator(
        bucket: '${route.name}-$tabIdentifier',
        // Handle back button only if the route is within tab's branch
        shouldHandleBackButton: (_) =>
            Octopus.instance.state.arguments[tabIdentifier] == route.name,
        onBackButtonPressed: onBackButtonPressed,
      );
}
