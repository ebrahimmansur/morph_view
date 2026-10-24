import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morph_view/morph_view.dart';

void main() {
  group('WindowSizeClass', () {
    test('uses Material 3 breakpoints', () {
      expect(WindowSizeClass.fromWidth(0), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(599.9), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(839), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
      expect(WindowSizeClass.fromWidth(1200), WindowSizeClass.large);
      expect(WindowSizeClass.fromWidth(1600), WindowSizeClass.extraLarge);
    });

    test('handles invalid widths', () {
      expect(WindowSizeClass.fromWidth(-10), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(double.nan), WindowSizeClass.compact);
      expect(
        WindowSizeClass.fromWidth(double.infinity),
        WindowSizeClass.extraLarge,
      );
    });

    test('isAtLeast compares order', () {
      expect(
          WindowSizeClass.expanded.isAtLeast(WindowSizeClass.medium), isTrue);
      expect(
          WindowSizeClass.medium.isAtLeast(WindowSizeClass.expanded), isFalse);
      expect(WindowSizeClass.medium.isAtLeast(WindowSizeClass.medium), isTrue);
    });
  });

  group('MorphFeature', () {
    const hinge = MorphFeature(
      bounds: Rect.fromLTWH(390, 0, 20, 600),
      kind: DisplayFeatureKind.hinge,
    );

    test('value equality and copyWith', () {
      const same = MorphFeature(
        bounds: Rect.fromLTWH(390, 0, 20, 600),
        kind: DisplayFeatureKind.hinge,
      );
      expect(hinge, same);
      expect(hinge.hashCode, same.hashCode);
      expect(hinge.copyWith(state: DisplayPosture.flat), isNot(hinge));
      expect(hinge.copyWith(), hinge);
    });

    test('separating semantics match Android', () {
      expect(hinge.isSeparating, isTrue);
      const flatFold = MorphFeature(
        bounds: Rect.fromLTWH(400, 0, 0, 600),
        kind: DisplayFeatureKind.fold,
        state: DisplayPosture.flat,
      );
      expect(flatFold.isSeparating, isFalse);
      expect(
        flatFold.copyWith(state: DisplayPosture.halfOpened).isSeparating,
        isTrue,
      );
      const cutout = MorphFeature(
        bounds: Rect.fromLTWH(10, 0, 50, 30),
        kind: DisplayFeatureKind.cutout,
      );
      expect(cutout.isSeparating, isFalse);
    });

    test('occlusion and orientation', () {
      expect(hinge.isOccluding, isTrue);
      expect(hinge.orientation, Axis.vertical);
      const fold = MorphFeature(
        bounds: Rect.fromLTWH(0, 300, 800, 0),
        kind: DisplayFeatureKind.fold,
      );
      expect(fold.isOccluding, isFalse);
      expect(fold.orientation, Axis.horizontal);
      expect(
        hinge.copyWith(bounds: const Rect.fromLTWH(400, 0, 0, 600)).isOccluding,
        isFalse,
      );
    });

    test('converts from dart:ui DisplayFeature', () {
      const raw = ui.DisplayFeature(
        bounds: Rect.fromLTWH(0, 300, 800, 0),
        type: ui.DisplayFeatureType.fold,
        state: ui.DisplayFeatureState.postureHalfOpened,
      );
      final feature = MorphFeature.fromDisplayFeature(raw);
      expect(feature.kind, DisplayFeatureKind.fold);
      expect(feature.state, DisplayPosture.halfOpened);
      expect(feature.bounds, raw.bounds);

      final flatHinge = MorphFeature.fromDisplayFeature(
        const ui.DisplayFeature(
          bounds: Rect.zero,
          type: ui.DisplayFeatureType.hinge,
          state: ui.DisplayFeatureState.postureFlat,
        ),
      );
      expect(flatHinge.kind, DisplayFeatureKind.hinge);
      expect(flatHinge.state, DisplayPosture.flat);

      final unknown = MorphFeature.fromDisplayFeature(
        const ui.DisplayFeature(
          bounds: Rect.zero,
          type: ui.DisplayFeatureType.unknown,
          state: ui.DisplayFeatureState.unknown,
        ),
      );
      expect(unknown.kind, DisplayFeatureKind.unknown);
      expect(unknown.state, DisplayPosture.unknown);
    });
  });

  group('DisplayCapabilities', () {
    test('Android supports fold geometry and posture', () {
      final caps = DisplayCapabilities.forPlatform(
        TargetPlatform.android,
        isWeb: false,
      );
      expect(caps.foldGeometry, CapabilityStatus.supported);
      expect(caps.posture, CapabilityStatus.supported);
      expect(caps.multipleRegions, CapabilityStatus.supported);
      expect(caps.windowMetrics, CapabilityStatus.supported);
    });

    test('iOS reports fold geometry and posture as unsupported', () {
      final caps =
          DisplayCapabilities.forPlatform(TargetPlatform.iOS, isWeb: false);
      expect(caps.foldGeometry, CapabilityStatus.unsupported);
      expect(caps.posture, CapabilityStatus.unsupported);
      expect(caps.multipleRegions, CapabilityStatus.unsupported);
      expect(caps.cutouts, CapabilityStatus.unknown);
      expect(caps.windowMetrics.isSupported, isTrue);
    });

    test('desktop is responsive-only, fuchsia unknown, web unsupported', () {
      for (final platform in [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      ]) {
        final caps = DisplayCapabilities.forPlatform(platform, isWeb: false);
        expect(caps.foldGeometry, CapabilityStatus.unsupported);
      }
      expect(
        DisplayCapabilities.forPlatform(TargetPlatform.fuchsia, isWeb: false),
        DisplayCapabilities.unknown,
      );
      expect(
        DisplayCapabilities.forPlatform(TargetPlatform.android, isWeb: true),
        DisplayCapabilities.responsiveOnly,
      );
    });

    test('current follows defaultTargetPlatform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      // Flutter web never reports display features, even on Android.
      expect(
        DisplayCapabilities.current().foldGeometry,
        kIsWeb ? CapabilityStatus.unsupported : CapabilityStatus.supported,
      );
    });

    test('value equality and copyWith', () {
      const a = DisplayCapabilities(foldGeometry: CapabilityStatus.supported);
      expect(a,
          const DisplayCapabilities(foldGeometry: CapabilityStatus.supported));
      expect(a.copyWith(posture: CapabilityStatus.supported), isNot(a));
      expect(a.hashCode, a.copyWith().hashCode);
      expect(a.toString(), contains('foldGeometry: supported'));
    });
  });

  group('DisplayEnvironment', () {
    const size = Size(800, 600);
    const hinge = ui.DisplayFeature(
      bounds: Rect.fromLTWH(390, 0, 20, 600),
      type: ui.DisplayFeatureType.hinge,
      state: ui.DisplayFeatureState.postureHalfOpened,
    );

    test('resolve normalizes features and infers capabilities', () {
      final env = DisplayEnvironment.resolve(
        windowSize: size,
        displayFeatures: const [
          hinge,
          hinge,
          ui.DisplayFeature(
            bounds: Rect.fromLTWH(2000, 0, 10, 10),
            type: ui.DisplayFeatureType.cutout,
            state: ui.DisplayFeatureState.unknown,
          ),
        ],
        capabilities: DisplayCapabilities.responsiveOnly,
      );
      expect(env.features, hasLength(1));
      expect(env.capabilities.foldGeometry, CapabilityStatus.supported);
      expect(env.capabilities.posture, CapabilityStatus.supported);
      expect(env.posture, DisplayPosture.halfOpened);
      expect(env.hasSeparatingFeature, isTrue);
      expect(env.isReady, isTrue);
    });

    test('cutout features mark cutouts supported', () {
      final env = DisplayEnvironment.resolve(
        windowSize: size,
        displayFeatures: const [
          ui.DisplayFeature(
            bounds: Rect.fromLTWH(380, 0, 40, 24),
            type: ui.DisplayFeatureType.cutout,
            state: ui.DisplayFeatureState.unknown,
          ),
        ],
        capabilities: DisplayCapabilities.responsiveOnly,
      );
      expect(env.capabilities.cutouts, CapabilityStatus.supported);
      expect(env.capabilities.foldGeometry, CapabilityStatus.unsupported);
      expect(env.foldingFeatures, isEmpty);
      expect(env.posture, DisplayPosture.unknown);
    });

    test('unknown is distinct from confirmed absence', () {
      final android = DisplayEnvironment.resolve(
        windowSize: size,
        capabilities: DisplayCapabilities.forPlatform(TargetPlatform.android,
            isWeb: false),
      );
      final ios = DisplayEnvironment.resolve(
        windowSize: size,
        capabilities:
            DisplayCapabilities.forPlatform(TargetPlatform.iOS, isWeb: false),
      );
      expect(android.features, isEmpty);
      expect(ios.features, isEmpty);
      expect(android.capabilities.foldGeometry.isSupported, isTrue);
      expect(ios.capabilities.foldGeometry.isSupported, isFalse);
      expect(android.posture, DisplayPosture.unknown);
    });

    test('flat posture when every fold is flat', () {
      final env = DisplayEnvironment.resolve(
        windowSize: size,
        displayFeatures: const [
          ui.DisplayFeature(
            bounds: Rect.fromLTWH(400, 0, 0, 600),
            type: ui.DisplayFeatureType.fold,
            state: ui.DisplayFeatureState.postureFlat,
          ),
        ],
      );
      expect(env.posture, DisplayPosture.flat);
      expect(env.hasSeparatingFeature, isFalse);
      expect(env.regionLayout.isSplit, isFalse);
      expect(
        env.resolveRegions(treatFlatFoldsAsSeparating: true).isSplit,
        isTrue,
      );
    });

    test('invalid window size is reported as unavailable', () {
      final env = DisplayEnvironment.resolve(windowSize: Size.zero);
      expect(env.status, DisplayEnvironmentStatus.unavailable);
      expect(env.regionLayout.regions, isEmpty);
      final infinite = DisplayEnvironment.resolve(
          windowSize: const Size(double.infinity, 1));
      expect(infinite.windowSize, Size.zero);
      expect(infinite.isReady, isFalse);
    });

    test('derived getters', () {
      const env = DisplayEnvironment(windowSize: Size(1000, 700));
      expect(env.orientation, Orientation.landscape);
      expect(env.sizeClass, WindowSizeClass.expanded);
      const square = DisplayEnvironment(windowSize: Size(500, 500));
      expect(square.orientation, Orientation.portrait);
    });

    test('equality ignores error and covers every other field', () {
      const a = DisplayEnvironment(windowSize: size);
      expect(a, a.copyWith(error: Exception('x')));
      expect(a.hashCode, const DisplayEnvironment(windowSize: size).hashCode);
      expect(a, isNot(a.copyWith(padding: const EdgeInsets.only(top: 24))));
      expect(
        a,
        isNot(a.copyWith(status: DisplayEnvironmentStatus.unavailable)),
      );
      expect(
        a,
        isNot(a.copyWith(capabilities: DisplayCapabilities.responsiveOnly)),
      );
      expect(a.toString(), contains('medium'));
    });

    test('unavailable keeps previous geometry', () {
      final previous = DisplayEnvironment.resolve(
        windowSize: size,
        displayFeatures: const [hinge],
      );
      final error = StateError('boom');
      final env =
          DisplayEnvironment.unavailable(error: error, previous: previous);
      expect(env.windowSize, size);
      expect(env.features, previous.features);
      expect(env.status, DisplayEnvironmentStatus.unavailable);
      expect(env.error, error);

      final empty = DisplayEnvironment.unavailable();
      expect(empty.windowSize, Size.zero);
      expect(empty.capabilities, DisplayCapabilities.unknown);
    });

    test('fromMediaQuery reads size, padding and features', () {
      const data = MediaQueryData(
        size: size,
        padding: EdgeInsets.only(top: 24),
        displayFeatures: [hinge],
      );
      final env = DisplayEnvironment.fromMediaQuery(data);
      expect(env.windowSize, size);
      expect(env.padding, const EdgeInsets.only(top: 24));
      expect(env.features.single.kind, DisplayFeatureKind.hinge);
    });
  });

  group('DisplayRegion and RegionLayout', () {
    test('value equality', () {
      const r = DisplayRegion(rect: Rect.fromLTWH(0, 0, 10, 10), index: 0);
      expect(
          r, const DisplayRegion(rect: Rect.fromLTWH(0, 0, 10, 10), index: 0));
      expect(r.size, const Size(10, 10));
      expect(r.toString(), contains('#0'));
      const layout = RegionLayout(regions: [r]);
      expect(layout, const RegionLayout(regions: [r]));
      expect(layout.hashCode, const RegionLayout(regions: [r]).hashCode);
      expect(layout.isSplit, isFalse);
      expect(
          layout, isNot(const RegionLayout(regions: [r], isAmbiguous: true)));
    });
  });
}
