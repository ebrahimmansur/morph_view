import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'models/display_environment.dart';
import 'platform/display_environment_source.dart';

/// Watches the display environment outside the widget tree.
///
/// Use this in services, controllers or state-management layers that have
/// no `BuildContext`. Inside widgets, prefer `MorphView.of`.
///
/// ## Semantics
///
/// * **Initialization:** the environment is read right away in the
///   constructor, so [value] is never stale. A [WidgetsBinding] must exist
///   (call `WidgetsFlutterBinding.ensureInitialized()` before `runApp` if
///   you create one early).
/// * **Updates:** the environment is read again whenever the window metrics
///   change (resize, rotation, fold/unfold, posture change) or when
///   [refresh] is called. Listeners and [changes] are notified only when the
///   new snapshot is different from the previous one.
/// * **Errors:** if the source throws, the observer emits an
///   [DisplayEnvironmentStatus.unavailable] snapshot that keeps the last
///   good geometry. The error is available in [DisplayEnvironment.error].
/// * **Disposal:** [dispose] unregisters from the binding and closes
///   [changes]. It can be called more than once. Listening or refreshing
///   after disposal throws a [StateError].
class DisplayEnvironmentObserver
    with WidgetsBindingObserver
    implements ValueListenable<DisplayEnvironment> {
  /// Creates an observer and starts listening.
  ///
  /// [source] defaults to a [FlutterViewEnvironmentSource] for the implicit
  /// view. [binding] defaults to [WidgetsBinding.instance].
  DisplayEnvironmentObserver({
    DisplayEnvironmentSource? source,
    WidgetsBinding? binding,
  })  : _source = source ?? FlutterViewEnvironmentSource(),
        _binding = binding ?? WidgetsBinding.instance {
    _notifier = ValueNotifier(_read(null));
    _binding.addObserver(this);
  }

  final DisplayEnvironmentSource _source;
  final WidgetsBinding _binding;
  late final ValueNotifier<DisplayEnvironment> _notifier;
  final StreamController<DisplayEnvironment> _controller =
      StreamController<DisplayEnvironment>.broadcast(sync: true);
  bool _disposed = false;

  /// The latest snapshot. After [dispose] this is the last value seen.
  @override
  DisplayEnvironment get value => _notifier.value;

  /// The same as [value].
  DisplayEnvironment get current => value;

  /// Whether [dispose] has been called.
  bool get isDisposed => _disposed;

  /// A broadcast stream of changed snapshots.
  ///
  /// The current value is not replayed. Read [value] first if you need it.
  /// Consecutive identical snapshots are never emitted.
  Stream<DisplayEnvironment> get changes {
    _checkNotDisposed('changes');
    return _controller.stream;
  }

  @override
  void addListener(VoidCallback listener) {
    _checkNotDisposed('addListener');
    _notifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_disposed) return;
    _notifier.removeListener(listener);
  }

  /// Reads the source again and notifies listeners if the snapshot changed.
  void refresh() {
    _checkNotDisposed('refresh');
    final next = _read(_notifier.value);
    if (next == _notifier.value) return;
    _notifier.value = next;
    _controller.add(next);
  }

  /// Called by the framework when window metrics change. Do not call this
  /// yourself. Use [refresh] instead.
  @override
  void didChangeMetrics() {
    if (!_disposed) refresh();
  }

  /// Stops observing and releases resources. Safe to call more than once.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _binding.removeObserver(this);
    _notifier.dispose();
    unawaited(_controller.close());
  }

  DisplayEnvironment _read(DisplayEnvironment? previous) {
    try {
      return _source.read();
    } catch (error) {
      return DisplayEnvironment.unavailable(error: error, previous: previous);
    }
  }

  void _checkNotDisposed(String member) {
    if (_disposed) {
      throw StateError(
        'DisplayEnvironmentObserver.$member was used after dispose().',
      );
    }
  }
}
