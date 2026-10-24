import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../models/display_capabilities.dart';
import '../models/display_environment.dart';

/// Reads the current [DisplayEnvironment] from a platform.
///
/// This is the platform-adapter contract behind `DisplayEnvironmentObserver`.
/// The default, [FlutterViewEnvironmentSource], reads what the Flutter
/// engine reports. Implement this to inject fake data in tests or to bridge
/// a custom native integration.
///
/// [read] may throw. The observer turns errors into
/// [DisplayEnvironmentStatus.unavailable] snapshots.
abstract interface class DisplayEnvironmentSource {
  /// Returns the current display environment.
  DisplayEnvironment read();
}

/// Reads the display environment from a Flutter view.
///
/// On Android, the Flutter engine fills `FlutterView.displayFeatures` from
/// Jetpack WindowManager (folds, hinges, posture) and display cutouts. On
/// other platforms only window metrics are reported. See
/// [DisplayCapabilities.forPlatform].
class FlutterViewEnvironmentSource implements DisplayEnvironmentSource {
  /// Creates a source for [view], or for the app's implicit view when [view]
  /// is null.
  ///
  /// [capabilities] defaults to [DisplayCapabilities.current].
  FlutterViewEnvironmentSource({this.view, this.capabilities});

  /// The view to read. When null, the implicit view is used, falling back to
  /// the first view.
  final ui.FlutterView? view;

  /// The capabilities to report. When null, [DisplayCapabilities.current]
  /// is used on every read.
  final DisplayCapabilities? capabilities;

  @override
  DisplayEnvironment read() {
    final target = view ?? _defaultView();
    if (target == null) {
      throw StateError(
          'No FlutterView is attached to the platform dispatcher.');
    }
    return DisplayEnvironment.fromMediaQuery(
      MediaQueryData.fromView(target),
      capabilities: capabilities,
    );
  }

  static ui.FlutterView? _defaultView() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final implicit = dispatcher.implicitView;
    if (implicit != null) return implicit;
    final views = dispatcher.views;
    return views.isEmpty ? null : views.first;
  }
}
