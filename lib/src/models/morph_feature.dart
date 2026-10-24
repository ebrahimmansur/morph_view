import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'display_enums.dart';

/// A validated display feature, such as a hinge, fold or cutout.
///
/// [bounds] is in logical pixels, relative to the top-left corner of the
/// Flutter view (the application window). This is the same coordinate space
/// as `MediaQueryData.displayFeatures`. Safe-area insets are **not**
/// subtracted.
///
/// Instances produced by MorphView are normalized: bounds are finite,
/// clipped to the window, and cutouts always report
/// [DisplayPosture.unknown].
@immutable
class MorphFeature {
  /// Creates a display feature.
  ///
  /// Prefer reading features from a `DisplayEnvironment` instead of
  /// creating them yourself. Construct them directly in tests or when
  /// bridging a custom platform source.
  const MorphFeature({
    required this.bounds,
    required this.kind,
    this.state = DisplayPosture.unknown,
  });

  /// Converts a Flutter [ui.DisplayFeature] into a [MorphFeature].
  ///
  /// The feature's bounds must already be in logical pixels, as they are in
  /// `MediaQueryData.displayFeatures`.
  ///
  /// Engine values MorphView does not know about map to
  /// [DisplayFeatureKind.unknown] and [DisplayPosture.unknown]. `dart:ui`
  /// enums differ between platforms (the web engine has extra postures) and
  /// can grow between Flutter versions, so lookups are used here instead of
  /// exhaustive switches.
  factory MorphFeature.fromDisplayFeature(ui.DisplayFeature feature) {
    return MorphFeature(
      bounds: feature.bounds,
      kind: _kinds[feature.type] ?? DisplayFeatureKind.unknown,
      state: _postures[feature.state] ?? DisplayPosture.unknown,
    );
  }

  static const _kinds = {
    ui.DisplayFeatureType.hinge: DisplayFeatureKind.hinge,
    ui.DisplayFeatureType.fold: DisplayFeatureKind.fold,
    ui.DisplayFeatureType.cutout: DisplayFeatureKind.cutout,
  };

  static const _postures = {
    ui.DisplayFeatureState.postureFlat: DisplayPosture.flat,
    ui.DisplayFeatureState.postureHalfOpened: DisplayPosture.halfOpened,
  };

  /// The area the feature covers, in logical pixels in window coordinates.
  ///
  /// Folds may have zero width or height.
  final Rect bounds;

  /// What kind of feature this is.
  final DisplayFeatureKind kind;

  /// The posture of this feature. Always [DisplayPosture.unknown] for
  /// cutouts.
  final DisplayPosture state;

  /// Whether this feature is a hinge or a fold.
  bool get isFoldable =>
      kind == DisplayFeatureKind.hinge || kind == DisplayFeatureKind.fold;

  /// Whether the feature splits the window into separate logical areas.
  ///
  /// This matches the meaning of Android's `FoldingFeature.isSeparating`.
  /// Hinges always separate. Folds separate only while half-opened, because
  /// a flat fold is one continuous surface. Cutouts never separate.
  bool get isSeparating =>
      kind == DisplayFeatureKind.hinge ||
      (kind == DisplayFeatureKind.fold && state == DisplayPosture.halfOpened);

  /// Whether the feature hides content drawn beneath it.
  ///
  /// True for hinges and cutouts that cover a non-zero area.
  bool get isOccluding =>
      (kind == DisplayFeatureKind.hinge || kind == DisplayFeatureKind.cutout) &&
      bounds.width > 0 &&
      bounds.height > 0;

  /// The direction the feature's long side runs in.
  ///
  /// A hinge running from the top to the bottom of the window is
  /// [Axis.vertical] and puts panes side by side. A tall-and-thin or
  /// zero-width feature is vertical. A wide-and-short or zero-height feature
  /// is horizontal.
  Axis get orientation =>
      bounds.height >= bounds.width ? Axis.vertical : Axis.horizontal;

  /// Returns a copy with the given fields replaced.
  MorphFeature copyWith({
    Rect? bounds,
    DisplayFeatureKind? kind,
    DisplayPosture? state,
  }) {
    return MorphFeature(
      bounds: bounds ?? this.bounds,
      kind: kind ?? this.kind,
      state: state ?? this.state,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MorphFeature &&
          other.bounds == bounds &&
          other.kind == kind &&
          other.state == state;

  @override
  int get hashCode => Object.hash(bounds, kind, state);

  @override
  String toString() => 'MorphFeature(${kind.name}, ${state.name}, $bounds)';
}
