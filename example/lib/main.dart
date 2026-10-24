import 'package:flutter/material.dart';
import 'package:morph_view/morph_view.dart';

import 'src/inbox_page.dart';

void main() => runApp(const MorphViewExampleApp());

/// The MorphView example app: an adaptive list-and-details inbox.
class MorphViewExampleApp extends StatelessWidget {
  /// Creates the example app.
  const MorphViewExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MorphView',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      // One MorphView near the root provides the display environment to
      // every route.
      builder: (context, child) => MorphView(child: child!),
      home: const InboxPage(),
    );
  }
}
