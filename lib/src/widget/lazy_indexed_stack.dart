import 'package:flutter/material.dart';

/// {@template lazy_indexed_stack}
/// A stack that only builds its children when they are accessed for the first
/// time.
/// This is useful for implementing lazy loading in tab-based navigation where
/// you don't want to build all pages immediately.
/// {@endtemplate}
class LazyIndexedStack extends StatefulWidget {
  /// {@macro lazy_indexed_stack}
  const LazyIndexedStack({
    required this.index,
    required this.itemCount,
    required this.itemBuilder,
    super.key,
    this.sizing = StackFit.loose,
    this.alignment = AlignmentDirectional.topStart,
    this.clipBehavior = Clip.hardEdge,
    this.textDirection,
  });

  /// The index of the child to show.
  final int index;

  /// The total number of children.
  final int itemCount;

  /// A builder function that creates a child widget for the given index.
  /// This function is only called once per index when the child is first
  /// accessed.
  final Widget Function(int index) itemBuilder;

  /// How to size the non-positioned children in the stack.
  final StackFit sizing;

  /// How to align the non-positioned and partially-positioned children in the
  /// stack.
  final AlignmentGeometry alignment;

  /// The text direction with which to resolve [alignment].
  final TextDirection? textDirection;

  /// The clip behavior for the IndexedStack.
  final Clip clipBehavior;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  /// Cache to store built widgets to avoid rebuilding them
  final Map<int, Widget> _children = {};

  @override
  Widget build(BuildContext context) {
    // Build the current widget if it hasn't been built yet
    if (!_children.containsKey(widget.index)) {
      _children[widget.index] = widget.itemBuilder(widget.index);
    }

    // Create a list of widgets for the IndexedStack
    // Only include widgets that have been built
    final children = List<Widget>.generate(
      widget.itemCount,
      (index) {
        if (_children.containsKey(index)) {
          return _children[index]!;
        }
        // Return an empty container for unbuilt widgets
        return const SizedBox.shrink();
      },
    );

    return IndexedStack(
      index: widget.index,
      sizing: widget.sizing,
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      clipBehavior: widget.clipBehavior,
      children: children,
    );
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clear cache if itemCount changed (though this shouldn't happen in normal
    // usage)
    if (oldWidget.itemCount != widget.itemCount) {
      _children.clear();
    }
  }
}
