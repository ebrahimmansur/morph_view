# Contributing to morph_view

Thanks for considering a contribution. This repository holds one publishable package
(`morph_view`, at the root) and its example app (`example/`).

## Prerequisites

- The [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel).
- Optional: an Android emulator with a foldable or dual-screen profile (for example "7.6 Fold-in
  with outer display") to try fold-aware behavior by hand. Automated tests need no hardware.

## Workflow

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test                        # package
(cd example && flutter test)        # example app
flutter test --platform chrome      # web dart:ui differs from native
dart pub publish --dry-run
```

## Code style

- Run `dart format .` before committing. CI treats unformatted code as a failure.
- `analysis_options.yaml` enables `flutter_lints` plus `public_member_api_docs` and
  `strict-casts`/`strict-inference`/`strict-raw-types`. Every public class, member and function
  needs a real dartdoc comment that explains the *why* where it isn't obvious.
- No new lint suppressions (`// ignore:`) without a comment explaining why the rule doesn't apply.

## Architecture rules a PR must not break

See [`doc/architecture.md`](doc/architecture.md) for the full rationale.

- **Observe, don't decide.** MorphView reports display information and calculates geometry. It
  must not choose layouts for the app, navigate, or hold application state.
- **No unverified capabilities.** Every capability claim must be backed by a public, documented
  platform API. Never use private APIs, and never infer hardware from device model names. When a
  platform can't tell, report `CapabilityStatus.unsupported` or `unknown`.
- **No state-management or routing dependencies.** The package depends only on Flutter.
- **Pure core.** `lib/src/core/` has no binding or widget dependencies and must stay testable with
  plain `Rect`/`Size` values.
- **Keep native details out of the public API.** Platform specifics stay behind
  `DisplayEnvironmentSource` and `DisplayCapabilities.forPlatform`.
- **Be tolerant of `dart:ui` differences.** Don't exhaustively `switch` on engine enums: the web
  engine has extra values.

## Before opening a PR

- [ ] Tests added or updated for any behavior change, and every command in *Workflow* passes.
- [ ] `CHANGELOG.md` updated (with migration notes for any breaking change).
- [ ] README/`doc/` updated if the change affects documented behavior or the capability matrix.

## Filing a good bug report

Please include the package version, platform, device or emulator profile, `flutter --version`
output, and minimal steps to reproduce. Pasting `MorphView.of(context).toString()` from the
affected screen helps a lot. For anything that looks like a security issue, see
[`SECURITY.md`](SECURITY.md) instead of opening a public issue.
