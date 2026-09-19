# Lapse

[![License: MIT](https://img.shields.io/badge/License-MIT-4F46E5.svg)](LICENSE)

**Cancel before it charges.**

Lapse is a subscription and free-trial tracker for Android. It reminds you *before* a
renewal or a trial charges you, keeps the cancel link one tap away, and shows how much
you've saved by cancelling what you don't use.

Local-first: no account, no backend, no bank linking. Your data stays on your device.

---

## Status

| Phase | Scope | State |
|---|---|---|
| 0 | Foundation & design system | ✅ Done |
| 1 | Domain & data layer (models, SQLite, billing engine) | ✅ Done |
| 2 | Catalog & Add / Edit | ⏳ Next |
| 3 | Home, All subscriptions, Detail | — |
| 4 | Notifications | — |
| 5 | Cancel flow, savings, celebration | — |
| 6 | Splash, onboarding, setup | — |
| 7 | Settings & backup | — |
| 8 | Motion & accessibility polish | — |
| 9 | QA & release | — |

Right now the app has the full design system, a tested domain and data layer (SQLite),
placeholder screens for every route, and two debug tools: the **Design Gallery** and
the **Data Inspector**.

## MVP features

- Add subscriptions and free trials in seconds from a catalog of popular services
- Reminders before a charge (7 / 3 / 1 day / same day) at a time you choose
- A **Cancel now ↗** link on every subscription and in the reminder notification
- Home dashboard: this month's total, yearly total, trials ending soon, upcoming charges
- Mark as cancelled → savings tracker ("Saved Rs 7,788 / year")
- Light and dark themes, reduce-motion support, JSON backup export / import

---

## Tech stack

| Concern | Choice |
|---|---|
| Framework | Flutter 3.41 · Dart 3.11 · **Android only** |
| State management | `flutter_riverpod` 3, providers written by hand |
| Routing | `go_router` |
| Database | `sqflite` (hand-written SQL) |
| Settings | `shared_preferences` |
| IDs | `uuid` |
| Vector assets | `flutter_svg` (bundled service logos) |
| Lints | `very_good_analysis` |
| Font | Plus Jakarta Sans (bundled, OFL) |

**No code generation.** The project doesn't use `build_runner`, `riverpod_generator`,
`freezed`, `json_serializable` or `drift`. Providers, models, `copyWith`, equality, JSON
mapping and SQL are all written by hand. Later phases add packages only when they need
them.

---

## Getting started

```bash
flutter pub get
flutter run                 # on a connected Android device / emulator
```

Other commands:

```bash
flutter analyze             # must report 0 issues
flutter test                # unit + widget tests
dart format lib test        # format
flutter build apk --debug   # debug APK
```

Requirements: Flutter 3.41+ (stable), Android SDK, JDK 17+. Minimum Android version:
**API 24 (Android 7.0)**, Flutter 3.41's minimum.

### Design Gallery (debug builds only)

Home shows an **Open design gallery** button in debug builds. The gallery renders every
design-system widget (colours, type scale, spacing, buttons, chips, inputs, rings, tiles,
brand, empty state) with:

- a **System / Light / Dark** theme switch
- a **Simulate reduce motion** toggle
- a **Replay** button in the app bar to restart animations

Use it to compare the widgets against the design file side by side.

### Data Inspector (debug builds only)

Home also shows **Open data inspector**. It works on the real database:

- **Seed sample data**: 8 subscriptions (monthly, yearly, custom, a trial, one overdue,
  one cancelled)
- **Roll over now**: logs charges for dates that have passed and moves them forward
- **+1 month / Reset time**: time travel with a fake clock
- **Clear all**
- Each row shows next date, days left, urgency, yearly and monthly cost, charge count, and
  has Cancel / Restore / Delete

---

## Project structure

Clean Architecture, feature-first.

```
lib/
├── main.dart                       # entry point: bootstrap, edge-to-edge
├── app/
│   ├── app.dart                    # MaterialApp.router, themes, system bars
│   ├── bootstrap.dart              # opens SQLite + settings, builds the ProviderContainer
│   ├── providers/theme_mode_provider.dart
│   └── router/                     # app_router.dart, routes.dart
├── core/
│   ├── database/                   # openAppDatabase, schema v1, migrations
│   ├── domain/                     # CalendarDate, Money, Urgency, Clock, currency by country
│   ├── errors/                     # ValidationException
│   ├── providers/                  # clock, today, ids, database, preferences
│   ├── motion/                     # durations, curves, reduceMotion()
│   ├── theme/                      # theme.dart barrel, ThemeData, tokens/
│   └── widgets/                    # widgets.dart barrel + brand/ buttons/ chips/
│                                   # inputs/ layout/ rings/ subscription/
└── features/
    ├── subscriptions/
    │   ├── domain/                 # entities, repository interface, BillingEngine,
    │   │                           # validator, use cases (pure Dart)
    │   ├── data/                   # SQLite data source, mappers, repository
    │   └── presentation/providers/ # service + list providers
    ├── settings/                   # AppSettings, repository over shared_preferences
    ├── debug/                      # Design Gallery, Data Inspector
    └── placeholders/               # stand-in screens until each phase lands

assets/
├── fonts/                          # Plus Jakarta Sans 400–800 + OFL.txt
├── brand/                          # logo / icon sources (not bundled; Phase 6 input)
└── logos/                          # bundled service logos (added in Phase 2)

test/                               # mirrors lib/, plus helpers/
```

Each feature follows the same layout as it grows:

```
features/<feature>/
├── domain/        # entities, repository interfaces, use cases (pure Dart)
├── data/          # data sources, mappers, repository implementations
└── presentation/  # providers, screens, widgets
```

---

## Conventions

- **Tokens only.** Widgets never use raw colours, sizes or durations. Use
  `context.lapse.colors.*`, `context.lapse.text.*`, `Space.*`, `Radii.*`, `Sizes.*` and
  `Motion.*`.
- **Barrels for features, direct imports inside `core/`.** Feature code imports
  `core/theme/theme.dart` and `core/widgets/widgets.dart`. Files inside `core/` import the
  exact file they need, which avoids import cycles.
- **Package imports** (`package:lapse/...`) everywhere in `lib/`.
- **Urgency is never colour-only.** Every urgency colour comes with text ("Tomorrow",
  "In 3 days", "Oct 24").
- **Money uses tabular figures** so digits don't shift while counting.
- **Money is `int` minor units** (`Money`), never `double`. **Billing dates are
  `CalendarDate`**, never `DateTime`, so time zones and daylight saving can't shift a day.
- **Reduce motion is respected.** Every animation checks `reduceMotion(context)`.
- **Accessibility:** tap targets are at least 44×44, and widgets have `Semantics` labels.
- **One widget per file**, named after the widget.
- **No comments or doc comments in code.** Names should explain the code; decisions are
  recorded in this README and the plan.

### Theme at a glance

| Token | Light | Dark |
|---|---|---|
| Primary | `#4F46E5` | `#818CF8` |
| Savings | `#10B981` | `#10B981` |
| Trial | `#8B5CF6` | `#8B5CF6` |
| Urgent (≤ 1 day) | `#EF4444` | `#EF4444` |
| Warning (≤ 3 days) | `#F59E0B` | `#F59E0B` |
| Background | `#FAFAFC` | `#0B0B12` |
| Surface | `#FFFFFF` | `#16161F` |

---

## Service logos

Real service logos are bundled in `assets/logos/`, **unmodified** and taken from each
company's official brand kit. They are used only to identify a service, and never in the
Play Store listing or in marketing. [`assets/logos/LOGOS.md`](assets/logos/LOGOS.md)
lists the rules and records where each logo came from.

## Licence

Lapse is released under the [MIT License](LICENSE).
Copyright (c) 2026 Muhammad Saad Ahsan.

Third-party:

- Plus Jakarta Sans: SIL Open Font License 1.1 (`assets/fonts/OFL.txt`)
- Service logos are trademarks of their respective owners. Lapse is not affiliated with
  or endorsed by them.
