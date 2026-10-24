import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morph_view/morph_view.dart';

const verticalHinge = ui.DisplayFeature(
  bounds: Rect.fromLTWH(390, 0, 20, 600),
  type: ui.DisplayFeatureType.hinge,
  state: ui.DisplayFeatureState.postureFlat,
);

const horizontalFold = ui.DisplayFeature(
  bounds: Rect.fromLTWH(0, 280, 800, 0),
  type: ui.DisplayFeatureType.fold,
  state: ui.DisplayFeatureState.postureHalfOpened,
);

void setView(
  WidgetTester tester, {
  Size size = const Size(800, 600),
  List<ui.DisplayFeature> features = const [],
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.displayFeatures = features;
  addTearDown(tester.view.reset);
}

/// The test's root `View` already provides a MediaQuery that follows
/// `tester.view`, so only text direction is missing.
Widget app(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

class Probe extends StatelessWidget {
  const Probe({super.key, required this.onBuild});

  final void Function(DisplayEnvironment environment) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(MorphView.of(context));
    return const SizedBox.expand();
  }
}

class Counter extends StatefulWidget {
  const Counter({super.key, required this.label});

  final String label;

  @override
  State<Counter> createState() => CounterState();
}

class CounterState extends State<Counter> {
  int value = 0;

  @override
  Widget build(BuildContext context) => Text('${widget.label}:$value');
}

void main() {
  group('MorphView', () {
    testWidgets('provides the environment from MediaQuery', (tester) async {
      setView(tester, features: const [verticalHinge]);
      late DisplayEnvironment env;
      await tester.pumpWidget(app(
        MorphView(
          capabilities: DisplayCapabilities.unknown,
          child: Probe(onBuild: (e) => env = e),
        ),
      ));
      expect(env.windowSize, const Size(800, 600));
      expect(env.hasSeparatingFeature, isTrue);
      expect(env.regionLayout.regions, hasLength(2));
      expect(env.capabilities.foldGeometry, CapabilityStatus.supported);
    });

    testWidgets('rebuilds dependents only when the environment changes',
        (tester) async {
      setView(tester);
      var builds = 0;
      final probe = Probe(onBuild: (_) => builds++);
      Widget tree(double textScale) => MediaQuery(
            data: MediaQueryData(
              size: const Size(800, 600),
              textScaler: TextScaler.linear(textScale),
            ),
            child: MorphView(child: probe),
          );

      await tester.pumpWidget(tree(1));
      expect(builds, 1);

      await tester.pumpWidget(tree(2));
      expect(builds, 1, reason: 'text scale is not part of the environment');

      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(1000, 600)),
        child: MorphView(child: probe),
      ));
      expect(builds, 2);
    });

    testWidgets('reacts to fold and resize updates from the view',
        (tester) async {
      setView(tester);
      final seen = <DisplayEnvironment>[];
      await tester.pumpWidget(app(MorphView(child: Probe(onBuild: seen.add))));
      expect(seen.last.hasSeparatingFeature, isFalse);

      tester.view.displayFeatures = const [verticalHinge];
      await tester.pump();
      expect(seen.last.hasSeparatingFeature, isTrue);

      tester.view.physicalSize = const Size(400, 600);
      tester.view.displayFeatures = const [];
      await tester.pump();
      expect(seen.last.sizeClass, WindowSizeClass.compact);
      expect(seen.last.hasSeparatingFeature, isFalse);
    });

    testWidgets('of falls back to MediaQuery without a MorphView',
        (tester) async {
      setView(tester);
      late DisplayEnvironment env;
      await tester.pumpWidget(app(Probe(onBuild: (e) => env = e)));
      expect(env.windowSize, const Size(800, 600));
    });

    testWidgets('of throws without MediaQuery, maybeOf returns null',
        (tester) async {
      DisplayEnvironment? maybe =
          const DisplayEnvironment(windowSize: Size(1, 1));
      Object? error;
      // RawView, unlike View, does not insert a MediaQuery.
      await tester.pumpWidget(
        RawView(
          view: tester.view,
          child: Builder(builder: (context) {
            maybe = MorphView.maybeOf(context);
            try {
              MorphView.of(context);
            } catch (e) {
              error = e;
            }
            return const SizedBox();
          }),
        ),
        wrapWithView: false,
      );
      expect(maybe, isNull);
      expect(error, isA<FlutterError>());
    });
  });

  group('MorphLayoutBuilder', () {
    testWidgets('classifies local constraints, not the window', (tester) async {
      setView(tester, size: const Size(1200, 800));
      final infos = <MorphLayoutInfo>[];
      await tester.pumpWidget(app(MorphView(
        child: Row(
          children: [
            SizedBox(
              width: 500,
              child: MorphLayoutBuilder(builder: (context, info) {
                infos.add(info);
                return const SizedBox();
              }),
            ),
          ],
        ),
      )));
      expect(infos.last.size.width, 500);
      expect(infos.last.sizeClass, WindowSizeClass.compact);
      expect(infos.last.environment.sizeClass, WindowSizeClass.large);
      expect(infos.last.toString(), contains('compact'));
    });

    testWidgets('uses window size for unbounded axes', (tester) async {
      setView(tester);
      late MorphLayoutInfo info;
      await tester.pumpWidget(app(SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: MorphLayoutBuilder(builder: (context, i) {
          info = i;
          return const SizedBox(width: 10, height: 10);
        }),
      )));
      expect(info.size.width, 800);
      expect(info, info);
    });

    testWidgets('switches layouts as the window resizes', (tester) async {
      setView(tester, size: const Size(400, 800));
      Widget build() => app(MorphView(
            child: MorphLayoutBuilder(
              builder: (context, info) => Text(info.sizeClass.name),
            ),
          ));
      await tester.pumpWidget(build());
      expect(find.text('compact'), findsOneWidget);

      tester.view.physicalSize = const Size(700, 800);
      await tester.pump();
      expect(find.text('medium'), findsOneWidget);

      tester.view.physicalSize = const Size(900, 800);
      await tester.pump();
      expect(find.text('expanded'), findsOneWidget);
    });
  });

  group('MorphTwoPane', () {
    Widget panes({double ratio = 0.5, Axis axis = Axis.horizontal}) =>
        app(MorphView(
          child: MorphTwoPane(
            fallbackRatio: ratio,
            fallbackAxis: axis,
            fallbackGap: 0,
            start: const Counter(key: Key('start'), label: 'start'),
            end: const Counter(key: Key('end'), label: 'end'),
          ),
        ));

    Rect rectOf(WidgetTester tester, String key) =>
        tester.getRect(find.byKey(Key(key)));

    testWidgets('splits by ratio without a fold', (tester) async {
      setView(tester);
      await tester.pumpWidget(panes(ratio: 0.25));
      expect(rectOf(tester, 'start'), const Rect.fromLTWH(0, 0, 200, 600));
      expect(rectOf(tester, 'end'), const Rect.fromLTWH(200, 0, 600, 600));
    });

    testWidgets('stacks by ratio on the vertical fallback axis',
        (tester) async {
      setView(tester);
      await tester.pumpWidget(panes(axis: Axis.vertical));
      expect(rectOf(tester, 'start'), const Rect.fromLTWH(0, 0, 800, 300));
      expect(rectOf(tester, 'end'), const Rect.fromLTWH(0, 300, 800, 300));
    });

    testWidgets('avoids a vertical hinge', (tester) async {
      setView(tester, features: const [verticalHinge]);
      await tester.pumpWidget(panes(ratio: 0.25));
      expect(rectOf(tester, 'start'), const Rect.fromLTWH(0, 0, 390, 600));
      expect(rectOf(tester, 'end'), const Rect.fromLTWH(410, 0, 390, 600));
    });

    testWidgets('stacks around a half-opened horizontal fold', (tester) async {
      setView(tester, features: const [horizontalFold]);
      await tester.pumpWidget(panes());
      expect(rectOf(tester, 'start'), const Rect.fromLTWH(0, 0, 800, 280));
      expect(rectOf(tester, 'end'), const Rect.fromLTWH(0, 280, 800, 320));
    });

    testWidgets('falls back to ratio when not aligned with the window',
        (tester) async {
      setView(tester, features: const [verticalHinge]);
      await tester.pumpWidget(app(MorphView(
        child: Padding(
          padding: const EdgeInsets.only(left: 100),
          child: MorphTwoPane(
            start: const SizedBox(key: Key('start')),
            end: const SizedBox(key: Key('end')),
          ),
        ),
      )));
      expect(rectOf(tester, 'start'), const Rect.fromLTWH(100, 0, 350, 600));
    });

    testWidgets('keeps pane state across fold and axis changes',
        (tester) async {
      setView(tester);
      await tester.pumpWidget(panes());
      tester.state<CounterState>(find.byKey(const Key('start'))).value = 7;
      tester.state<CounterState>(find.byKey(const Key('end'))).value = 3;

      tester.view.displayFeatures = const [horizontalFold];
      await tester.pump();
      expect(rectOf(tester, 'start').height, 280);

      tester.view.displayFeatures = const [verticalHinge];
      await tester.pump();
      expect(rectOf(tester, 'start').width, 390);

      expect(
          tester.state<CounterState>(find.byKey(const Key('start'))).value, 7);
      expect(tester.state<CounterState>(find.byKey(const Key('end'))).value, 3);
    });

    testWidgets('removes inner safe-area padding from each pane',
        (tester) async {
      setView(tester);
      late EdgeInsets startPadding;
      late EdgeInsets endPadding;
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          padding: EdgeInsets.fromLTRB(10, 20, 30, 40),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MorphTwoPane(
            start: Builder(builder: (context) {
              startPadding = MediaQuery.paddingOf(context);
              return const SizedBox();
            }),
            end: Builder(builder: (context) {
              endPadding = MediaQuery.paddingOf(context);
              return const SizedBox();
            }),
          ),
        ),
      ));
      expect(startPadding, const EdgeInsets.fromLTRB(10, 20, 0, 40));
      expect(endPadding, const EdgeInsets.fromLTRB(0, 20, 30, 40));
    });
  });
}
