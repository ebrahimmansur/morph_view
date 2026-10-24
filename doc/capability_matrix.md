# Capability matrix

How each capability is sourced, what it needs, its limitations and what
MorphView does when it is unavailable. Verified against Flutter 3.47 /
Dart 3.13 (`dart:ui` `FlutterView.displayFeatures`, `DisplayFeatureType`,
`DisplayFeatureState`) and the public Android and Apple SDK documentation.

| Capability | Android | iOS | Web | Desktop |
|---|---|---|---|---|
| Available window dimensions | ✅ | ✅ | ✅ | ✅ |
| Display-feature geometry | ✅ | ❌ | ❌ | ❌ |
| Separating hinges and folds | ✅ | ❌ | ❌ | ❌ |
| Display posture | ✅ | ❌ | ❌ | ❌ |
| Multiple usable regions | ✅ | ❌ | ❌ | ❌ |
| Live display configuration updates | ✅ | ✅ (window only) | ✅ (window only) | ✅ (window only) |

## Available window dimensions

- **Source:** `MediaQueryData.size` / `FlutterView.physicalSize ÷ devicePixelRatio`.
- **Prerequisites:** none.
- **Limitations:** this is the *window*, not the screen. That is the right
  input for layout.
- **Fallback:** a zero size (for example while the app starts) gives
  `DisplayEnvironmentStatus.unavailable` and no regions.

## Display-feature geometry

- **Source (Android):** Jetpack WindowManager `WindowLayoutInfo.displayFeatures`
  → `FoldingFeature.bounds`, forwarded by the Flutter Android embedding to
  `FlutterView.displayFeatures` in logical pixels. Display cutouts are
  forwarded too.
- **Prerequisites:** a device or emulator that reports folding features
  (foldables, dual-screen devices, foldable AVD profiles). No app
  configuration is needed.
- **Limitations:** features are only reported while the app's window
  overlaps them. In split-screen they may disappear, which is correct
  because the app is then not spanning the fold.
- **iOS:** there is no public API (UIKit `UIScreen`, `UIWindowScene` and
  `UITraitCollection` expose no fold or hinge data), so it is
  `unsupported`. MorphView does not use private APIs and does not infer
  hardware from model names.
- **Fallback:** an empty feature list with `foldGeometry: unsupported`. Apps
  keep responsive layouts.

## Separating hinges and folds

- **Source (Android):** `FoldingFeature.occlusionType` (`FULL` → hinge,
  `NONE` → fold) and `state`, mapped by the engine to `DisplayFeatureType`
  and `DisplayFeatureState`.
- **Rule:** `MorphFeature.isSeparating` is true for hinges, and for folds
  only when half-opened, matching `FoldingFeature.isSeparating`.
- **Fallback:** single region.

## Display posture

- **Source (Android):** `FoldingFeature.State.FLAT` / `HALF_OPENED` →
  `DisplayPosture.flat` / `halfOpened`.
- **Limitations:** the web engine's `DisplayFeatureState` has extra values
  (for example `postureFlipped`) that no platform currently fills in. Unknown
  values map to `DisplayPosture.unknown`.
- **Fallback:** `DisplayPosture.unknown`. Never assume it means flat.

## Multiple usable regions

- **Source:** calculated by `RegionResolver` from separating features and
  safe-area padding.
- **Prerequisites:** a separating feature that spans the window from edge to
  edge.
- **Fallback:** a single region covering the safe window. Conflicting
  separators set `isAmbiguous`.

## Live display configuration updates

- **Source:** `WidgetsBindingObserver.didChangeMetrics` (observer) and
  `MediaQuery` dependencies (widgets). Fold, unfold and posture changes
  arrive as metric changes on Android.
- **Prerequisites:** a `WidgetsBinding`.
- **Fallback:** call `DisplayEnvironmentObserver.refresh()` to force a
  re-read.
