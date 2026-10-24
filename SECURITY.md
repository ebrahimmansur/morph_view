# Security Policy

## Scope

This covers the `morph_view` package published from this repository. MorphView is a pure Dart
package. It has no native code, makes no network requests and stores no data.

## Reporting a vulnerability

**Please do not open a public GitHub issue for a security vulnerability.**

Instead, use GitHub's private vulnerability reporting for this repository:
[github.com/ebrahimmansur/morph_view/security/advisories/new](https://github.com/ebrahimmansur/morph_view/security/advisories/new).
This opens a private discussion visible only to you and the maintainer until a fix is ready.

If you're unable to use that (for example, you don't have a GitHub account), you can reach the
maintainer directly through their GitHub profile: [@ebrahimmansur](https://github.com/ebrahimmansur).

Please include:
- Which version is affected.
- A description of the vulnerability and its potential impact.
- Steps to reproduce, or a minimal proof of concept, if you have one.

## What counts as in scope

Examples of things worth reporting privately:
- Platform data that can make MorphView crash an app or hang it (for example, a crafted display
  feature that causes unbounded work).
- A way for MorphView to leak information across Flutter views or isolates.

Not in scope: vulnerabilities in Flutter, Dart, or the Android/iOS platforms themselves. Please
report those to their respective maintainers.

## Response

This is a small, independently maintained project. There's no guaranteed SLA, but security
reports will be prioritized over regular issues and acknowledged as soon as possible.
