import 'package:flutter/widgets.dart';

import '../models/display_capabilities.dart';
import '../models/display_environment.dart';

/// Provides the [DisplayEnvironment] to its descendants.
///
/// Place it once near the top of the tree, below `MaterialApp`/`WidgetsApp`
/// or any other widget that provides a [MediaQuery]:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => MorphView(child: child!),
///   home: const HomePage(),
/// );
/// ```
///
/// Descendants read the environment with [MorphView.of]. They rebuild only
/// when the environment actually changes, not on every `MediaQuery` change
/// (for example, the keyboard opening does not rebuild them).
///
/// Adding a [MorphView] is optional: [MorphView.of] falls back to reading
/// the nearest [MediaQuery] directly, so the package can be adopted one
/// widget at a time.
class MorphView extends StatelessWidget {
  /// Creates a display-environment scope.
  const MorphView({super.key, required this.child, this.capabilities});

  /// The widget below this widget in the tree.
  final Widget child;

  /// Overrides the reported capabilities. Defaults to
  /// [DisplayCapabilities.current]. Mostly useful in tests and previews.
  final DisplayCapabilities? capabilities;

  /// Returns the nearest [DisplayEnvironment] and registers [context] to
  /// rebuild when it changes.
  ///
  /// Without a [MorphView] ancestor, the environment is built from the
  /// nearest [MediaQuery]. Throws a [FlutterError] if there is neither.
  static DisplayEnvironment of(BuildContext context) {
    final environment = maybeOf(context);
    if (environment == null) {
      throw FlutterError.fromParts([
        ErrorSummary('MorphView.of() called with no MediaQuery in scope.'),
        ErrorHint(
          'Wrap your app in MaterialApp, CupertinoApp or WidgetsApp, or '
          'provide a MediaQuery above the widget calling MorphView.of().',
        ),
        context.describeElement('The context used was'),
      ]);
    }
    return environment;
  }

  /// Like [of], but returns null when there is neither a [MorphView] nor a
  /// [MediaQuery] above [context].
  static DisplayEnvironment? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_MorphScope>();
    if (scope != null) return scope.environment;
    if (MediaQuery.maybeOf(context) == null) return null;
    return _environmentFromMediaQuery(context, null);
  }

  @override
  Widget build(BuildContext context) {
    return _MorphScope(
      environment: _environmentFromMediaQuery(context, capabilities),
      child: child,
    );
  }

  /// Reads only the MediaQuery aspects MorphView uses, so unrelated changes
  /// (text scale, keyboard insets, brightness) do not trigger a rebuild.
  static DisplayEnvironment _environmentFromMediaQuery(
    BuildContext context,
    DisplayCapabilities? capabilities,
  ) {
    return DisplayEnvironment.resolve(
      windowSize: MediaQuery.sizeOf(context),
      padding: MediaQuery.paddingOf(context),
      displayFeatures: MediaQuery.displayFeaturesOf(context),
      capabilities: capabilities,
    );
  }
}

class _MorphScope extends InheritedWidget {
  const _MorphScope({required this.environment, required super.child});

  final DisplayEnvironment environment;

  @override
  bool updateShouldNotify(_MorphScope oldWidget) =>
      environment != oldWidget.environment;
}
