import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// Declarative page that creates a [ModalBottomSheetRoute],
/// matching [showModalBottomSheet] behavior for the Octopus stack.
@internal
class OctopusModalBottomSheetPage extends Page<Object?> {
  const OctopusModalBottomSheetPage({
    required this.builder,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.constraints,
    this.barrierColor,
    this.barrierLabel,
    this.isScrollControlled = false,
    this.scrollControlDisabledMaxHeightRatio = 9.0 / 16.0,
    this.isDismissible = true,
    this.enableDrag = true,
    this.showDragHandle,
    this.useSafeArea = false,
    this.anchorPoint,
    this.requestFocus,
  });

  final WidgetBuilder builder;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final BoxConstraints? constraints;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool isScrollControlled;
  final double scrollControlDisabledMaxHeightRatio;
  final bool isDismissible;
  final bool enableDrag;
  final bool? showDragHandle;
  final bool useSafeArea;
  final Offset? anchorPoint;
  final bool? requestFocus;

  @override
  Route<Object?> createRoute(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return ModalBottomSheetRoute<Object?>(
      builder: builder,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: context,
      ),
      isScrollControlled: isScrollControlled,
      scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      modalBarrierColor: barrierColor,
      barrierLabel: barrierLabel ?? localizations.scrimLabel,
      barrierOnTapHint:
          localizations.scrimOnTapHint(localizations.bottomSheetLabel),
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      useSafeArea: useSafeArea,
      anchorPoint: anchorPoint,
      requestFocus: requestFocus,
      settings: this,
    );
  }
}
