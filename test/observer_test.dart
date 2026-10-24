import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morph_view/morph_view.dart';

class FakeSource implements DisplayEnvironmentSource {
  FakeSource(this.environment);

  DisplayEnvironment environment;
  Object? error;
  int reads = 0;

  @override
  DisplayEnvironment read() {
    reads++;
    final e = error;
    if (e != null) throw e;
    return environment;
  }
}

const small = DisplayEnvironment(windowSize: Size(400, 800));
const large = DisplayEnvironment(windowSize: Size(1000, 800));

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('DisplayEnvironmentObserver', () {
    late FakeSource source;
    late DisplayEnvironmentObserver observer;

    setUp(() {
      source = FakeSource(small);
      observer = DisplayEnvironmentObserver(source: source);
    });

    tearDown(() => observer.dispose());

    test('reads the initial value immediately', () {
      expect(observer.value, small);
      expect(observer.current, small);
      expect(source.reads, 1);
    });

    test('notifies listeners and the stream only on change', () async {
      var notifications = 0;
      observer.addListener(() => notifications++);
      final emitted = <DisplayEnvironment>[];
      final sub = observer.changes.listen(emitted.add);

      observer.refresh();
      expect(notifications, 0, reason: 'identical snapshot is deduplicated');

      source.environment = large;
      observer.refresh();
      observer.refresh();
      expect(notifications, 1);
      expect(emitted, [large]);
      expect(observer.value, large);

      // A fresh but equal instance is still deduplicated.
      source.environment =
          const DisplayEnvironment(windowSize: Size(1000, 800));
      observer.refresh();
      expect(notifications, 1);
      await sub.cancel();
    });

    test('reacts to window metric changes from the binding', () {
      source.environment = large;
      binding.handleMetricsChanged();
      expect(observer.value, large);
    });

    test('turns source errors into unavailable snapshots', () {
      final emitted = <DisplayEnvironment>[];
      observer.changes.listen(emitted.add);

      source.error = StateError('platform failure');
      observer.refresh();
      expect(observer.value.status, DisplayEnvironmentStatus.unavailable);
      expect(observer.value.windowSize, small.windowSize,
          reason: 'last good geometry is kept');
      expect(observer.value.error, isA<StateError>());

      // Repeated identical failures are not re-emitted.
      observer.refresh();
      expect(emitted, hasLength(1));

      source.error = null;
      observer.refresh();
      expect(observer.value, small);
      expect(emitted, hasLength(2));
    });

    test('initial read failure yields an empty unavailable snapshot', () {
      final failing = FakeSource(small)..error = Exception('no view');
      final o = DisplayEnvironmentObserver(source: failing);
      addTearDown(o.dispose);
      expect(o.value.isReady, isFalse);
      expect(o.value.windowSize, Size.zero);
    });

    test('dispose stops observing and is idempotent', () async {
      var done = false;
      observer.changes.listen((_) {}, onDone: () => done = true);
      observer.dispose();
      observer.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(done, isTrue);
      expect(observer.isDisposed, isTrue);

      final readsBefore = source.reads;
      binding.handleMetricsChanged();
      expect(source.reads, readsBefore, reason: 'observer was removed');
      expect(observer.value, small, reason: 'last value is still readable');
    });

    test('use after dispose throws StateError', () {
      observer.dispose();
      expect(() => observer.refresh(), throwsStateError);
      expect(() => observer.addListener(() {}), throwsStateError);
      expect(() => observer.changes, throwsStateError);
      // Removing a listener after dispose is harmless.
      observer.removeListener(() {});
    });

    test('removeListener stops notifications', () {
      var count = 0;
      void listener() => count++;
      observer.addListener(listener);
      observer.removeListener(listener);
      source.environment = large;
      observer.refresh();
      expect(count, 0);
    });
  });

  group('FlutterViewEnvironmentSource', () {
    testWidgets('reads logical geometry and features from the view',
        (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.padding = const FakeViewPadding(top: 48);
      tester.view.displayFeatures = const [
        ui.DisplayFeature(
          // FlutterView.displayFeatures bounds are already logical.
          bounds: Rect.fromLTWH(390, 0, 20, 600),
          type: ui.DisplayFeatureType.hinge,
          state: ui.DisplayFeatureState.postureFlat,
        ),
      ];
      addTearDown(tester.view.reset);

      final env = FlutterViewEnvironmentSource(
        view: tester.view,
        capabilities: DisplayCapabilities.unknown,
      ).read();
      expect(env.windowSize, const Size(800, 600));
      expect(env.padding.top, 24);
      expect(env.features.single.bounds, const Rect.fromLTWH(390, 0, 20, 600));
      expect(env.posture, DisplayPosture.flat);
      expect(env.capabilities.foldGeometry, CapabilityStatus.supported);
    });

    testWidgets('defaults to the implicit view', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(500, 900);
      addTearDown(tester.view.reset);
      expect(FlutterViewEnvironmentSource().read().windowSize,
          const Size(500, 900));
    });

    testWidgets('observer with the default source tracks resizes',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.reset);
      final observer = DisplayEnvironmentObserver();
      addTearDown(observer.dispose);
      expect(observer.value.sizeClass, WindowSizeClass.compact);

      tester.view.physicalSize = const Size(1000, 800);
      await tester.pump();
      expect(observer.value.sizeClass, WindowSizeClass.expanded);
    });
  });
}
