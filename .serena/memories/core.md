# a-bar core

Native macOS menu bar replacement, Swift + SwiftUI, one Xcode project `a-bar.xcodeproj`, scheme `a-bar`.
Fork `SijanC147/a-bar` of `Jean-Tinland/a-bar`, GPL-3.0, public repo. Push only to `origin`; never touch upstream (rules in `CLAUDE.md`).

## Invariants
- **This Mac Studio cannot build or test.** Command Line Tools only, no Xcode. Every build/test runs on the Mac mini (`ssh mac-mini`, `~/Code/a-bar`, Xcode 27.0) at an exact pushed sha. Flow and command: `mem:suggested_commands`.
- Tests recompile a whitelist of production sources (no TEST_HOST, no `@testable import`). Membership rules and TCC hazards: `mem:conventions`.
- Public repo: private data (Linear mapping, hosts beyond the `mac-mini` alias) goes in untracked `CLAUDE.local.md`, never in tracked files or these memories if `.serena/` is committed.
- Settings persist to `~/.a-barrc` (JSON via `Models/SettingsCodec.swift`, written by `Models/SettingsStore.swift`; follows symlink chain, atomic replace of target, cycle left alone).

## Source map (`a-bar/`)
- `ABarApp.swift`, `AppDelegate.swift`, `BarWindow.swift`, `BarView.swift`: entry, window per display, widget dispatch by `WidgetIdentifier`.
- `Logic/`: pure, unit-tested functions (parsers, geometry, samplers, schedules). New testable logic goes here.
- `Models/`: `WidgetTypes.swift` (`WidgetIdentifier` enum = every widget id, category, section), `Settings.swift` (per-widget settings structs), `SettingsCodec.swift`, `SettingsStore.swift`, `Profile.swift`.
- `Services/`: `SystemInfoService` (IOKit/mach/CoreAudio metrics, tmutil), `YabaiService`, `AerospaceService`, `WifiService`, `BluetoothService`, `UserWidgetManager` + `XBarParser`/`XBarMenu` (XBar-compatible custom widgets).
- `Widgets/{Data,Graphs,Yabai,Aerospace,Custom}/`: SwiftUI views. `Views/Settings/`: settings UI (`WidgetSettingsViews.swift`, `LayoutBuilderView.swift` are the largest files).
- `Utilities/ShellExecutor.swift`: all shell-outs; PATH prefix `/usr/local/bin:/opt/homebrew/bin`, 10 s default timeout.
- `a-bar.sdef`: AppleScript dictionary (`Services/RefreshWidgetCommand.swift`).

## Adding a widget touches
`WidgetTypes.swift` (id, name, category), `Settings.swift` + `SettingsCodec.swift` (settings + decode defaults), `BarView.swift` (view dispatch), `Views/Settings/SettingsView.swift` + `WidgetSettingsViews.swift` (settings pane), `Logic/WidgetRefreshSchedule.swift` (refresh interval), plus a `Logic/` parser with tests. `TimeMachine*` is a complete recent example.

## More
- Stack, versions, signing, distribution: `mem:tech_stack`.
- Commands: `mem:suggested_commands`. Done criteria: `mem:task_completion`.
