import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// Declarative page that presents a modal bottom sheet on the Octopus stack.
///
/// Uses [RawDialogRoute] (same family as [showGeneralDialog]) instead of
/// [ModalBottomSheetRoute], so page-based [Navigator.maybePop] / system back
/// completes via [RouterDelegate.popRoute] → [onPopPage] reliably.
///
/// Visually mirrors a Material modal sheet: bottom-aligned content, slide-up
/// transition, scrim, and the usual sheet theme / size constraints.
///
/// [enableDrag] and [showDragHandle] are accepted for API parity with
/// [showModalBottomSheet] but are ignored — drag-to-dismiss belongs in the
/// sheet content (e.g. [DraggableScrollableSheet]), not on the route.
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

  /// Accepted for [showModalBottomSheet] parity; unused on this route.
  final bool enableDrag;

  /// Accepted for [showModalBottomSheet] parity; unused on this route.
  final bool? showDragHandle;
  final bool useSafeArea;
  final Offset? anchorPoint;
  final bool? requestFocus;

  static const Duration _transitionDuration = Duration(milliseconds: 250);

  @override
  Route<Object?> createRoute(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final navigator = Navigator.of(context);
    final capturedThemes = InheritedTheme.capture(
      from: context,
      to: navigator.context,
    );

    return RawDialogRoute<Object?>(
      settings: this,
      barrierDismissible: isDismissible,
      barrierLabel: barrierLabel ?? localizations.scrimLabel,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: _transitionDuration,
      requestFocus: requestFocus,
      anchorPoint: anchorPoint,
      pageBuilder: (context, animation, secondaryAnimation) {
        final sheet = Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final sheetTheme = theme.bottomSheetTheme;
            Widget child = Material(
              color: backgroundColor ??
                  sheetTheme.modalBackgroundColor ??
                  sheetTheme.backgroundColor,
              elevation: elevation ??
                  sheetTheme.modalElevation ??
                  sheetTheme.elevation ??
                  0,
              shape: shape ?? sheetTheme.shape,
              clipBehavior: clipBehavior ??
                  sheetTheme.clipBehavior ??
                  Clip.none,
              child: builder(context),
            );
            final sheetConstraints = constraints ?? sheetTheme.constraints;
            if (sheetConstraints != null) {
              child = ConstrainedBox(
                constraints: sheetConstraints,
                child: child,
              );
            }
            return child;
          },
        );

        Widget body = Align(
          alignment: Alignment.bottomCenter,
          child: LayoutBuilder(
            builder: (context, layoutConstraints) {
              final maxHeight = isScrollControlled
                  ? layoutConstraints.maxHeight
                  : layoutConstraints.maxHeight *
                      scrollControlDisabledMaxHeightRatio;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: layoutConstraints.maxWidth,
                  maxHeight: maxHeight,
                ),
                child: sheet,
              );
            },
          ),
        );

        body = useSafeArea
            ? SafeArea(bottom: false, child: body)
            : MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: body,
              );

        return capturedThemes.wrap(body);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }
}
