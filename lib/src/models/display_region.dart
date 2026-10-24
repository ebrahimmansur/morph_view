import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'morph_feature.dart';

/// A usable, rectangular area of the window.
///
/// [rect] is in logical pixels, in window coordinates (the same space as
/// `MorphFeature.bounds`), and already excludes safe-area padding and any
/// separating features.
@immutable
class DisplayRegion {
  /// Creates a region.
  const DisplayRegion({required this.rect, required this.index});

  /// The usable area, in window coordinates.
  final Rect rect;

  /// The region's position in reading order: left to right for side-by-side
  /// regions, top to bottom for stacked regions. Starts at 0.
  final int index;

  /// The size of [rect].
  Size get size => rect.size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisplayRegion && other.rect == rect && other.index == index;

  @override
  int get hashCode => Object.hash(rect, index);

  @override
  String toString() => 'DisplayRegion(#$index, $rect)';
}

/// The result of splitting a window into usable regions.
///
/// See `RegionResolver.resolve`.
@immutable
class RegionLayout {
  /// Creates a region layout.
  const RegionLayout({
    required this.regions,
    this.axis,
    this.separators = const [],
    this.isAmbiguous = false,
  });

  /// A layout with no usable regions, for example because the window has
  /// zero size.
  static const RegionLayout empty = RegionLayout(regions: []);

  /// The usable regions in reading order. Empty only when the window, minus
  /// safe-area padding, has no area.
  final List<DisplayRegion> regions;

  /// The direction the [regions] are laid out in.
  ///
  /// [Axis.horizontal] means side by side (split by a vertical hinge).
  /// [Axis.vertical] means stacked (split by a horizontal fold, for example
  /// in tabletop posture). `null` when there are fewer than two regions.
  final Axis? axis;

  /// The separating features that produced the split, in reading order.
  final List<MorphFeature> separators;

  /// Whether the separating features conflicted, for example by overlapping
  /// or by running in both directions.
  ///
  /// In that case MorphView falls back to a single region covering the safe
  /// window, so the layout stays deterministic.
  final bool isAmbiguous;

  /// Whether the window is split into two or more regions.
  bool get isSplit => regions.length > 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegionLayout &&
          listEquals(other.regions, regions) &&
          other.axis == axis &&
          listEquals(other.separators, separators) &&
          other.isAmbiguous == isAmbiguous;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(regions),
        axis,
        Object.hashAll(separators),
        isAmbiguous,
      );

  @override
  String toString() => 'RegionLayout(axis: ${axis?.name}, '
      'ambiguous: $isAmbiguous, regions: $regions)';
}
