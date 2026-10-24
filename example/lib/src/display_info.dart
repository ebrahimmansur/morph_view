import 'package:flutter/material.dart';
import 'package:morph_view/morph_view.dart';

/// A one-line banner that explains how the layout is adapting.
class FoldStatusBanner extends StatelessWidget {
  /// Creates the banner.
  const FoldStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final environment = MorphView.of(context);
    final (IconData icon, String text) = _describe(environment);
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.secondaryContainer,
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: colors.onSecondaryContainer),
        title: Text(
          text,
          key: const ValueKey('fold-status'),
          style: TextStyle(color: colors.onSecondaryContainer),
        ),
      ),
    );
  }

  static (IconData, String) _describe(DisplayEnvironment environment) {
    if (environment.hasSeparatingFeature) {
      final layout = environment.regionLayout;
      final arrangement =
          layout.axis == Axis.vertical ? 'stacked' : 'side by side';
      return (
        Icons.vertical_split,
        'Fold detected (${environment.posture.name}): panes $arrangement',
      );
    }
    return switch (environment.capabilities.foldGeometry) {
      CapabilityStatus.supported when environment.foldingFeatures.isNotEmpty =>
        (Icons.tablet, 'Flat fold reported: using responsive layout'),
      CapabilityStatus.supported => (
          Icons.smartphone,
          'No fold reported: using responsive layout',
        ),
      CapabilityStatus.unsupported => (
          Icons.devices,
          'Fold info unavailable on this platform: using responsive layout',
        ),
      CapabilityStatus.unknown => (
          Icons.help_outline,
          'Fold support unknown: using responsive layout',
        ),
    };
  }
}

/// A bottom sheet that lists the current display environment.
class DisplayInfoSheet extends StatelessWidget {
  /// Creates the sheet.
  const DisplayInfoSheet({super.key, required this.environmentChanges});

  /// How many changes the page's observer has seen.
  final int environmentChanges;

  @override
  Widget build(BuildContext context) {
    final env = MorphView.of(context);
    final caps = env.capabilities;
    String size(Size s) =>
        '${s.width.toStringAsFixed(0)} x ${s.height.toStringAsFixed(0)}';
    final rows = <(String, String)>[
      ('Status', env.status.name),
      ('Window', size(env.windowSize)),
      ('Size class', env.sizeClass.name),
      ('Orientation', env.orientation.name),
      ('Posture', env.posture.name),
      ('Fold geometry', caps.foldGeometry.name),
      ('Posture support', caps.posture.name),
      ('Cutouts', caps.cutouts.name),
      ('Multiple regions', caps.multipleRegions.name),
      ('Observer updates', '$environmentChanges'),
      for (final f in env.features)
        ('Feature', '${f.kind.name} ${f.state.name} ${f.bounds}'),
      for (final r in env.regionLayout.regions)
        ('Region ${r.index}', '${size(r.size)} at ${r.rect.topLeft}'),
    ];
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final (label, value) in rows)
          ListTile(dense: true, title: Text(label), trailing: Text(value)),
      ],
    );
  }
}
