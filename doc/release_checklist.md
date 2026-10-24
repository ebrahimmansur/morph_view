# Release checklist

Run these from the repository root before every `dart pub publish`.

## Code quality

- [ ] `dart format --set-exit-if-changed .` makes no changes
- [ ] `flutter analyze` reports no issues (package and `example/`)
- [ ] `flutter test` passes (package)
- [ ] `cd example && flutter test` passes
- [ ] `flutter test --platform chrome` passes (web `dart:ui` differs from
      native)
- [ ] Lower SDK bound still works: run `flutter analyze` and `flutter test`
      with Flutter 3.24 / Dart 3.5

## Example builds

- [ ] `cd example && flutter build apk --debug`
- [ ] `cd example && flutter build web`
- [ ] `cd example && flutter build windows` (or macOS/Linux on those hosts)
- [ ] `cd example && flutter build ios --no-codesign` (macOS host only)
- [ ] Manual check on a foldable emulator profile: fold, unfold,
      half-open, rotate, resize

## pub.dev metadata

- [ ] `version` in `pubspec.yaml` bumped, following semver
- [ ] `CHANGELOG.md` has a section for the new version (with migration notes
      for any breaking change)
- [ ] README capability matrix and limitations still match reality
- [ ] `homepage`, `repository` and `issue_tracker` URLs resolve
- [ ] `dart pub publish --dry-run` shows 0 warnings
- [ ] `dart pub global run pana .` scores 160/160

## Publish

- [ ] Commit, tag `vX.Y.Z`, push
- [ ] `dart pub publish`
- [ ] Check the package page, scores and API docs on pub.dev
