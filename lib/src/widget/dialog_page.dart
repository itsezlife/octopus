import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// Declarative page that creates a [RawDialogRoute] with a [RoutePageBuilder],
/// matching [showGeneralDialog] behavior (animated page content).
@internal
class OctopusGeneralDialogPage extends Page<Object?> {
  const OctopusGeneralDialogPage({
    required this.pageBuilder,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.barrierDismissible = false,
    this.barrierLabel,
    this.barrierColor = const Color(0x80000000),
    this.transitionDuration = const Duration(milliseconds: 200),
    this.transitionBuilder,
    this.requestFocus,
    this.anchorPoint,
    this.traversalEdgeBehavior,
    this.directionalTraversalEdgeBehavior,
    this.fullscreenDialog = false,
  });

  final RoutePageBuilder pageBuilder;
  final bool barrierDismissible;
  final String? barrierLabel;
  final Color? barrierColor;
  final Duration transitionDuration;
  final RouteTransitionsBuilder? transitionBuilder;
  final bool? requestFocus;
  final Offset? anchorPoint;
  final TraversalEdgeBehavior? traversalEdgeBehavior;
  final TraversalEdgeBehavior? directionalTraversalEdgeBehavior;
  final bool fullscreenDialog;

  @override
  Route<void> createRoute(BuildContext context) => RawDialogRoute<void>(
        pageBuilder: pageBuilder,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor,
        transitionDuration: transitionDuration,
        transitionBuilder: transitionBuilder,
        settings: this,
        requestFocus: requestFocus,
        anchorPoint: anchorPoint,
        traversalEdgeBehavior: traversalEdgeBehavior,
        directionalTraversalEdgeBehavior: directionalTraversalEdgeBehavior,
        fullscreenDialog: fullscreenDialog,
      );
}

/// Used for creating a dialog route if route name end with '-dialog'.
@internal
class OctopusDialogPage extends Page<Object?> {
  const OctopusDialogPage({
    required this.builder,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.themes,
    this.barrierColor = Colors.black54,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.useSafeArea = true,
    this.requestFocus,
    this.anchorPoint,
    this.traversalEdgeBehavior,
  });

  final WidgetBuilder builder;

  final Color? barrierColor;
  final bool barrierDismissible;
  final String? barrierLabel;
  final bool useSafeArea;
  final CapturedThemes? themes;
  final bool? requestFocus;
  final Offset? anchorPoint;
  final TraversalEdgeBehavior? traversalEdgeBehavior;

  @override
  Route<void> createRoute(BuildContext context) => DialogRoute(
        context: context,
        builder: builder,
        themes: themes,
        barrierColor: barrierColor,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        requestFocus: requestFocus,
        anchorPoint: anchorPoint,
        traversalEdgeBehavior: traversalEdgeBehavior,
        settings: this,
      );
}
