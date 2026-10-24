import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morph_view/morph_view.dart';

import 'display_info.dart';
import 'inbox_controller.dart';

/// The inbox screen. Shows one pane on compact windows and master-detail on
/// expanded windows or when a hinge separates the display.
class InboxPage extends StatefulWidget {
  /// Creates the inbox page.
  const InboxPage({super.key, this.observer});

  /// An optional observer to inject in tests. When null, the page creates
  /// and disposes its own.
  final DisplayEnvironmentObserver? observer;

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final InboxController _controller = InboxController();
  late final DisplayEnvironmentObserver _observer;
  late final bool _ownsObserver;
  StreamSubscription<DisplayEnvironment>? _subscription;
  int _environmentChanges = 0;

  @override
  void initState() {
    super.initState();
    // The observer works outside the widget tree. Here it just counts
    // environment changes, showing how a service or controller would
    // subscribe and clean up.
    _ownsObserver = widget.observer == null;
    _observer = widget.observer ?? DisplayEnvironmentObserver();
    _subscription = _observer.changes.listen((_) {
      if (mounted) setState(() => _environmentChanges++);
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    if (_ownsObserver) _observer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => MorphLayoutBuilder(
        builder: (context, info) {
          final environment = info.environment;
          final twoPane = info.sizeClass.isAtLeast(WindowSizeClass.expanded) ||
              environment.hasSeparatingFeature;
          return twoPane ? _buildTwoPane(context) : _buildSinglePane(context);
        },
      ),
    );
  }

  Widget _buildTwoPane(BuildContext context) {
    return Scaffold(
      key: const ValueKey('two-pane'),
      appBar: _appBar(context, title: 'Inbox'),
      body: MorphTwoPane(
        fallbackRatio: 0.38,
        fallbackGap: 1,
        start: _list(),
        end: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: _detail(),
        ),
      ),
    );
  }

  Widget _buildSinglePane(BuildContext context) {
    final selected = _controller.selected;
    if (selected == null) {
      return Scaffold(
        key: const ValueKey('list'),
        appBar: _appBar(context, title: 'Inbox'),
        body: _list(),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _controller.select(null);
      },
      child: Scaffold(
        key: const ValueKey('detail'),
        appBar: _appBar(
          context,
          title: selected.subject,
          leading: BackButton(onPressed: () => _controller.select(null)),
        ),
        body: _detail(),
      ),
    );
  }

  PreferredSizeWidget _appBar(
    BuildContext context, {
    required String title,
    Widget? leading,
  }) {
    return AppBar(
      title: Text(title),
      leading: leading,
      actions: [
        IconButton(
          tooltip: 'Display info',
          icon: const Icon(Icons.info_outline),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (context) =>
                DisplayInfoSheet(environmentChanges: _environmentChanges),
          ),
        ),
      ],
    );
  }

  Widget _list() {
    return Column(
      children: [
        const FoldStatusBanner(),
        Expanded(
          child: ListView(
            key: const PageStorageKey('message-list'),
            children: [
              for (final message in _controller.messages)
                ListTile(
                  key: ValueKey('message-${message.id}'),
                  leading: CircleAvatar(child: Text(message.sender[0])),
                  title: Text(message.subject),
                  subtitle: Text(message.sender),
                  selected: message.id == _controller.selected?.id,
                  onTap: () => _controller.select(message),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detail() {
    final message = _controller.selected;
    if (message == null) {
      return const Center(child: Text('Select a message'));
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(message.subject, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('From ${message.sender}'),
        const SizedBox(height: 16),
        Text(message.body),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('notes'),
          controller: _controller.notesFor(message),
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
