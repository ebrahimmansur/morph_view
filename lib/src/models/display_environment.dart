import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/feature_normalizer.dart';
import '../core/region_resolver.dart';
import 'display_capabilities.dart';
import 'display_enums.dart';
import 'display_region.dart';
import 'morph_feature.dart';
import 'window_size_class.dart';

/// An immutable snapshot of the application's display environment.
///
/// ## Coordinate space
///
/// All geometry is in **logical pixels**, relative to the top-left corner of
/// the Flutter view (the application window, not the physical screen).
/// [features] and [regionLayout] use this space. [padding] is the safe-area
/// inset (system bars, notches, rounded corners), taken from
/// `MediaQueryData.padding`.
///
/// ## Unknown versus absent
///
/// An empty [features] list means "no features" only when
/// `capabilities.foldGeometry` is [CapabilityStatus.supported]. Otherwise
/// the platform simply cannot report them. In the same way,
/// [DisplayPosture.unknown] never means "flat".
///
/// ## Equality
///
/// Snapshots compare by value, which lets observers skip identical updates.
/// [error] is diagnostic only and is not part of equality.
@immutable
class DisplayEnvironment {
  /// Creates a snapshot from already-normalized values.
  ///
  /// Use [DisplayEnvironment.resolve] or [DisplayEnvironment.fromMediaQuery]
  /// to build one from raw platform data. They validate the features.
  const DisplayEnvironment({
    required this.windowSize,
    this.padding = EdgeInsets.zero,
    this.features = const [],
    this.capabilities = DisplayCapabilities.unknown,
    this.status = DisplayEnvironmentStatus.ready,
    this.error,
  });

  /// Builds a snapshot from raw platform values.
  ///
  /// [displayFeatures] are normalized (see `RegionResolver.resolve`).
  /// [capabilities] defaults to [DisplayCapabilities.current]. If a fold or
  /// hinge is actually reported, `foldGeometry`, `posture` and
  /// `multipleRegions` are upgraded to [CapabilityStatus.supported], because
  /// the data proves the platform provides them.
  factory DisplayEnvironment.resolve({
    required Size windowSize,
    EdgeInsets padding = EdgeInsets.zero,
    Iterable<ui.DisplayFeature> displayFeatures = const [],
    DisplayCapabilities? capabilities,
  }) {
    final features = normalizeFeatures(
      displayFeatures.map(MorphFeature.fromDisplayFeature),
      windowSize,
    );
    var caps = capabilities ?? DisplayCapabilities.current();
    if (features.any((f) => f.isFoldable)) {
      caps = caps.copyWith(
        foldGeometry: CapabilityStatus.supported,
        posture: CapabilityStatus.supported,
        multipleRegions: CapabilityStatus.supported,
      );
    }
    if (features.any((f) => f.kind == DisplayFeatureKind.cutout)) {
      caps = caps.copyWith(cutouts: CapabilityStatus.supported);
    }
    final validSize = windowSize.isFinite && !windowSize.isEmpty;
    return DisplayEnvironment(
      windowSize: validSize ? windowSize : Size.zero,
      padding: padding,
      features: features,
      capabilities: caps,
      status: validSize
          ? DisplayEnvironmentStatus.ready
          : DisplayEnvironmentStatus.unavailable,
    );
  }

  /// Builds a snapshot from [data], using its size, padding and display
  /// features.
  factory DisplayEnvironment.fromMediaQuery(
    MediaQueryData data, {
    DisplayCapabilities? capabilities,
  }) {
    return DisplayEnvironment.resolve(
      windowSize: data.size,
      padding: data.padding,
      displayFeatures: data.displayFeatures,
      capabilities: capabilities,
    );
  }

  /// A snapshot for when display data cannot be read.
  ///
  /// When [previous] is given, its geometry is kept so layouts don't
  /// collapse on a temporary failure. Otherwise the window is empty.
  factory DisplayEnvironment.unavailable({
    Object? error,
    DisplayEnvironment? previous,
  }) {
    return DisplayEnvironment(
      windowSize: previous?.windowSize ?? Size.zero,
      padding: previous?.padding ?? EdgeInsets.zero,
      features: previous?.features ?? const [],
      capabilities: previous?.capabilities ?? DisplayCapabilities.unknown,
      status: DisplayEnvironmentStatus.unavailable,
      error: error,
    );
  }

  /// The size of the application window in logical pixels.
  ///
  /// This is the space given to the app, which may be much smaller than the
  /// physical screen (split screen, desktop windows, freeform mode).
  final Size windowSize;

  /// Safe-area insets in logical pixels, in window coordinates.
  final EdgeInsets padding;

  /// Validated display features, sorted top-to-bottom then left-to-right.
  final List<MorphFeature> features;

  /// What the platform can report. See [DisplayCapabilities].
  final DisplayCapabilities capabilities;

  /// Whether this snapshot holds trustworthy data.
  final DisplayEnvironmentStatus status;

  /// The error that made this snapshot [DisplayEnvironmentStatus.unavailable],
  /// if any. Not part of equality.
  final Object? error;

  /// Whether [status] is [DisplayEnvironmentStatus.ready].
  bool get isReady => status == DisplayEnvironmentStatus.ready;

  /// The window's orientation, derived from [windowSize].
  ///
  /// A square window counts as portrait, matching `MediaQueryData`.
  Orientation get orientation => windowSize.width > windowSize.height
      ? Orientation.landscape
      : Orientation.portrait;

  /// The Material 3 size class for the window width.
  ///
  /// For a widget that does not fill the window, prefer the size class of
  /// its own constraints (see `MorphLayoutBuilder`).
  WindowSizeClass get sizeClass => WindowSizeClass.fromWidth(windowSize.width);

  /// Hinges and folds only, without cutouts.
  Iterable<MorphFeature> get foldingFeatures =>
      features.where((f) => f.isFoldable);

  /// Features that currently split the window. See
  /// [MorphFeature.isSeparating].
  Iterable<MorphFeature> get separatingFeatures =>
      features.where((f) => f.isSeparating);

  /// Whether any feature currently splits the window.
  bool get hasSeparatingFeature => features.any((f) => f.isSeparating);

  /// The posture of the device.
  ///
  /// [DisplayPosture.halfOpened] if any fold or hinge is half-opened,
  /// otherwise [DisplayPosture.flat] if any is flat, otherwise
  /// [DisplayPosture.unknown]. This includes devices with no foldable
  /// features and platforms that do not report posture.
  DisplayPosture get posture {
    var result = DisplayPosture.unknown;
    for (final feature in foldingFeatures) {
      if (feature.state == DisplayPosture.halfOpened) {
        return DisplayPosture.halfOpened;
      }
      if (feature.state == DisplayPosture.flat) result = DisplayPosture.flat;
    }
    return result;
  }

  /// The usable regions of the window, split by separating features and
  /// clipped to the safe area.
  ///
  /// Calculated on each access. Cache it if you read it in a tight loop.
  RegionLayout get regionLayout => resolveRegions();

  /// The usable regions of the window. See `RegionResolver.resolve` for the
  /// rules and [treatFlatFoldsAsSeparating].
  RegionLayout resolveRegions({bool treatFlatFoldsAsSeparating = false}) {
    return RegionResolver.resolve(
      windowSize,
      features,
      padding: padding,
      treatFlatFoldsAsSeparating: treatFlatFoldsAsSeparating,
    );
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// [features] are used as given and are not normalized again.
  DisplayEnvironment copyWith({
    Size? windowSize,
    EdgeInsets? padding,
    List<MorphFeature>? features,
    DisplayCapabilities? capabilities,
    DisplayEnvironmentStatus? status,
    Object? error,
  }) {
    return DisplayEnvironment(
      windowSize: windowSize ?? this.windowSize,
      padding: padding ?? this.padding,
      features: features ?? this.features,
      capabilities: capabilities ?? this.capabilities,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisplayEnvironment &&
          other.windowSize == windowSize &&
          other.padding == padding &&
          listEquals(other.features, features) &&
          other.capabilities == capabilities &&
          other.status == status;

  @override
  int get hashCode => Object.hash(
        windowSize,
        padding,
        Object.hashAll(features),
        capabilities,
        status,
      );

  @override
  String toString() => 'DisplayEnvironment(${status.name}, '
      'size: $windowSize, sizeClass: ${sizeClass.name}, '
      'posture: ${posture.name}, features: $features)';
}
