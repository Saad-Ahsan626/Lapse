# Lapse brand assets

Source files exported from the design (`plan/design/assets`), with embedded metadata
stripped. They are **not bundled** into the app:

- In-app, the mark is drawn in code by `LogoMark` / `LapseLogoPainter`
  (`lib/core/widgets/logo_mark.dart`), and the wordmark is `Wordmark`.
- The PNG / SVG app icons are the inputs for `flutter_launcher_icons` and
  `flutter_native_splash` in Phase 6.

| File | Use |
|---|---|
| `logo-mark-indigo.svg` | #4F46E5 on light backgrounds |
| `logo-mark-indigo-dark.svg` | #818CF8 on dark backgrounds |
| `logo-mark-white.svg` | knockout on indigo |
| `logo-mark-ink.svg` | single-colour #12121A |
| `wordmark-light.svg`, `wordmark-dark.svg` | uses live text; convert to outlines before print |
| `app-icon-light(-1024).svg/png`, `app-icon-dark(-1024).svg/png` | launcher icon masters |

Geometry (48-unit master): ring r=19, stroke 5, round caps, gap 14/119.4 of the
circumference centred at 12 o'clock; checkmark 16,24.6 → 21.6,30.2 → 32,19.
