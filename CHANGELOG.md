## 0.1.0

Initial release.

- `DisplayEnvironment`: an immutable, value-equal snapshot of window size,
  safe-area padding, display features, capabilities and status, with derived
  `sizeClass`, `orientation`, `posture`, `separatingFeatures` and
  `regionLayout`.
- `MorphFeature`: validated hinge, fold and cutout data with `isSeparating`
  and `isOccluding` semantics that match Android.
- `DisplayCapabilities` with `CapabilityStatus` (`supported`, `unsupported`,
  `unknown`) for each platform, upgraded from runtime evidence.
- `RegionResolver`: deterministic, tested splitting of the window into usable
  regions (vertical and horizontal separators, multiple features, overlaps,
  malformed data, safe areas).
- `WindowSizeClass`: Material 3 width breakpoints.
- `DisplayEnvironmentObserver`: a `ValueListenable` and deduplicated `Stream`
  outside the widget tree, with safe error handling and disposal.
- `DisplayEnvironmentSource`: an injectable platform-adapter contract, with a
  `FlutterView`-backed default.
- Widgets: `MorphView`, `MorphLayoutBuilder` and `MorphTwoPane`.
- An example app showing an adaptive, fold-aware list-and-details layout that
  keeps its state across layout changes.
