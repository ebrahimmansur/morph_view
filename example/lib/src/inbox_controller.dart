import 'package:flutter/widgets.dart';

/// A message shown in the inbox.
@immutable
class Message {
  /// Creates a message.
  const Message({
    required this.id,
    required this.sender,
    required this.subject,
    required this.body,
  });

  /// A stable identifier.
  final int id;

  /// Who sent the message.
  final String sender;

  /// The subject line.
  final String subject;

  /// The message text.
  final String body;
}

/// App state for the inbox, kept in a plain [ChangeNotifier].
///
/// It lives *above* the layout switch, so the selection and the typed notes
/// survive changes between one and two panes. MorphView does not require any
/// particular state-management library. Bloc, Riverpod and others work the
/// same way.
class InboxController extends ChangeNotifier {
  /// Creates a controller holding [messages].
  InboxController({List<Message>? messages})
      : messages = List.unmodifiable(messages ?? _sampleMessages);

  /// All messages, in display order.
  final List<Message> messages;

  final Map<int, TextEditingController> _notes = {};
  int? _selectedId;

  /// The selected message, or null when nothing is selected.
  Message? get selected {
    final id = _selectedId;
    if (id == null) return null;
    for (final message in messages) {
      if (message.id == id) return message;
    }
    return null;
  }

  /// Selects [message], or clears the selection when it is null.
  void select(Message? message) {
    if (_selectedId == message?.id) return;
    _selectedId = message?.id;
    notifyListeners();
  }

  /// The notes field controller for [message], created on first use.
  TextEditingController notesFor(Message message) =>
      _notes.putIfAbsent(message.id, TextEditingController.new);

  @override
  void dispose() {
    for (final controller in _notes.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

const _sampleMessages = [
  Message(
    id: 1,
    sender: 'Ada',
    subject: 'Fold-aware layouts',
    body: 'On a dual-screen device, the list and the details sit on either '
        'side of the hinge instead of underneath it.',
  ),
  Message(
    id: 2,
    sender: 'Grace',
    subject: 'Responsive fallback',
    body: 'On iOS, web and desktop, no fold information is available, so the '
        'app falls back to an ordinary responsive layout based on window '
        'width.',
  ),
  Message(
    id: 3,
    sender: 'Linus',
    subject: 'State preservation',
    body: 'Type a note, then resize the window or fold the device. The '
        'selection and your note are kept.',
  ),
  Message(
    id: 4,
    sender: 'Margaret',
    subject: 'Tabletop posture',
    body: 'Half-fold a foldable phone with a horizontal fold, and the panes '
        'stack above and below the crease.',
  ),
  Message(
    id: 5,
    sender: 'Alan',
    subject: 'Window size classes',
    body: 'Compact windows show one pane at a time. Expanded windows show '
        'master and detail together.',
  ),
];
