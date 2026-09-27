# a-bar: project instructions

a-bar is a native macOS menu-bar replacement written in Swift and SwiftUI, built with Xcode.
This checkout is Sean's fork, `SijanC147/a-bar`, of `Jean-Tinland/a-bar`. Its license is GPL-3.0.

@AGENTS.md

## Fork rules

- Push only to `origin`, which is `SijanC147/a-bar`. Fork `main` is our line of development:
  feature branches merge into it, and it is expected to diverge from upstream.
- Never push, open a pull request, tag, or comment on `Jean-Tinland/a-bar`. Never add an
  `upstream` remote. Sean ruled this on 2026-09-27: "we're going to be pushing to OUR fork main
  now, with our work, NEVER to the upstream".
- A pull request on the fork gets a Codex security review automatically. It reacts with `+1`
  when it has no findings.

## Where it builds

`xcodebuild` needs full Xcode. **This Mac Studio has only the Command Line Tools**, so nothing
here can build or test the app. Builds and tests run on the Mac mini:

| Machine | Reach it with | a-bar checkout | Xcode |
|---|---|---|---|
| Mac Studio (this one) | local | `/Users/seanbugeja/Code/a-bar` | none |
| Mac mini | `ssh mac-mini` | `~/Code/a-bar` | 27.0 (27A266a), DerivedData on `/Volumes/Rugged/Xcode/DerivedData` |

Both checkouts were on `main` at `8e97575` on 2026-09-27. Edit and commit here, push the
branch, then build and test that exact commit on the mini:

```sh
ssh mac-mini 'cd ~/Code/a-bar && git fetch -q origin && git switch -q --detach <sha> && \
  ./scripts/check-test-membership.sh && \
  xcodebuild test -project a-bar.xcodeproj -scheme a-bar -destination "platform=macOS"'
```

Leave the mini's checkout clean and back on `main` afterwards. The mini's `origin` URL uses a
lowercase owner (`https://github.com/sijanc147/a-bar`); GitHub treats owners case-insensitively.

A local scheme build copies the app to `<checkout>/a-bar.app` through the `CopyAppToCheckout`
target and a scheme post-action (`scripts/copy-app-to-checkout.sh --apply`). That path is
gitignored. The script does nothing when `CI` or `GITHUB_ACTIONS` is set.

## Tests and CI

- Test command and the test-membership rule are in `AGENTS.md`. The test bundle recompiles
  a whitelist of production sources, so a test compiling does not prove the file is a member:
  run `./scripts/check-test-membership.sh`.
- `.github/workflows/tests.yml` runs on `macos-15`. Its jobs are `Unit tests` and, on push only,
  `Publish badges`. The required check context is `Unit tests` (first fork run 2026-09-27, after
  enabling workflows on the fork's Actions tab; GitHub disables inherited workflows on a fork).

## Versioning

`MARKETING_VERSION` (app target, 1.7.0 since the first fork release) is the one version source.
`a-bar/Info.plist` reads `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)`. With
`GENERATE_INFOPLIST_FILE = YES` the build settings won even over the old literal `1.0.0`
(measured on the mini, SB23-3098), so a Hextap release tag becomes the app version. Keep
`CHANGELOG.md` in step. Sparkle was removed upstream and stays removed. The app is not
notarized and is ad-hoc signed.

## Distribution (Hextap)

a-bar is to be published through Sean's Homebrew tap as a Cask. Toolkit support shipped in
hextap-toolkit v0.8.0 (manifest schema 3, `runtime: "xcode"`). a-bar is not onboarded yet.
The step-by-step path is in the Hextap onboarding handoff linked from `KICKOFF.md`; the
`hextap` skill and `hextap --help` are authoritative for commands.

## Tracking

Linear is the system of record for a-bar work. The project mapping lives in the untracked
`CLAUDE.local.md`, because this repository is public.
