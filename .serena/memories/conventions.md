# Conventions

## Test target membership (the main trap)
- `a-barTests` has no TEST_HOST and no `@testable import`: its Sources phase `S1000002` in `a-bar.xcodeproj/project.pbxproj` recompiles a whitelist of production files.
- A new test file, and every production file it touches (transitively), must be added to `S1000002`. A test file missing from the phase runs nothing and the suite still passes; `./scripts/check-test-membership.sh` is the only guard.
- Hence testable logic is factored into `a-bar/Logic/` as pure functions/structs with few dependencies; views stay thin.

## What tests must never call
- Test bundle has no privacy usage strings: touching a TCC-protected API aborts the whole test process. Never start `BluetoothService` (`IOBluetoothHostController`, `IOBluetoothDevice.pairedDevices()`) or CoreLocation in `WifiService`.
- IOKit, mach, CoreAudio, IORegistry are safe; `SystemInfoServiceTests` asserts only invariants true on a headless runner. Never call the setters (volume, mute, caffeinate).

## Coverage
- SwiftUI inflates executable lines ~4x; `Views/` + `Widgets/` are ~72% of lines, so overall coverage caps near 25%. The `logic coverage` badge (excludes `Views/`, `Widgets/`, `BarView.swift`) is the one that moves. Do not smoke-render views to chase the overall number.

## Style
- Parsers for CLI output (`tmutil`, `netstat`, yabai/aerospace JSON, `system_profiler`) live in `Logic/` with fixture-string tests.
- Settings decoding must tolerate missing keys (older `~/.a-barrc`); add defaults in `SettingsCodec.swift` and a codec test.
- Icons: template images; stroke-only SVGs rendered as grey squares, so Tabler icons ship as 128x128 template PNGs. Pipeline: fetch from `https://api.iconify.design/<prefix>.json?icons=a,b` (Python's urllib gets 403 without a `User-Agent` header), set `currentColor` to black, `rsvg-convert -w 128 -h 128`, imageset `Contents.json` with `"template-rendering-intent": "template"`. Tint in SwiftUI with a `ThemeColorRole` (example: `SolarEventKind.colorRole`).
- Networking: the app declares no `NSAppTransportSecurity` exception, so `URLSession` to plain `http://` (for example ip-api.com's free tier) fails silently. Use `ShellExecutor.run("curl -s ...")` as `WeatherWidget` and `SolarCoordinate` do, and retry until a result arrives (SB23-3180).
- `BaseWidgetView` draws a `theme.minor` chip by default. Content in `theme.minor` on it is invisible; use `theme.foreground.opacity(...)` for placeholders.
- A widget's settings pane writes through `settings.draftSettings` (`ABarSettingsBindable.binding(...)`). `settings.settings` is `private(set)`.
- Visual choices (icons, layout) are Sean's: show candidates before building.
