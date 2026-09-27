# Task completion

1. `./scripts/check-test-membership.sh` locally (runs without Xcode).
2. Commit on a feature branch, push to `origin` (`SijanC147/a-bar`).
3. On the mini at that exact sha: membership check + `xcodebuild test` (command in `mem:suggested_commands`). Quote the result line; an interrupted run is no result.
4. Return the mini's checkout to clean `main`.
5. PR against fork `main`; wait for the automatic Codex security review (`+1` reaction = no findings) and the `Unit tests` check once CI has run on the fork.
6. User-visible change: add a line under the unreleased section of `CHANGELOG.md`.
No linter or formatter is configured in the repo.
