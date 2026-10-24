import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morph_view_example/main.dart';

void setWindow(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

const hinge = ui.DisplayFeature(
  bounds: Rect.fromLTWH(390, 0, 20, 700),
  type: ui.DisplayFeatureType.hinge,
  state: ui.DisplayFeatureState.postureFlat,
);

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(binding.platformDispatcher.implicitView!.reset);
  });

  testWidgets('compact window shows one pane at a time', (tester) async {
    setWindow(tester, const Size(400, 800));
    await tester.pumpWidget(const MorphViewExampleApp());

    expect(find.text('Fold-aware layouts'), findsOneWidget);
    expect(find.text('Select a message'), findsNothing);

    await tester.tap(find.text('Fold-aware layouts'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notes')), findsOneWidget);
    expect(find.text('Responsive fallback'), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Responsive fallback'), findsOneWidget);
  });

  testWidgets('expanded window shows master and detail', (tester) async {
    setWindow(tester, const Size(1000, 700));
    await tester.pumpWidget(const MorphViewExampleApp());
    expect(find.text('Select a message'), findsOneWidget);
    expect(find.text('Fold-aware layouts'), findsOneWidget);
  });

  testWidgets('selection and notes survive layout changes', (tester) async {
    setWindow(tester, const Size(1000, 700));
    await tester.pumpWidget(const MorphViewExampleApp());

    await tester.tap(find.text('State preservation'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('notes')), 'keep me');

    // Shrink to compact: the detail pane is shown alone, note intact.
    setWindow(tester, const Size(400, 800));
    await tester.pumpAndSettle();
    expect(find.text('Responsive fallback'), findsNothing);
    expect(find.text('keep me'), findsOneWidget);

    // Grow back to expanded: still selected, note intact.
    setWindow(tester, const Size(1000, 700));
    await tester.pumpAndSettle();
    expect(find.text('Responsive fallback'), findsOneWidget);
    expect(find.text('keep me'), findsOneWidget);
  });

  testWidgets('a hinge triggers a fold-aware two-pane layout', (tester) async {
    setWindow(tester, const Size(800, 700));
    tester.view.displayFeatures = const [hinge];
    await tester.pumpWidget(const MorphViewExampleApp());

    // 800px is only "medium", but the hinge separates the display.
    expect(find.text('Select a message'), findsOneWidget);
    expect(find.textContaining('Fold detected'), findsOneWidget);

    final list = tester.getRect(find.byType(ListView).first);
    expect(list.right, lessThanOrEqualTo(390));
    final detail = tester.getRect(find.text('Select a message'));
    expect(detail.left, greaterThanOrEqualTo(410));
  });

  testWidgets('without fold info the banner explains the fallback',
      (tester) async {
    setWindow(tester, const Size(400, 800));
    await tester.pumpWidget(const MorphViewExampleApp());
    // The test platform is Android by default, where fold geometry is
    // supported but none is reported.
    expect(
        find.text('No fold reported: using responsive layout'), findsOneWidget);
  });

  testWidgets('display info sheet lists the environment', (tester) async {
    setWindow(tester, const Size(400, 800));
    await tester.pumpWidget(const MorphViewExampleApp());
    await tester.tap(find.byTooltip('Display info'));
    await tester.pumpAndSettle();
    expect(find.text('Size class'), findsOneWidget);
    expect(find.text('compact'), findsOneWidget);
  });

  testWidgets('disposing the app releases the observer', (tester) async {
    setWindow(tester, const Size(400, 800));
    await tester.pumpWidget(const MorphViewExampleApp());
    await tester.pumpWidget(const SizedBox());
    // Metric changes after disposal must not throw.
    setWindow(tester, const Size(500, 800));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
