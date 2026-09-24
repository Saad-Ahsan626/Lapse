# Lapse brand assets

Source files exported from the design (`plan/design/assets`), with embedded metadata
stripped. They are **not bundled** into the app:

- In-app, the mark is drawn in code by `LogoMark` / `LapseLogoPainter`
  (`lib/core/widgets/brand/`), and the wordmark is `Wordmark`.
- The launcher icon and the native splash are hand-written Android resources
  (no `flutter_launcher_icons` / `flutter_native_splash`) under
  `android/app/src/main/res/`:
  - `mipmap-anydpi-v26/ic_launcher.xml`: adaptive icon with the
    `ic_launcher_background` colour (#4F46E5), the white vector
    `drawable/ic_launcher_foreground.xml` (48-unit mark scaled to 60dp inside
    the 108dp canvas, within the 66dp safe zone) and the same paths as
    `drawable/ic_launcher_monochrome.xml` for Android 13 themed icons.
  - `mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png`: legacy icons (48 to 192 px)
    resized once from `app-icon-light-1024.png` with a throwaway script.
  - Android 12+: `values-v31` / `values-night-v31` set
    `windowSplashScreenBackground` (#FAFAFC / #0B0B12) and a transparent
    `windowSplashScreenAnimatedIcon` (`drawable/splash_blank.xml`). Older
    versions use `drawable(-v21)/launch_background.xml` (background colour
    only). The system splash is just the app's background colour, so the
    Flutter splash draws the mark from scratch with no visible restart.

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
