import 'package:flutter/widgets.dart';

import '../models/display_environment.dart';
import 'morph_view.dart';

/// Lays out two panes side by side or stacked, avoiding a separating hinge
/// or fold when there is one.
///
/// When exactly one separating feature runs across the whole widget, [start]
/// goes on one side of it and [end] on the other, and the feature's bounds
/// are left empty. Otherwise the panes are split by [fallbackRatio] along
/// [fallbackAxis], with [fallbackGap] between them.
///
/// The fold can only be placed accurately when the widget lines up with the
/// window along the split axis. For side-by-side panes the widget must be
/// as wide as the window. For stacked panes it must be as tall as the
/// window. Otherwise the ratio fallback is used. For tabletop layouts, place
/// [MorphTwoPane] outside any `AppBar`.
///
/// This widget never decides *whether* to show two panes. That is the
/// application's call, usually based on `MorphLayoutInfo.sizeClass` or
/// `DisplayEnvironment.hasSeparatingFeature`.
///
/// Children keep their state when the layout switches between fold mode and
/// ratio mode, and when the axis changes.
class MorphTwoPane extends StatelessWidget {
  /// Creates a two-pane layout.
  const MorphTwoPane({
    super.key,
    required this.start,
    required this.end,
    this.fallbackRatio = 0.5,
    this.fallbackAxis = Axis.horizontal,
    this.fallbackGap = 0,
    this.treatFlatFoldsAsSeparating = false,
  })  : assert(fallbackRatio >= 0 && fallbackRatio <= 1),
        assert(fallbackGap >= 0);

  /// The left (side by side) or top (stacked) pane.
  final Widget start;

  /// The right (side by side) or bottom (stacked) pane.
  final Widget end;

  /// The share of space given to [start] when there is no usable fold,
  /// from 0 to 1.
  final double fallbackRatio;

  /// How to arrange the panes when there is no usable fold.
  /// [Axis.horizontal] means side by side.
  final Axis fallbackAxis;

  /// The space between the panes when there is no usable fold, in logical
  /// pixels.
  final double fallbackGap;

  /// Whether a flat fold also splits the panes.
  ///
  /// By default only hinges and half-opened folds do, because a flat fold
  /// is one continuous surface.
  final bool treatFlatFoldsAsSeparating;

  @override
  Widget build(BuildContext context) {
    final environment = MorphView.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth && constraints.hasBoundedHeight,
          'MorphTwoPane needs bounded constraints.',
        );
        final size = constraints.biggest;
        final split = _foldSplit(environment, size) ?? _ratioSplit(size);
        final horizontal = split.axis == Axis.horizontal;
        return Flex(
          direction: split.axis,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sized(
              split.axis,
              split.startExtent,
              MediaQuery.removePadding(
                context: context,
                removeRight: horizontal,
                removeBottom: !horizontal,
                child: start,
              ),
            ),
            _sized(split.axis, split.gap, null),
            _sized(
              split.axis,
              split.endExtent,
              MediaQuery.removePadding(
                context: context,
                removeLeft: horizontal,
                removeTop: !horizontal,
                child: end,
              ),
            ),
          ],
        );
      },
    );
  }

  _Split? _foldSplit(DisplayEnvironment environment, Size size) {
    final layout = environment.resolveRegions(
      treatFlatFoldsAsSeparating: treatFlatFoldsAsSeparating,
    );
    if (layout.isAmbiguous || layout.separators.length != 1) return null;
    final separator = layout.separators.single;
    final window = environment.windowSize;
    if (separator.orientation == Axis.vertical) {
      if ((size.width - window.width).abs() > 1) return null;
      final left = separator.bounds.left.clamp(0.0, size.width);
      final right = separator.bounds.right.clamp(left, size.width);
      return _Split(Axis.horizontal, left, right - left, size.width - right);
    }
    if ((size.height - window.height).abs() > 1) return null;
    final top = separator.bounds.top.clamp(0.0, size.height);
    final bottom = separator.bounds.bottom.clamp(top, size.height);
    return _Split(Axis.vertical, top, bottom - top, size.height - bottom);
  }

  _Split _ratioSplit(Size size) {
    final extent = fallbackAxis == Axis.horizontal ? size.width : size.height;
    final gap = fallbackGap.clamp(0.0, extent);
    final startExtent = (extent - gap) * fallbackRatio;
    return _Split(fallbackAxis, startExtent, gap, extent - gap - startExtent);
  }

  static Widget _sized(Axis axis, double extent, Widget? child) {
    return axis == Axis.horizontal
        ? SizedBox(width: extent, child: child)
        : SizedBox(height: extent, child: child);
  }
}

class _Split {
  const _Split(this.axis, this.startExtent, this.gap, this.endExtent);

  final Axis axis;
  final double startExtent;
  final double gap;
  final double endExtent;
}
