# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Beacon is a single-screen Flutter location-tracking app (a Senior Flutter Engineer take-home). On Start it fetches a target coordinate from a mock backend, polls device GPS every 5 s (foreground only), computes the Haversine distance, persists each reading, and shows them in a filterable, newest-first list. Stop halts collection immediately and readings survive restarts.

## Environment — read first

- **The Flutter SDK is pinned with FVM (`.fvm/fvm_config.json` → Flutter 3.41.9 / Dart 3.11.5). Run every Flutter/Dart command through `fvm` (`fvm flutter ...`, `fvm dart ...`).** Bare `flutter` may resolve to a different SDK.
- **`fvm` segfaults (exit 139) under Git Bash on this machine.** Run all `fvm` commands via **PowerShell** (the PowerShell tool), not the Bash tool. Plain `git`/file operations are fine in either shell.

## Commands

```powershell
fvm install                       # install the pinned SDK (reads .fvm/fvm_config.json)
fvm flutter pub get               # fetch dependencies
fvm flutter run                   # run on a connected device/emulator
fvm flutter analyze               # static analysis — must be clean (zero issues)
fvm flutter test                  # full suite (currently 53 tests)
fvm flutter test test/application/tracking_controller_test.dart   # one file
fvm flutter test --plain-name "stop cancels the timer"            # one test by name
```

Point the app at a different target backend without code changes via a compile-time define:

```powershell
fvm flutter run --dart-define=TARGET_ENDPOINT=http://localhost:8080/target.json
```

The default endpoint is a hosted copy of `mock/target.json` (GitHub raw). The mock payload shape is `{ "id": "001", "target_lat": 1.265, "target_lng": 103.695 }`.

## Architecture

Pragmatic **layered** architecture with a strict one-way dependency flow — deliberately *not* full Clean Architecture (no use-case classes / abstract-interface ceremony) given the single-screen scope.

```
presentation → application → data → core
```

- **`core/utils/`** — pure, dependency-free functions. `haversine.dart` is **hand-rolled** (mean Earth radius 6,371,000 m) and is intentionally **not** `Geolocator.distanceBetween` — the take-home asks for a from-scratch Haversine, so don't "simplify" it to the geolocator call. `formatters.dart` owns the display rule: `< 1000 m` → whole metres (`742 m`); `≥ 1000 m` → km with 2 decimals (`12.48 km`).
- **`data/`** — `models/` (framework-free value types with JSON round-trips), `sources/` (`target_api` http, `location_service` geolocator+permissions, `reading_store` Hive box), and `repositories/tracking_repository.dart`.
- **`application/`** — Riverpod. `TrackingController` (a `Notifier<TrackingState>`) holds all logic; `providers.dart` wires the sources and the repository.
- **`presentation/`** — widgets only; no business logic.

### The two seams that define the design

1. **`TrackingRepository` is the only thing the application layer talks to.** The controller never imports http / geolocator / Hive directly — it calls `fetchTarget`, `captureReading`, `readings`, `clearReadings`, `openLocationSettings`. Keep new data access behind this seam.
2. **`trackingRepositoryProvider` is the single override point for tests.** Every data source is constructor-injected (an `http.Client`, a `GeolocatorPlatform`, a Hive box name, and a `DateTime Function()? now` clock), so tests override one provider with a mock repo rather than stubbing the whole graph.

### State machine (in `tracking_controller.dart`)

`idle → fetchingTarget → tracking → idle`, with an `error` branch for a failed target fetch or a blocked location read.

- **Start** fetches the target, then takes an **immediate first reading** (this is what surfaces permission errors right away), and only then arms `Timer.periodic(5 s)`.
- The **timer lives in the controller**, not a widget, so tracking survives rebuilds. It is cancelled on `stop()` and via `ref.onDispose` — nothing keeps ticking after disposal.
- An overlap guard (`_capturing`) skips a tick if the previous GPS read is still in flight.
- Location failures carry a `LocationFailure` enum; the UI shows a snackbar for most errors but an "Open settings" dialog for `permissionDeniedForever`.

### Persistence

Hive via **`hive_ce` / `hive_ce_flutter`** (community fork, **no codegen**). `LocationReadingAdapter` is a **hand-written `TypeAdapter` with `typeId 0`** (hive_ce_flutter auto-registers adapters at typeId 200/201, so 0 is safe). Bootstrap order in `main.dart` matters: `Hive.initFlutter()` → `ReadingStore.init()` → `UncontrolledProviderScope`. The store throws `StateError` if used before `init()`.

## Testing conventions

`test/` mirrors `lib/`. Patterns in use: `MockClient` (`package:http/testing.dart`) for the API, `mocktail` for geolocator/repository, a real temp-directory Hive round-trip for the store, and **`fake_async`** to drive the 5 s timer deterministically. Inject the `now` clock when a test asserts on timestamps. Both `analyze` and the full suite must stay green.

## Conventions

- Dart 3.7+ wildcard params: use `(_, _)` for unused closure params, not `(_, __)`.
- Use `.withValues(alpha:)`, not the deprecated `.withOpacity()`.
- Theme is navy `#0B1F3A` primary / amber `#FFB020` secondary, Material 3.

## Knowledge base (gitignored)

`knowledge-base/` holds the authoritative spec and the live development checklist but is **gitignored** — it won't survive a fresh clone. `assignment-spec.md` wins on any conflict; `development-checklist.md` tracks phase/traceability status. Consult and update these when working from the project plan; never rely on them being present in CI or a clone.
