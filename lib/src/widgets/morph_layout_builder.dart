import 'package:flutter/widgets.dart';

import '../models/display_environment.dart';
import '../models/window_size_class.dart';
import 'morph_view.dart';

/// Layout information passed to a [MorphLayoutBuilder] builder.
@immutable
class MorphLayoutInfo {
  /// Creates layout information.
  const MorphLayoutInfo({
    required this.constraints,
    required this.size,
    required this.environment,
  });

  /// The constraints the builder was laid out with.
  final BoxConstraints constraints;

  /// The space available to the builder, in logical pixels.
  ///
  /// When a constraint is unbounded (for example inside a scroll view), the
  /// window's size along that axis is used instead.
  final Size size;

  /// The display environment of the whole window.
  final DisplayEnvironment environment;

  /// The size class of the available width ([size]), not the window.
  WindowSizeClass get sizeClass => WindowSizeClass.fromWidth(size.width);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MorphLayoutInfo &&
          other.constraints == constraints &&
          other.size == size &&
          other.environment == environment;

  @override
  int get hashCode => Object.hash(constraints, size, environment);

  @override
  String toString() =>
      'MorphLayoutInfo(size: $size, sizeClass: ${sizeClass.name})';
}

/// Signature for [MorphLayoutBuilder.builder].
typedef MorphLayoutWidgetBuilder = Widget Function(
  BuildContext context,
  MorphLayoutInfo info,
);

/// Builds a widget from the space that is actually available to it.
///
/// Combines a [LayoutBuilder] (local constraints) with the window's
/// [DisplayEnvironment]. Use [MorphLayoutInfo.sizeClass] to choose between
/// layouts. It classifies the space given to *this* widget, which is
/// correct inside split views, side sheets and desktop windows.
///
/// ```dart
/// MorphLayoutBuilder(
///   builder: (context, info) => info.sizeClass.isAtLeast(WindowSizeClass.expanded)
///       ? const MasterDetail()
///       : const SinglePane(),
/// )
/// ```
class MorphLayoutBuilder extends StatelessWidget {
  /// Creates a layout builder.
  const MorphLayoutBuilder({super.key, required this.builder});

  /// Builds the child from the available space and display environment.
  final MorphLayoutWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final environment = MorphView.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = environment.windowSize;
        final size = Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : window.width,
          constraints.hasBoundedHeight ? constraints.maxHeight : window.height,
        );
        return builder(
          context,
          MorphLayoutInfo(
            constraints: constraints,
            size: size,
            environment: environment,
          ),
        );
      },
    );
  }
}
