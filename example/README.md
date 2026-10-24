# morph_view_example

An adaptive, fold-aware list-and-details app built with
[MorphView](https://pub.dev/packages/morph_view).

- **Compact windows** show one pane at a time (list, then details).
- **Expanded windows** show master and detail side by side.
- **Devices with a hinge or half-opened fold** place the panes on either side
  of it, even at medium widths.
- **Platforms without fold information** (iOS, web, desktop) show a banner and
  fall back to the responsive layout.
- **Selection and notes survive** every layout change, because the state lives
  in a plain `ChangeNotifier` above the layout switch.
- Tap the info button to see the live display environment.

```bash
flutter run            # any device
flutter test           # widget tests, including state preservation
```

To try fold-aware layouts without hardware, use an Android emulator with a
foldable or dual-screen profile (for example "7.6 Fold-in with outer
display"), or resize a desktop window to switch size classes.
