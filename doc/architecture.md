# Architecture

## Mental model

**MorphView observes the display. The application decides how the UI adapts.**

There are three separate responsibilities:

1. **Display awareness:** window geometry, display features, posture and
   capabilities (`DisplayEnvironment`, `DisplayEnvironmentObserver`,
   `MorphView`).
2. **Layout utilities:** usable regions and size classes (`RegionResolver`,
   `WindowSizeClass`, `MorphLayoutBuilder`, `MorphTwoPane`).
3. **Application presentation:** done by the app. MorphView never chooses
   between one and two panes, never navigates and never holds app state.

## Layers

```
lib/morph_view.dart                  public exports only
lib/src/
  models/                            immutable value types
    display_environment.dart         snapshot + derived getters
    morph_feature.dart               validated hinge / fold / cutout
    display_capabilities.dart        CapabilityStatus per capability, per platform
    display_region.dart              DisplayRegion, RegionLayout
    window_size_class.dart           Material 3 breakpoints
    display_enums.dart
  core/                              pure Dart geometry, no Flutter bindings
    feature_normalizer.dart          validation, clipping, de-duplication, ordering
    region_resolver.dart             split the window into usable regions
  platform/
    display_environment_source.dart  adapter contract + FlutterView-backed implementation
  display_environment_observer.dart  binding observer, dedup, errors, disposal
  widgets/                           Flutter integration
    morph_view.dart                  InheritedWidget scope
    morph_layout_builder.dart        LayoutBuilder + environment
    morph_two_pane.dart              fold-aware two-pane layout
```

Dependencies only point downward: widgets → observer/models → core. The core
is testable with plain `Rect`s and `Size`s.

## Why there is no native plugin code

The guide asks for platform-specific code "only when justified by actual
platform requirements". Research showed it isn't needed:

- **Android:** the Flutter embedding already subscribes to Jetpack
  WindowManager's `WindowLayoutInfo` and forwards each `FoldingFeature`
  (bounds, hinge vs. fold, flat vs. half-opened) and display cutout to
  `FlutterView.displayFeatures` (see `dart:ui` `DisplayFeature`,
  `DisplayFeatureType`, `DisplayFeatureState`). A MorphView plugin would
  duplicate this, add a second listener, and add Gradle and SDK requirements.
- **iOS:** there is no public API for fold, hinge or posture information. A
  native plugin would have nothing to report.
- **Web and desktop:** the engine reports window metrics. There is no fold
  API to bridge.

As a result the package is pure Dart, supports every Flutter platform and
needs no setup. Platform differences live in one place,
`DisplayCapabilities.forPlatform`, and data access sits behind
`DisplayEnvironmentSource`. If a platform gains a public API that the engine
does not forward, a native `DisplayEnvironmentSource` can be added (in a
federated `morph_view_<platform>` package if needed) without changing the
public API.

## Key decisions

| Decision | Rationale |
|---|---|
| Value-equal immutable snapshots | Lets every layer drop identical updates. `error` is left out of equality so repeated identical failures are not re-emitted. |
| `CapabilityStatus` with three states | Separates "the platform can't tell" from "the platform says none". |
| Capabilities upgraded from evidence | If a fold is reported, the platform clearly supports it, whatever the static table says. |
| `MorphView` reads aspect-specific `MediaQuery` getters | Unrelated changes (keyboard insets, text scale) don't rebuild dependents. |
| `MorphView.of` falls back to `MediaQuery` | The package can be adopted one widget at a time, with no root wrapper required. |
| Size class from local constraints in `MorphLayoutBuilder` | A pane inside a split view should classify its own width, not the screen's. |
| `MorphTwoPane` only uses fold geometry when aligned with the window | Global offsets aren't reliably known during layout. Matching the window extent along the split axis proves the alignment. Otherwise it falls back deterministically. |
| `Flex` with stable child slots in `MorphTwoPane` | Pane state survives switches between fold mode, ratio mode and axes. |
| Lookup maps for `dart:ui` enums | The web engine's `DisplayFeatureState` has extra values, and enums can grow, so exhaustive switches would break compilation. |
| No dependencies beyond Flutter | Smallest possible footprint, and no conflicts with the app's state-management choice. |
