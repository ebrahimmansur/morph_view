import 'package:flutter/foundation.dart';

import 'display_enums.dart';

/// Which kinds of display information the current platform can provide.
///
/// Use this to choose between fold-aware layouts and plain responsive
/// layouts. When [foldGeometry] is [CapabilityStatus.supported] and no
/// features are reported, the device really has no fold or hinge (or it is
/// not currently exposed to the app). When it is
/// [CapabilityStatus.unsupported], an empty feature list says nothing about
/// the hardware.
@immutable
class DisplayCapabilities {
  /// Creates a capability set. Every field defaults to
  /// [CapabilityStatus.unknown], except [windowMetrics], which Flutter
  /// supports everywhere.
  const DisplayCapabilities({
    this.windowMetrics = CapabilityStatus.supported,
    this.foldGeometry = CapabilityStatus.unknown,
    this.posture = CapabilityStatus.unknown,
    this.cutouts = CapabilityStatus.unknown,
    this.multipleRegions = CapabilityStatus.unknown,
  });

  /// Returns the capabilities MorphView can provide on [platform].
  ///
  /// [isWeb] defaults to [kIsWeb]. Flutter web does not report display
  /// features, even when it runs on a foldable Android device.
  ///
  /// This is a static description of what the Flutter engine reports on each
  /// platform. When a fold or hinge is actually reported at runtime, the
  /// display environment upgrades [foldGeometry] and [posture] to
  /// [CapabilityStatus.supported] on any platform.
  factory DisplayCapabilities.forPlatform(
    TargetPlatform platform, {
    bool isWeb = kIsWeb,
  }) {
    if (isWeb) return responsiveOnly;
    return switch (platform) {
      // The Android embedding forwards Jetpack WindowManager folding
      // features and display cutouts to FlutterView.displayFeatures.
      TargetPlatform.android => const DisplayCapabilities(
          foldGeometry: CapabilityStatus.supported,
          posture: CapabilityStatus.supported,
          cutouts: CapabilityStatus.supported,
          multipleRegions: CapabilityStatus.supported,
        ),
      // There is no public UIKit API for fold, hinge or posture information.
      // Cutouts (notch, Dynamic Island) always show up in safe-area padding,
      // but whether they appear as display features depends on the engine
      // version, so we do not promise them.
      TargetPlatform.iOS => responsiveOnly,
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux =>
        const DisplayCapabilities(
          foldGeometry: CapabilityStatus.unsupported,
          posture: CapabilityStatus.unsupported,
          cutouts: CapabilityStatus.unsupported,
          multipleRegions: CapabilityStatus.unsupported,
        ),
      TargetPlatform.fuchsia => unknown,
    };
  }

  /// Returns the capabilities for the current [defaultTargetPlatform].
  factory DisplayCapabilities.current() =>
      DisplayCapabilities.forPlatform(defaultTargetPlatform);

  /// Window metrics are available. Nothing else is known.
  static const DisplayCapabilities unknown = DisplayCapabilities();

  /// Only window metrics and safe-area padding are available. Fold
  /// geometry, posture and multiple regions are unsupported. This is the
  /// iOS and web profile.
  static const DisplayCapabilities responsiveOnly = DisplayCapabilities(
    foldGeometry: CapabilityStatus.unsupported,
    posture: CapabilityStatus.unsupported,
    cutouts: CapabilityStatus.unknown,
    multipleRegions: CapabilityStatus.unsupported,
  );

  /// Window size, safe-area padding and live resize updates.
  final CapabilityStatus windowMetrics;

  /// The bounds of folds and hinges.
  final CapabilityStatus foldGeometry;

  /// The posture of folds and hinges (flat or half-opened).
  final CapabilityStatus posture;

  /// Camera and sensor cutouts reported as display features (rather than
  /// only as safe-area padding).
  final CapabilityStatus cutouts;

  /// Splitting the window into several usable regions around separating
  /// features.
  final CapabilityStatus multipleRegions;

  /// Returns a copy with the given fields replaced.
  DisplayCapabilities copyWith({
    CapabilityStatus? windowMetrics,
    CapabilityStatus? foldGeometry,
    CapabilityStatus? posture,
    CapabilityStatus? cutouts,
    CapabilityStatus? multipleRegions,
  }) {
    return DisplayCapabilities(
      windowMetrics: windowMetrics ?? this.windowMetrics,
      foldGeometry: foldGeometry ?? this.foldGeometry,
      posture: posture ?? this.posture,
      cutouts: cutouts ?? this.cutouts,
      multipleRegions: multipleRegions ?? this.multipleRegions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisplayCapabilities &&
          other.windowMetrics == windowMetrics &&
          other.foldGeometry == foldGeometry &&
          other.posture == posture &&
          other.cutouts == cutouts &&
          other.multipleRegions == multipleRegions;

  @override
  int get hashCode => Object.hash(
      windowMetrics, foldGeometry, posture, cutouts, multipleRegions);

  @override
  String toString() => 'DisplayCapabilities('
      'windowMetrics: ${windowMetrics.name}, '
      'foldGeometry: ${foldGeometry.name}, '
      'posture: ${posture.name}, '
      'cutouts: ${cutouts.name}, '
      'multipleRegions: ${multipleRegions.name})';
}
