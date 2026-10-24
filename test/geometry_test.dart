import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morph_view/morph_view.dart';
import 'package:morph_view/src/core/feature_normalizer.dart';

const window = Size(800, 600);

MorphFeature hinge(Rect bounds) =>
    MorphFeature(bounds: bounds, kind: DisplayFeatureKind.hinge);

MorphFeature fold(Rect bounds,
        [DisplayPosture state = DisplayPosture.halfOpened]) =>
    MorphFeature(bounds: bounds, kind: DisplayFeatureKind.fold, state: state);

List<Rect> rects(RegionLayout layout) =>
    [for (final region in layout.regions) region.rect];

void main() {
  group('normalizeFeatures', () {
    test('drops non-finite and negative-size bounds', () {
      final result = normalizeFeatures([
        hinge(const Rect.fromLTRB(double.nan, 0, 10, 600)),
        hinge(const Rect.fromLTRB(0, 0, double.infinity, 600)),
        hinge(const Rect.fromLTRB(500, 0, 400, 600)),
        hinge(const Rect.fromLTRB(390, 0, 410, 600)),
      ], window);
      expect(result, [hinge(const Rect.fromLTRB(390, 0, 410, 600))]);
    });

    test('clips to the window and drops features outside it', () {
      final result = normalizeFeatures([
        hinge(const Rect.fromLTRB(390, -50, 410, 900)),
        hinge(const Rect.fromLTRB(900, 0, 920, 600)),
        fold(const Rect.fromLTRB(-10, 0, -10, 600)),
      ], window);
      expect(result, [hinge(const Rect.fromLTRB(390, 0, 410, 600))]);
    });

    test('keeps zero-width folds inside the window', () {
      final result = normalizeFeatures(
          [fold(const Rect.fromLTRB(400, 0, 400, 600))], window);
      expect(result, hasLength(1));
      expect(result.single.bounds.width, 0);
    });

    test('forces cutout posture to unknown and removes duplicates', () {
      const cutout = MorphFeature(
        bounds: Rect.fromLTWH(380, 0, 40, 20),
        kind: DisplayFeatureKind.cutout,
        state: DisplayPosture.flat,
      );
      final result = normalizeFeatures([cutout, cutout], window);
      expect(result, hasLength(1));
      expect(result.single.state, DisplayPosture.unknown);
    });

    test('sorts deterministically regardless of input order', () {
      final a = hinge(const Rect.fromLTRB(600, 0, 610, 600));
      final b = hinge(const Rect.fromLTRB(200, 0, 210, 600));
      final c = fold(const Rect.fromLTRB(0, 300, 800, 300));
      expect(normalizeFeatures([a, b, c], window), [b, a, c]);
      expect(normalizeFeatures([c, a, b], window), [b, a, c]);
    });

    test('breaks sort ties by kind, size and state', () {
      final narrowHinge = hinge(const Rect.fromLTRB(400, 0, 410, 600));
      final wideHinge = hinge(const Rect.fromLTRB(400, 0, 420, 600));
      final shortHinge = hinge(const Rect.fromLTRB(400, 0, 410, 300));
      final flatFold =
          fold(const Rect.fromLTRB(400, 0, 400, 600), DisplayPosture.flat);
      final openFold = fold(const Rect.fromLTRB(400, 0, 400, 600));
      final expected = [shortHinge, narrowHinge, wideHinge, flatFold, openFold];
      expect(normalizeFeatures(expected.reversed, window), expected);
    });

    test('returns nothing for an empty or invalid window', () {
      final features = [hinge(const Rect.fromLTRB(0, 0, 10, 10))];
      expect(normalizeFeatures(features, Size.zero), isEmpty);
      expect(normalizeFeatures(features, const Size(-1, 100)), isEmpty);
      expect(normalizeFeatures(features, const Size(double.infinity, 100)),
          isEmpty);
    });

    test('result is unmodifiable', () {
      final result = normalizeFeatures(
          [hinge(const Rect.fromLTRB(0, 0, 10, 600))], window);
      expect(() => result.add(result.first), throwsUnsupportedError);
    });
  });

  group('RegionResolver', () {
    test('no features yields one region covering the window', () {
      final layout = RegionResolver.resolve(window, const []);
      expect(rects(layout), [Offset.zero & window]);
      expect(layout.axis, isNull);
      expect(layout.isSplit, isFalse);
    });

    test('vertical hinge splits side by side and excludes the hinge', () {
      final layout = RegionResolver.resolve(
        window,
        [hinge(const Rect.fromLTRB(390, 0, 410, 600))],
      );
      expect(layout.axis, Axis.horizontal);
      expect(rects(layout), const [
        Rect.fromLTRB(0, 0, 390, 600),
        Rect.fromLTRB(410, 0, 800, 600),
      ]);
      expect([for (final r in layout.regions) r.index], [0, 1]);
      expect(layout.separators, hasLength(1));
    });

    test('horizontal half-opened fold stacks regions (tabletop)', () {
      final layout = RegionResolver.resolve(
        window,
        [fold(const Rect.fromLTRB(0, 280, 800, 280))],
      );
      expect(layout.axis, Axis.vertical);
      expect(rects(layout), const [
        Rect.fromLTRB(0, 0, 800, 280),
        Rect.fromLTRB(0, 280, 800, 600),
      ]);
    });

    test('unequal splits are preserved', () {
      final layout = RegionResolver.resolve(
        window,
        [hinge(const Rect.fromLTRB(250, 0, 260, 600))],
      );
      expect(layout.regions[0].size.width, 250);
      expect(layout.regions[1].size.width, 540);
    });

    test('flat folds only split when opted in', () {
      final flat =
          fold(const Rect.fromLTRB(400, 0, 400, 600), DisplayPosture.flat);
      expect(RegionResolver.resolve(window, [flat]).isSplit, isFalse);
      expect(
        RegionResolver.resolve(window, [flat], treatFlatFoldsAsSeparating: true)
            .isSplit,
        isTrue,
      );
    });

    test('cutouts and partial features never split', () {
      final layout = RegionResolver.resolve(window, [
        const MorphFeature(
          bounds: Rect.fromLTRB(380, 0, 420, 600),
          kind: DisplayFeatureKind.cutout,
        ),
        hinge(const Rect.fromLTRB(390, 100, 410, 500)),
      ]);
      expect(layout.isSplit, isFalse);
      expect(layout.isAmbiguous, isFalse);
      expect(layout.separators, isEmpty);
    });

    test('features within span tolerance still count as spanning', () {
      final layout = RegionResolver.resolve(
        window,
        [hinge(const Rect.fromLTRB(390, 0.5, 410, 599.5))],
      );
      expect(layout.isSplit, isTrue);
    });

    test('multiple parallel separators make several regions', () {
      final layout = RegionResolver.resolve(window, [
        hinge(const Rect.fromLTRB(500, 0, 510, 600)),
        hinge(const Rect.fromLTRB(200, 0, 210, 600)),
      ]);
      expect(rects(layout), const [
        Rect.fromLTRB(0, 0, 200, 600),
        Rect.fromLTRB(210, 0, 500, 600),
        Rect.fromLTRB(510, 0, 800, 600),
      ]);
      expect(layout.separators.first.bounds.left, 200);
    });

    test('mixed axes are ambiguous and fall back to one region', () {
      final layout = RegionResolver.resolve(window, [
        hinge(const Rect.fromLTRB(390, 0, 410, 600)),
        fold(const Rect.fromLTRB(0, 300, 800, 300)),
      ]);
      expect(layout.isAmbiguous, isTrue);
      expect(rects(layout), [Offset.zero & window]);
      expect(layout.separators, hasLength(2));
    });

    test('overlapping separators are ambiguous', () {
      final layout = RegionResolver.resolve(window, [
        hinge(const Rect.fromLTRB(380, 0, 420, 600)),
        hinge(const Rect.fromLTRB(400, 0, 440, 600)),
      ]);
      expect(layout.isAmbiguous, isTrue);
      expect(layout.regions, hasLength(1));
    });

    test('touching separators are not ambiguous', () {
      final layout = RegionResolver.resolve(window, [
        hinge(const Rect.fromLTRB(380, 0, 400, 600)),
        hinge(const Rect.fromLTRB(400, 0, 420, 600)),
      ]);
      expect(layout.isAmbiguous, isFalse);
      expect(rects(layout), const [
        Rect.fromLTRB(0, 0, 380, 600),
        Rect.fromLTRB(420, 0, 800, 600),
      ]);
    });

    test('regions are clipped to the safe area', () {
      final layout = RegionResolver.resolve(
        window,
        [hinge(const Rect.fromLTRB(390, 0, 410, 600))],
        padding: const EdgeInsets.fromLTRB(10, 24, 20, 30),
      );
      expect(rects(layout), const [
        Rect.fromLTRB(10, 24, 390, 570),
        Rect.fromLTRB(410, 24, 780, 570),
      ]);
    });

    test('regions swallowed by padding are dropped and renumbered', () {
      final layout = RegionResolver.resolve(
        window,
        [hinge(const Rect.fromLTRB(20, 0, 30, 600))],
        padding: const EdgeInsets.only(left: 40),
      );
      expect(rects(layout), const [Rect.fromLTRB(40, 0, 800, 600)]);
      expect(layout.regions.single.index, 0);
      expect(layout.axis, isNull);
      expect(layout.separators, hasLength(1));
    });

    test('a hinge covering the whole window falls back to the safe window', () {
      final layout = RegionResolver.resolve(
        window,
        [hinge(Offset.zero & window)],
      );
      expect(rects(layout), [Offset.zero & window]);
      expect(layout.isSplit, isFalse);
    });

    test('negative and non-finite padding is ignored', () {
      final layout = RegionResolver.resolve(
        window,
        const [],
        padding: const EdgeInsets.fromLTRB(-5, double.infinity, 0, 0),
      );
      expect(rects(layout), [Offset.zero & window]);
    });

    test('empty geometry yields no regions', () {
      expect(RegionResolver.resolve(Size.zero, const []), RegionLayout.empty);
      expect(
        RegionResolver.resolve(const Size(100, 0), const []).regions,
        isEmpty,
      );
      expect(
        RegionResolver.resolve(
          window,
          const [],
          padding: const EdgeInsets.symmetric(horizontal: 400),
        ).regions,
        isEmpty,
      );
    });

    test('resolution is deterministic for any input order', () {
      final features = [
        hinge(const Rect.fromLTRB(500, 0, 510, 600)),
        hinge(const Rect.fromLTRB(200, 0, 210, 600)),
        const MorphFeature(
          bounds: Rect.fromLTWH(0, 0, 30, 30),
          kind: DisplayFeatureKind.cutout,
        ),
      ];
      expect(
        RegionResolver.resolve(window, features),
        RegionResolver.resolve(window, features.reversed),
      );
    });
  });
}
