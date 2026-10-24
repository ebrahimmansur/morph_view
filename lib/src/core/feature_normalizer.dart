import 'package:flutter/painting.dart';

import '../models/display_enums.dart';
import '../models/morph_feature.dart';

/// Validates raw display features against a window of [windowSize] logical
/// pixels.
///
/// Rules, in order:
/// 1. If the window has no area, no features are returned.
/// 2. Features with non-finite coordinates or negative sizes are dropped.
/// 3. Bounds are clipped to the window. Features completely outside it are
///    dropped. Zero-width or zero-height features (folds) are kept.
/// 4. Cutouts are forced to [DisplayPosture.unknown].
/// 5. Exact duplicates are removed.
/// 6. The result is sorted top-to-bottom, then left-to-right, then by kind,
///    so the output does not depend on platform ordering.
List<MorphFeature> normalizeFeatures(
  Iterable<MorphFeature> features,
  Size windowSize,
) {
  if (!_hasArea(windowSize)) return const [];
  final window = Offset.zero & windowSize;
  final result = <MorphFeature>{};
  for (final feature in features) {
    final bounds = feature.bounds;
    if (!_isFinite(bounds) || bounds.width < 0 || bounds.height < 0) continue;
    final clipped = bounds.intersect(window);
    if (clipped.width < 0 || clipped.height < 0) continue;
    result.add(
      MorphFeature(
        bounds: clipped,
        kind: feature.kind,
        state: feature.kind == DisplayFeatureKind.cutout
            ? DisplayPosture.unknown
            : feature.state,
      ),
    );
  }
  return List.unmodifiable(result.toList()..sort(_compare));
}

bool _hasArea(Size size) => size.isFinite && size.width > 0 && size.height > 0;

bool _isFinite(Rect rect) =>
    rect.left.isFinite &&
    rect.top.isFinite &&
    rect.right.isFinite &&
    rect.bottom.isFinite;

int _compare(MorphFeature a, MorphFeature b) {
  final byTop = a.bounds.top.compareTo(b.bounds.top);
  if (byTop != 0) return byTop;
  final byLeft = a.bounds.left.compareTo(b.bounds.left);
  if (byLeft != 0) return byLeft;
  final byKind = a.kind.index.compareTo(b.kind.index);
  if (byKind != 0) return byKind;
  final byWidth = a.bounds.width.compareTo(b.bounds.width);
  if (byWidth != 0) return byWidth;
  final byHeight = a.bounds.height.compareTo(b.bounds.height);
  if (byHeight != 0) return byHeight;
  return a.state.index.compareTo(b.state.index);
}
