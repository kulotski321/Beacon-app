# Beacon

**Know your distance.** A small Flutter app that tracks your device's location at a
fixed interval and shows how far you are from a target coordinate fetched from a
mock backend. Built as a Senior Flutter Engineer take-home.

On **Start**, Beacon fetches the target, then every 5 seconds (foreground only)
records the device position, computes the **Haversine** distance to the target,
persists the reading, and shows it in a filterable, newest-first list. **Stop**
halts collection immediately. Readings survive app restarts.

## Screenshot

> _Run `fvm flutter run` on a device and drop a capture at `docs/screenshot.png`._
> The home screen shows a navy status banner with the latest distance, a
> 5/10/15/20/All filter, the readings list, and a Start/Stop button (amber while
> tracking, with a pulsing "LIVE" badge in the app bar).

## Requirements coverage

| Requirement | Where |
|---|---|
| Start/Stop toggle, fetch target, 5 s foreground polling | `TrackingController` + `TrackingToggle` |
| Haversine distance (m / km) | `core/utils/haversine.dart` (hand-rolled) + `formatters.dart` |
| Store timestamp, lat, lng, distance | `LocationReading` + Hive (`reading_store.dart`) |
| Scrollable list of all readings | `home_screen.dart` + `reading_tile.dart` |
| Filter most recent 5 / 10 / 15 / 20 | `FilterSelector` + `TrackingController.setFilter` |
| Graceful permission handling | `location_service.dart` + snackbar / settings dialog |

## Setup & run

This project pins its Flutter version with [FVM](https://fvm.app)
(**Flutter 3.41.9 / Dart 3.11.5**, see `.fvm/fvm_config.json`).

```bash
# 1. Install the pinned SDK (reads .fvm/fvm_config.json)
fvm install

# 2. Fetch dependencies
fvm flutter pub get

# 3. Run on a connected device or emulator
fvm flutter run
```

Not using FVM? Any Flutter **≥ 3.41** (Dart ≥ 3.11) works — substitute plain
`flutter` for `fvm flutter`.

## Mock backend

The app fetches the target JSON:

```json
{ "id": "001", "target_lat": 1.265, "target_lng": 103.695 }
```

**Default (no setup):** a hosted copy of [`mock/target.json`](mock/target.json),
served from this repo via GitHub raw. It just works once the repo is pushed.

**Local server (optional):** serve the file and point the app at it with a
`--dart-define`, no code changes needed:

```bash
# serve mock/target.json (any static server works)
cd mock && python -m http.server 8080

# run against it
fvm flutter run --dart-define=TARGET_ENDPOINT=http://localhost:8080/target.json
```

> On the **Android emulator**, reach your host via `http://10.0.2.2:8080/...`,
> and note that Android blocks cleartext HTTP by default — the hosted HTTPS
> default avoids that. The local option is simplest on desktop/web/iOS.

## Architecture

Pragmatic layered architecture with a one-way dependency flow
(`presentation → application → data → core`). The UI talks only to the
`TrackingController`, which talks only to the `TrackingRepository`, so widgets
never touch http / geolocator / Hive directly. State management is **Riverpod**
(a `Notifier` holding an immutable `TrackingState`), keeping logic out of widgets
and fully unit-testable; the timer lives in the controller so tracking survives
rebuilds and is cancelled deterministically on stop and dispose.

```
lib/
├── main.dart                       # bootstrap: Hive.initFlutter + ProviderScope
├── app.dart                        # MaterialApp + Beacon theme (navy / amber)
├── core/utils/
│   ├── haversine.dart              # pure great-circle distance (unit-tested)
│   └── formatters.dart             # distance (m/km), coordinate, timestamp
├── data/
│   ├── models/
│   │   ├── target.dart
│   │   ├── location_reading.dart
│   │   └── location_reading_adapter.dart   # hand-written Hive adapter
│   ├── sources/
│   │   ├── target_api.dart         # http GET + typed error handling
│   │   ├── location_service.dart   # geolocator + permission flow
│   │   └── reading_store.dart      # hive_ce box: add / getAll / clear
│   └── repositories/
│       └── tracking_repository.dart
├── application/
│   ├── tracking_state.dart         # immutable state + visibleReadings filter
│   ├── tracking_controller.dart    # Riverpod Notifier: state machine + 5 s timer
│   └── providers.dart              # source + repository providers
└── presentation/
    ├── screens/home_screen.dart
    └── widgets/{tracking_toggle, filter_selector, reading_tile}.dart
```

**State machine:** `idle → fetchingTarget → tracking → idle`, with an `error`
branch for a failed target fetch or a blocked location read.

### Key packages
`flutter_riverpod` (state) · `geolocator` (location + permissions) · `http`
(mock fetch) · `hive_ce` / `hive_ce_flutter` (persistence) · `intl` (formatting).
Tested with `flutter_test`, `mocktail`, and `fake_async`.

## Tests

```bash
fvm flutter test       # 48 tests
fvm flutter analyze    # zero issues
```

Coverage includes: hand-rolled Haversine accuracy (an exact known value, a long
real-world pair, and a cross-check within 0.5 % of `Geolocator.distanceBetween`),
formatters, model JSON round-trips, the API's error handling (timeout / non-200 /
malformed JSON via `MockClient`), the geolocator permission branches (`mocktail`),
a real temp-directory Hive round-trip, and the full controller state machine
including the 5-second timer (driven deterministically with `fake_async`).

## Assumptions

- **Immediate first reading** on Start (then every 5 s) — gives instant feedback
  and surfaces permission errors right away, rather than waiting 5 s.
- **Distance display:** `< 1000 m` → whole metres (`742 m`); `≥ 1000 m` →
  kilometres with 2 decimals (`12.48 km`). Earth radius 6,371,000 m (mean).
- **List is newest-first**; filtering is a pure view concern — storage always
  keeps every reading. An **"All"** option is added beyond the required 5/10/15/20.
- **Persistence:** Hive (`hive_ce`, manual adapter, no codegen); readings survive
  restarts. In-memory storage was not used.
- **Foreground only:** polling via `Timer.periodic`; no background tracking. If a
  position read takes longer than the 5 s interval, the overlapping tick is skipped.
- **Coordinates** shown to 5 decimal places; **timestamps** in device local time.
