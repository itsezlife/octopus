import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

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
