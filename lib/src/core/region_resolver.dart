import 'package:flutter/painting.dart';

import '../models/display_enums.dart';
import '../models/display_region.dart';
import '../models/morph_feature.dart';
import 'feature_normalizer.dart';

/// Splits a window into usable regions around separating display features.
///
/// All geometry is in logical pixels, in window coordinates. The resolver
/// only calculates where content *can* go. Deciding what goes in each region
/// is up to the application.
abstract final class RegionResolver {
  /// How far, in logical pixels, a feature may stop short of the window
  /// edges and still count as spanning the whole window.
  static const double spanTolerance = 1.0;

  /// Resolves the usable regions of a window of [windowSize] that contains
  /// [features].
  ///
  /// Features are normalized first (see the package README). Then:
  ///
  /// * Only separating features ([MorphFeature.isSeparating], plus flat
  ///   folds when [treatFlatFoldsAsSeparating] is true) that span the whole
  ///   window from edge to edge can split it. Partial features are ignored.
  /// * Separators that all run the same way split the window into one more
  ///   region than there are separators. The separator's own bounds are
  ///   excluded, so a 20px hinge leaves a 20px gap and a zero-width fold
  ///   leaves none. Splits do not have to be equal.
  /// * Separators that run in both directions, or that overlap, make the
  ///   result [RegionLayout.isAmbiguous] and fall back to a single region.
  /// * Every region is clipped to the window minus [padding] (the safe
  ///   area). Regions left with no area are dropped and the rest are
  ///   renumbered.
  /// * If no region survives, the whole safe window is returned as a single
  ///   region. If the safe window has no area either, the result has no
  ///   regions.
  static RegionLayout resolve(
    Size windowSize,
    Iterable<MorphFeature> features, {
    EdgeInsets padding = EdgeInsets.zero,
    bool treatFlatFoldsAsSeparating = false,
  }) {
    if (!windowSize.isFinite || windowSize.isEmpty) return RegionLayout.empty;
    final window = Offset.zero & windowSize;
    final safe = _safeRect(window, padding);
    if (safe == null) return RegionLayout.empty;
    final single = RegionLayout(regions: [DisplayRegion(rect: safe, index: 0)]);

    final candidates = normalizeFeatures(features, windowSize).where(
      (f) =>
          f.isSeparating ||
          (treatFlatFoldsAsSeparating && f.kind == DisplayFeatureKind.fold),
    );
    final vertical = <MorphFeature>[];
    final horizontal = <MorphFeature>[];
    for (final feature in candidates) {
      final b = feature.bounds;
      if (feature.orientation == Axis.vertical &&
          b.top <= spanTolerance &&
          b.bottom >= windowSize.height - spanTolerance) {
        vertical.add(feature);
      } else if (feature.orientation == Axis.horizontal &&
          b.left <= spanTolerance &&
          b.right >= windowSize.width - spanTolerance) {
        horizontal.add(feature);
      }
    }

    if (vertical.isEmpty && horizontal.isEmpty) return single;
    if (vertical.isNotEmpty && horizontal.isNotEmpty) {
      return RegionLayout(
        regions: single.regions,
        separators: [...vertical, ...horizontal],
        isAmbiguous: true,
      );
    }

    // Vertical separators put regions side by side (horizontal axis).
    final axis = vertical.isNotEmpty ? Axis.horizontal : Axis.vertical;
    final separators = vertical.isNotEmpty ? vertical : horizontal;
    double start(MorphFeature f) =>
        axis == Axis.horizontal ? f.bounds.left : f.bounds.top;
    double end(MorphFeature f) =>
        axis == Axis.horizontal ? f.bounds.right : f.bounds.bottom;
    separators.sort((a, b) => start(a).compareTo(start(b)));

    for (var i = 1; i < separators.length; i++) {
      if (start(separators[i]) < end(separators[i - 1])) {
        return RegionLayout(
          regions: single.regions,
          separators: List.unmodifiable(separators),
          isAmbiguous: true,
        );
      }
    }

    final extent =
        axis == Axis.horizontal ? windowSize.width : windowSize.height;
    final rects = <Rect>[];
    var cursor = 0.0;
    for (final separator in [...separators, null]) {
      final segmentEnd = separator == null ? extent : start(separator);
      final segment = axis == Axis.horizontal
          ? Rect.fromLTRB(cursor, 0, segmentEnd, windowSize.height)
          : Rect.fromLTRB(0, cursor, windowSize.width, segmentEnd);
      final usable = segment.intersect(safe);
      if (usable.width > 0 && usable.height > 0) rects.add(usable);
      if (separator != null) cursor = end(separator);
    }

    if (rects.isEmpty) {
      return RegionLayout(
        regions: single.regions,
        separators: List.unmodifiable(separators),
      );
    }
    return RegionLayout(
      regions: List.unmodifiable([
        for (var i = 0; i < rects.length; i++)
          DisplayRegion(rect: rects[i], index: i),
      ]),
      axis: rects.length > 1 ? axis : null,
      separators: List.unmodifiable(separators),
    );
  }

  static Rect? _safeRect(Rect window, EdgeInsets padding) {
    final safe = Rect.fromLTRB(
      window.left + _nonNegative(padding.left),
      window.top + _nonNegative(padding.top),
      window.right - _nonNegative(padding.right),
      window.bottom - _nonNegative(padding.bottom),
    );
    if (!(safe.width > 0 && safe.height > 0)) return null;
    return safe;
  }

  static double _nonNegative(double value) =>
      value.isFinite && value > 0 ? value : 0;
}
