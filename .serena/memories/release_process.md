# Release process (fork, via Hextap)

Proven end to end on 2026-09-27 for v1.7.1 to v1.7.5 (release runs 36322494426, 36329008607, 36330246549, 36337413151, 36345737957; all 7 jobs green). Distribution design is in `CLAUDE.md` › Distribution.

## Steps
1. Change lands on `main` through a PR: the ruleset `hextap/main` needs the `Unit tests` check green and the branch up to date. Also wait for the Codex review: a PR reaction of `EYES` means it is still running, `THUMBS_UP` means no findings. Merge with `gh pr merge <n> --repo SijanC147/a-bar --merge`.
2. Version bump in a PR, or folded into the feature PR to save a CI round: `MARKETING_VERSION` in `a-bar.xcodeproj/project.pbxproj` (2 occurrences, app target only; the test target stays `1.0`). Move the `CHANGELOG.md` Unreleased entries under `## vX.Y.Z - <date>` and leave `_No changes yet._`.
3. `git tag -a vX.Y.Z -m "a-bar vX.Y.Z" <merged main sha> && git push origin vX.Y.Z`. First check that local `main` equals `git ls-remote origin refs/heads/main`.
4. The tag starts `Hextap release` (`.github/workflows/hextap-release.yml`): validate, source quality, build (hosted `macos-15`, about 3 min), native verify per arch, publish an immutable GitHub release, then `Publish Homebrew Formula`, which commits `Update a-bar to X.Y.Z` to the tap's `Casks/a-bar.rb` (version plus `sha256 arm:/intel:`). Check the tap values against the release's `SHA256SUMS`.
5. On the Mac Studio: `brew update && brew upgrade --cask sean/hextap/a-bar`. `sean/hextap` is this Mac's local name for the private tap `SijanC147/homebrew-hextap`; elsewhere it is `brew tap sijanc147/hextap` after `gh auth login`. Upgrading keeps `~/.a-barrc` and the Cask clears quarantine. Verify with `PlistBuddy -c 'Print :CFBundleShortVersionString' /Applications/a-bar.app/Contents/Info.plist` and `codesign --verify --deep --strict`.
6. `ssh mac-mini 'cd ~/Code/a-bar && git fetch -q origin && git merge -q --ff-only origin/main'`.

## Gotchas
- A failed tag is never moved (ruleset `hextap/release-tags`, immutable releases). Fix forward with the next patch tag. v1.7.0 is tagged and unpublished for this reason.
- The repo secret `OP_SERVICE_ACCOUNT_TOKEN` must be a live service account that can read `op://CICD/GH_PAT/credential`. The working 1Password reference, and the two that fail (Agents-vault-only; deleted account, `403 Service Account Deleted`), are in the untracked `CLAUDE.local.md` because this repo is public. Set it with `op read -n <ref> | gh secret set OP_SERVICE_ACCOUNT_TOKEN --repo SijanC147/a-bar`; never print it. Probe a token with `OP_SERVICE_ACCOUNT_TOKEN="$T" op read -n op://CICD/GH_PAT/credential >/dev/null`.
- `scripts/generate-badges.sh` runs `git describe --tags`. Push runs on `main` fail in `Generate badges` when no `v*` tag is reachable, even though the tests pass.
- Re-render the Hextap-owned files with `hextap onboard` (dry run first), never by hand. `hextap validate` compares `.hextap/SETUP.md` byte for byte, pin included.
