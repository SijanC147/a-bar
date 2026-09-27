# Tech stack

- Swift 5 (`SWIFT_VERSION = 5.0`), SwiftUI + AppKit, macOS deployment target 13.0. No SwiftPM/CocoaPods dependencies; system frameworks only (IOKit, CoreAudio, CoreWLAN/CoreLocation, IOBluetooth).
- Build: Xcode 27.0 on the Mac mini only (`mem:core`). DerivedData on the mini: `/Volumes/Rugged/Xcode/DerivedData`.
- Bundle id `com.jeantinland.a-bar` (inherited from upstream). Ad-hoc signed (`codesign --sign -`), not notarized. Entitlements `a-bar/a-bar.entitlements`. Sparkle removed upstream; stays removed.
- Version sources disagree: `MARKETING_VERSION = 1.6.0` / `CURRENT_PROJECT_VERSION = 1` in the app target, but `a-bar/Info.plist` hardcodes `CFBundleShortVersionString 1.0.0`, `CFBundleVersion 1`. Test target has `MARKETING_VERSION = 1.0`. `CHANGELOG.md` tops at v1.6.0.
- `scripts/release.sh <version> <build>`: archive Release with version overrides, ad-hoc sign with entitlements, `ditto` zip, sha256. Its trailing "appcast.xml" steps are Sparkle-era and stale.
- CI: `.github/workflows/tests.yml`, `macos-15`, job `Unit tests` (membership check + `xcodebuild test` with coverage, `CODE_SIGNING_ALLOWED=NO`); on push also `Publish badges` (force-pushes orphan `badges` branch via `scripts/generate-badges.sh`). Triggers: push to main, `v*` tags, pull_request; no `workflow_dispatch`.
- Build side effect: scheme post-action + `CopyAppToCheckout` target run `scripts/copy-app-to-checkout.sh --apply`, copying the built app to `<checkout>/a-bar.app` (gitignored). No-op when `CI` or `GITHUB_ACTIONS` is set.
- Distribution target: Sean's Homebrew tap via Hextap (hextap-toolkit >= 0.8.0, manifest schema 3, `runtime: "xcode"`, Cask). Commands are authoritative from `hextap --help` and the `hextap` skill.
