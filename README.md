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
| 2 | Catalog & Add / Edit | ✅ Done |
| 3 | Home, All subscriptions, Detail | ✅ Done |
| 4 | Notifications | ✅ Done (device check pending) |
| 5 | Cancel flow, savings, celebration | ✅ Done (device check pending) |
| 6 | Splash, onboarding, setup | ⏳ Next |
| 7 | Settings & backup | — |
| 8 | Motion & accessibility polish | — |
| 9 | QA & release | — |

Right now the app works end to end: Home shows this month's total, the
yearly total, savings, trials ending soon and upcoming charges; you can add subscriptions
and free trials from a catalog of 50 services, see each one's countdown and details,
**Cancel now ↗** straight to the service's cancel page, and mark subscriptions cancelled,
restore or delete them. **Reminder notifications** arrive before each charge at 09:00 (7 and
1 day before by default), with **Cancel now ↗** and **Snooze 1d** actions. Marking a
subscription cancelled opens a **celebration** with confetti and the yearly amount saved
(one tap to undo), and the Cancelled tab keeps a running savings total.

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
| Formatting | `intl` (money grouping, dates) |
| Links | `url_launcher` (Cancel now ↗) |
| Notifications | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
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

Open **Settings** (the sliders button on Home) in a debug build for **Open design gallery**. The gallery renders every
design-system widget (colours, type scale, spacing, buttons, chips, inputs, rings, tiles,
brand, empty state, celebration) with:

- a **System / Light / Dark** theme switch
- a **Simulate reduce motion** toggle
- a **Replay** button in the app bar to restart animations

Use it to compare the widgets against the design file side by side.

### Data Inspector (debug builds only)

Settings also shows **Open data inspector**. It works on the real database:

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
│   ├── domain/                     # CalendarDate, Money, Urgency, Clock, currencies
│   ├── errors/                     # ValidationException
│   ├── formatting/                 # formatMoney, parseMoneyInput, date labels
│   ├── providers/                  # clock, today, ids, database, preferences
│   ├── motion/                     # durations, curves, reduceMotion()
│   ├── theme/                      # theme.dart barrel, ThemeData, tokens/
│   └── widgets/                    # widgets.dart barrel + brand/ buttons/ chips/
│                                   # inputs/ layout/ rings/ subscription/
└── features/
    ├── catalog/                    # service catalog: entity, ranked search, JSON loader,
    │                               # providers, picker sheet (screen 06)
    ├── home/                       # Home screen (05): totals, trials, upcoming, empty state
    ├── savings/                    # cancellation stats + copy, celebration sheet (10),
    │                               # Cancelled-tab savings card
    ├── reminders/                  # notifications: planner (pure), plugin gateway, sync,
    │                               # background snooze, permission screen (03), Home banner
    ├── subscriptions/
    │   ├── domain/                 # entities, repository interface, BillingEngine,
    │   │                           # validator, use cases (pure Dart)
    │   ├── data/                   # SQLite data source, mappers, repository
    │   └── presentation/           # providers, form, actions, labels, links; screens:
    │                               # add/edit (07), detail (08), all subscriptions (09)
    ├── settings/                   # AppSettings, repository over shared_preferences
    ├── debug/                      # Design Gallery, Data Inspector
    └── placeholders/               # stand-in screens until each phase lands

assets/
├── catalog/services.json           # 50 services: name, category, brand colour, cancel link
├── fonts/                          # Plus Jakarta Sans 400–800 + OFL.txt
├── brand/                          # logo / icon sources (not bundled; Phase 6 input)
├── logos/                          # optional service logos: <key>.svg (bundled)
└── LOGOS.md                        # logo rules + source register (not bundled)

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

## How the totals work

- **This month:** charges already logged this calendar month plus charges still due before
  the month ends, for active subscriptions **including free trials** (their first charge is
  money at risk). Only the default currency is added up.
- **Per year:** the yearly cost of every active subscription (weekly × 52, monthly × 12,
  quarterly × 4, custom every N days × 365 / N).
- **Saved:** the yearly cost of everything you've cancelled (default currency). The same
  number appears on the Home pill, in the celebration after each cancel, and on the
  Cancelled tab.
- **Other currencies** are listed separately under the totals (no exchange rates).
- Charges whose date has passed are logged automatically when the app starts or comes back
  to the foreground, and the next date moves forward.

## How reminders work

- **Planner (pure Dart):** for every active subscription and each "Remind me" offset, a
  reminder at the reminder time (default 09:00) on `charge date − offset`. Past times are
  skipped, at most one per subscription per day, snoozes respected.
- **Sync:** whenever subscriptions or the reminder time change, and on start, resume and
  time-zone change, all pending reminders are cancelled and the plan is scheduled again.
  Nothing is scheduled until notification permission is granted.
- **Timing:** exact alarms when the user allows them, otherwise Android's inexact
  "allow while idle" alarms (may drift by a few minutes). Reminders survive a reboot.
- **Actions:** tapping opens the subscription; **Cancel now ↗** opens its cancel page;
  **Snooze 1d** runs in the background and stores `snoozedUntil`.
- **Permission** is asked in context (Home banner → permission screen), never on launch.
- Debug builds: Settings → Data Inspector → **Reminders** shows permission, pending count,
  the next 20 planned reminders, **Sync now** and **Fire test in 10 s**.

## Service catalog

`assets/catalog/services.json` lists the services offered when adding a subscription. Each
entry has a `key`, name, category, two-letter initials, brand colour, default billing
period, search aliases and, where known, the official **cancel link**. Prices are not
included: they differ by country and plan, so the user types them.

To add a service, add an entry (keys are `snake_case`). A test checks the file: unique keys,
popular ranks 1–11, https-only cancel links.

## Service logos

Service logos are optional: drop `assets/logos/<key>.svg` in and the tile uses it, otherwise
it shows the brand-coloured initials. Logos must be **unmodified** and taken from each
company's official brand kit. They are used only to identify a service, and never in the
Play Store listing or in marketing. [`assets/LOGOS.md`](assets/LOGOS.md)
lists the rules and records where each logo came from.

## Licence

Lapse is released under the [MIT License](LICENSE).
Copyright (c) 2026 Muhammad Saad Ahsan.

Third-party:

- Plus Jakarta Sans: SIL Open Font License 1.1 (`assets/fonts/OFL.txt`)
- Service logos are trademarks of their respective owners. Lapse is not affiliated with
  or endorsed by them.
