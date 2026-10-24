/// The physical kind of a display feature reported by the platform.
enum DisplayFeatureKind {
  /// A physical hinge between two screens or display panels.
  ///
  /// Hinges usually occlude content and always separate the window into
  /// distinct areas.
  hinge,

  /// A crease in a continuous flexible display.
  ///
  /// Folds usually do not occlude content and may be reported with
  /// zero-width bounds.
  fold,

  /// A camera or sensor cutout that occludes part of the display.
  cutout,

  /// A feature whose kind the platform could not determine.
  unknown,
}

/// The posture of a foldable display, as reported by the platform.
///
/// Used both for an individual [DisplayFeatureKind.fold] or
/// [DisplayFeatureKind.hinge] and for the display environment as a whole.
enum DisplayPosture {
  /// The posture is not known, not reported, or not applicable.
  ///
  /// This is always the value for cutouts and for platforms that do not
  /// report posture information.
  unknown,

  /// The device is fully opened and the display surface is flat.
  flat,

  /// The device is partially folded, like a book or a laptop ("tabletop").
  halfOpened,
}

/// Whether a platform can provide a particular piece of display information.
///
/// This lets applications tell "the platform cannot tell us" apart from
/// "the platform told us there is nothing there".
enum CapabilityStatus {
  /// The platform reports this information. An empty result means the
  /// information was checked and nothing was found.
  supported,

  /// The platform has no public API for this information. An empty result
  /// says nothing about the hardware.
  unsupported,

  /// MorphView cannot determine whether the platform reports this
  /// information.
  unknown;

  /// Whether this status is [CapabilityStatus.supported].
  bool get isSupported => this == CapabilityStatus.supported;
}

/// Whether a [DisplayEnvironment] snapshot holds trustworthy data.
///
/// See `DisplayEnvironment.status`.
enum DisplayEnvironmentStatus {
  /// The snapshot was read successfully from the platform.
  ready,

  /// The latest read failed or no display was attached. Geometry is either
  /// empty or the last known good value.
  unavailable,
}
