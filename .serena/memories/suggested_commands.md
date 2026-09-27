# Suggested commands

## Build and test (Mac mini only; see `mem:core`)
Edit + commit on the Mac Studio, push the branch, then test that exact sha on the mini:
```sh
ssh mac-mini 'cd ~/Code/a-bar && git fetch -q origin && git switch -q --detach <sha> && \
  ./scripts/check-test-membership.sh && \
  xcodebuild test -project a-bar.xcodeproj -scheme a-bar -destination "platform=macOS"'
```
Afterwards leave the mini clean and back on `main` (`git switch -q main`). The mini's origin URL uses lowercase `sijanc147`; same repo.
A green build ends `** TEST SUCCEEDED **` / `BUILD SUCCEEDED` (~24 s build). Pipe through nothing when reading the exit status.

## Local (Mac Studio, no Xcode)
- `./scripts/check-test-membership.sh`: pure bash/awk over `project.pbxproj`, runs here.
- `./scripts/generate-badges.sh <xcresult> <outdir>`: needs `xcrun xccov`, mini/CI only.
- `gh run list --repo SijanC147/a-bar --limit 3`: CI status.

## Darwin/zsh gotchas
- zsh expands unquoted globs: `grep --include='*.swift'`, not `--include=*.swift` (fails "no matches found").
- Delete with `trash`, never `rm` (denied by settings).
- `sed -i ''` (BSD) for in-place edits.
