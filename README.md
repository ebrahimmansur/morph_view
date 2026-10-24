# MorphView

**One UI. Every screen.**

[![pub package](https://img.shields.io/pub/v/morph_view.svg)](https://pub.dev/packages/morph_view)
[![CI](https://github.com/ebrahimmansur/morph_view/actions/workflows/ci.yml/badge.svg)](https://github.com/ebrahimmansur/morph_view/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A cross-platform Flutter toolkit for display awareness and adaptive layouts.
MorphView tells your app what the display looks like: window size class,
safe area, folds, hinges, posture, and the usable regions between them. **Your
app decides how to present its content.**

> Use window geometry for responsive layouts; use verified display features
> for fold-aware layouts; let the application decide how to present its
> content.

- Pure Dart, with no native code to configure. It works on Android, iOS, web,
  Windows, macOS and Linux.
- Immutable snapshots with value equality, so you get no duplicate updates and
  no needless rebuilds.
- Honest capabilities: "unsupported" is never mixed up with "none found".
- Tested region geometry for hinges, folds, multiple features, malformed data
  and safe areas.
- No state-management or routing dependency.

## Contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [API overview](#api-overview)
- [Platform support and capability matrix](#platform-support-and-capability-matrix)
- [Coordinate spaces and safe areas](#coordinate-spaces-and-safe-areas)
- [Region resolution rules](#region-resolution-rules)
- [Integrating with your architecture](#integrating-with-your-architecture)
- [Testing your app](#testing-your-app)
- [Known limitations](#known-limitations)
- [Troubleshooting](#troubleshooting)
- [Migration](#migration)
- [Further reading](#further-reading)

## Installation

```bash
flutter pub add morph_view
```

Requirements: Dart `>=3.5.0`, Flutter `>=3.24.0`. You don't need any
Android, iOS or desktop setup. Fold and hinge data on Android comes from the
Flutter engine's built-in Jetpack WindowManager integration.

## Quick start

**1. Provide the environment** (optional, but recommended) once near the
root:

```dart
import 'package:morph_view/morph_view.dart';

MaterialApp(
  builder: (context, child) => MorphView(child: child!),
  home: const InboxPage(),
);
```

**2. Choose a layout from the space you actually have:**

```dart
MorphLayoutBuilder(
  builder: (context, info) {
    final twoPane = info.sizeClass.isAtLeast(WindowSizeClass.expanded) ||
        info.environment.hasSeparatingFeature;
    return twoPane
        ? MorphTwoPane(start: const MessageList(), end: const MessageDetail())
        : const MessageList();
  },
);
```

`MorphTwoPane` puts the panes on either side of a hinge or half-opened fold
when there is one, and splits by `fallbackRatio` otherwise.

**3. Read the environment anywhere:**

```dart
final env = MorphView.of(context);

env.sizeClass;              // WindowSizeClass.compact ... extraLarge
env.posture;                // DisplayPosture.flat / halfOpened / unknown
env.hasSeparatingFeature;   // a hinge or half-opened fold splits the window
env.regionLayout.regions;   // usable rectangles, safe-area clipped
env.capabilities.foldGeometry; // supported / unsupported / unknown
```

**4. Outside the widget tree** (services, controllers, blocs):

```dart
final observer = DisplayEnvironmentObserver();
observer.value;                        // current snapshot
final sub = observer.changes.listen(print); // only real changes
// ...
await sub.cancel();
observer.dispose();
```

See [`example/`](example) for a complete list-and-details app.

## API overview

| Type | Purpose |
|---|---|
| `DisplayEnvironment` | Immutable snapshot: `windowSize`, `padding`, `features`, `capabilities`, `status`, plus derived `sizeClass`, `orientation`, `posture`, `separatingFeatures`, `regionLayout`. |
| `MorphFeature` | A validated hinge, fold or cutout: `bounds`, `kind`, `state`, `isSeparating`, `isOccluding`, `orientation`. |
| `DisplayCapabilities` | `CapabilityStatus` (`supported` / `unsupported` / `unknown`) for `windowMetrics`, `foldGeometry`, `posture`, `cutouts`, `multipleRegions`. |
| `RegionResolver` / `RegionLayout` / `DisplayRegion` | Pure geometry that splits a window into usable regions. |
| `WindowSizeClass` | Material 3 width classes: compact < 600 ≤ medium < 840 ≤ expanded < 1200 ≤ large < 1600 ≤ extraLarge. |
| `MorphView` | InheritedWidget scope. `MorphView.of(context)` rebuilds only on real changes, and falls back to `MediaQuery` when no scope exists. |
| `MorphLayoutBuilder` | `LayoutBuilder` plus environment. Its `info.sizeClass` uses *local* constraints. |
| `MorphTwoPane` | Two panes that avoid a separating feature, keeping their state across layout changes. |
| `DisplayEnvironmentObserver` | `ValueListenable` and `Stream` of snapshots, with no `BuildContext`. |
| `DisplayEnvironmentSource` | Platform-adapter contract. Inject fakes in tests. |

### Lifecycle and update semantics

- **Initialization:** `DisplayEnvironmentObserver` reads synchronously in its
  constructor, so `value` is valid right away. `MorphView` reads during build.
- **Updates:** re-read whenever window metrics change (resize, rotation,
  fold/unfold, posture). Equal snapshots are never emitted, and keyboard,
  text-scale or brightness changes don't cause rebuilds.
- **Errors:** a throwing source produces a `DisplayEnvironmentStatus.unavailable`
  snapshot that keeps the last good geometry. The error is in `env.error`.
- **Disposal:** `observer.dispose()` is idempotent. Using the observer
  afterwards throws a `StateError`. Widgets clean up automatically.

## Platform support and capability matrix

| Capability | Android | iOS | Web | Windows / macOS / Linux |
|---|---|---|---|---|
| Window dimensions + live updates | ✅ | ✅ | ✅ | ✅ |
| Safe-area padding | ✅ | ✅ | ✅ | ✅ |
| Fold / hinge geometry | ✅ ¹ | ❌ unsupported ² | ❌ unsupported | ❌ unsupported |
| Separating hinges vs. folds | ✅ ¹ | ❌ | ❌ | ❌ |
| Posture (flat / half-opened) | ✅ ¹ | ❌ unsupported ² | ❌ | ❌ |
| Cutouts as display features | ✅ | ❔ unknown ³ | ❔ unknown | ❌ |
| Multiple usable regions | ✅ ¹ | ❌ single region | ❌ single region | ❌ single region |

1. Comes from Jetpack WindowManager `FoldingFeature`, which the Flutter Android
   embedding forwards to `FlutterView.displayFeatures`. The device must report
   it: foldables, dual-screen devices and foldable emulator profiles do.
   Other devices report no features, which is a real "none".
2. iOS has no public UIKit or SwiftUI API for fold, hinge or posture
   information. MorphView never uses private APIs and never guesses, so
   iOS falls back to responsive layouts.
3. Notches and the Dynamic Island always show up in safe-area padding.
   Whether they also appear as display features depends on the engine.

If a fold or hinge *is* reported at runtime, `foldGeometry`, `posture` and
`multipleRegions` are upgraded to `supported` on any platform. See
[`doc/capability_matrix.md`](doc/capability_matrix.md) for sources,
prerequisites and fallbacks.

## Coordinate spaces and safe areas

- All geometry is in **logical pixels**.
- Feature bounds and region rects are relative to the **top-left of the
  Flutter view** (the app window, not the physical screen). This is the same
  space as `MediaQueryData.displayFeatures`.
- `windowSize` is the space the app actually has: split-screen, freeform and
  desktop windows can be much smaller than the screen.
- `padding` is `MediaQueryData.padding` (system bars, notches, rounded
  corners). Feature bounds are **not** reduced by it. Regions **are** clipped
  to it.
- To place a widget that does not fill the window over a region, convert it
  with `RenderBox.globalToLocal`, or use `MorphTwoPane`, which handles the
  common case for you.

## Region resolution rules

`RegionResolver.resolve(windowSize, features, padding: ...)` is a pure
function with deterministic results:

1. **Normalize:** drop non-finite or negative-size bounds, clip to the
   window, drop features outside it, force cutout posture to `unknown`,
   remove duplicates, and sort top-to-bottom then left-to-right.
2. **Pick separators:** hinges and half-opened folds (flat folds too with
   `treatFlatFoldsAsSeparating: true`) that span the window edge to edge,
   within 1 px. Partial features and cutouts never split.
3. **Split:** parallel separators make N+1 regions. The separator's own
   bounds are excluded, so a 20 px hinge leaves a gap and a zero-width fold
   leaves none. Unequal splits are kept as they are.
4. **Ambiguity:** separators running in both directions, or overlapping
   ones, give `isAmbiguous: true` and a single region.
5. **Safe area:** regions are clipped to the window minus `padding`. Empty
   regions are dropped and the rest renumbered. If nothing survives, the safe
   window is used. If the safe window is empty, there are no regions.

## Integrating with your architecture

MorphView only *observes*. Keep business logic and app state where it already
lives, **above** the layout switch, so changing layouts never duplicates
logic or loses state:

```dart
// Any state holder works: ChangeNotifier, Bloc, Riverpod, signals...
class InboxPage extends StatefulWidget { ... }

class _InboxPageState extends State<InboxPage> {
  final controller = InboxController(); // selection + form state

  @override
  Widget build(BuildContext context) => MorphLayoutBuilder(
        builder: (context, info) => info.sizeClass.isAtLeast(WindowSizeClass.expanded)
            ? MorphTwoPane(start: ListPane(controller), end: DetailPane(controller))
            : controller.selected == null
                ? ListPane(controller)
                : DetailPane(controller),
      );
}
```

- **Bloc / Riverpod / Provider:** wrap a `DisplayEnvironmentObserver` in your
  own provider or stream, or just call `MorphView.of(context)` in widgets.
  There is no adapter to install.
- **Routing:** decide in your router's builder whether a detail route is a
  page (compact) or a pane (expanded). MorphView does not navigate.
- **Text input:** keep `TextEditingController`s in your state holder (see
  the example) so typed text survives layout changes.

## Testing your app

Everything is injectable and needs no hardware:

```dart
testWidgets('two panes around a hinge', (tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 600);
  tester.view.displayFeatures = const [
    DisplayFeature( // from dart:ui; bounds are logical pixels
      bounds: Rect.fromLTWH(390, 0, 20, 600),
      type: DisplayFeatureType.hinge,
      state: DisplayFeatureState.postureFlat,
    ),
  ];
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MyApp());
  // ...
});
```

- Pure geometry: call `RegionResolver.resolve` or build a
  `DisplayEnvironment(...)` directly.
- Non-widget code: implement `DisplayEnvironmentSource` and pass it to
  `DisplayEnvironmentObserver(source: ...)`.
- Platform capabilities: set `debugDefaultTargetPlatformOverride`, or pass
  `MorphView(capabilities: ...)`.

Run the package's own checks:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test                     # package
cd example && flutter test       # example app, including state preservation
```

## Known limitations

- **No iOS fold detection.** Apple has no public API for it. iOS always
  reports fold geometry and posture as `unsupported`. Responsive layouts work
  normally.
- **Web and desktop** report no display features, even on foldable hardware
  running a browser.
- **Android** reports features only when the device and OS expose them
  through Jetpack WindowManager. Some older foldables with vendor-specific
  APIs report nothing.
- `MorphTwoPane` can only place panes around a fold when it lines up with the
  window along the split axis (full width for side-by-side, full height for
  stacked). Otherwise it uses `fallbackRatio`. Put it outside an `AppBar` for
  tabletop layouts.
- One Flutter view at a time: `MorphView` follows the `MediaQuery` of its
  view, and the default observer uses the implicit view. Pass
  `FlutterViewEnvironmentSource(view: ...)` for others.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `features` is always empty on Android | The device or emulator profile does not report folding features. Use a foldable emulator profile ("7.6 Fold-in with outer display", "8 Fold-out"). |
| A flat fold does not split | By design: a flat fold is one continuous surface. Use `resolveRegions(treatFlatFoldsAsSeparating: true)` or `MorphTwoPane(treatFlatFoldsAsSeparating: true)`. |
| `MorphTwoPane` ignores the hinge | The widget is narrower or shorter than the window. See the limitations above. |
| `MorphView.of() called with no MediaQuery in scope` | Use it below `MaterialApp` / `CupertinoApp` / `WidgetsApp` or a `View`. |
| `StateError: ... used after dispose()` | Something listens to an observer after you disposed it. Cancel subscriptions first. |
| `status == unavailable` | The source threw (see `env.error`) or the window has zero size, for example while the app starts up. Geometry is the last known value. |

## Migration

0.1.0 is the first release, so there is nothing to migrate yet. Breaking
changes will be listed in [`CHANGELOG.md`](CHANGELOG.md) with before/after
snippets, and will follow semantic versioning: breaking changes bump the
minor version while below 1.0.0, and the major version after that.

## Further reading

- [`doc/architecture.md`](doc/architecture.md): design and rationale
- [`doc/capability_matrix.md`](doc/capability_matrix.md): sources,
  prerequisites, limitations and fallbacks per capability
- [`doc/release_checklist.md`](doc/release_checklist.md): pub.dev release
  steps

## Contributing

Issues and pull requests are welcome. See [`CONTRIBUTING.md`](CONTRIBUTING.md),
the [Code of Conduct](CODE_OF_CONDUCT.md) and the
[security policy](SECURITY.md).

## License

MIT. See [LICENSE](LICENSE).
