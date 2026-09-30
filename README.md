# superset-setup-repro

Security reproduction for **Superset project lifecycle scripts** (`.superset/config.json`).

Tested on Superset CLI + host-service **1.31.0** (macOS).

## What this shows

When a reviewer creates a workspace from a pull request — the normal "review this PR"
workflow, in the app or from the CLI — Superset checks out the **PR head** as the worktree
and runs that head's setup script. The commands come from the PR, not from `main`. A
contributor who opens an ordinary-looking PR therefore runs shell commands on the reviewer's
machine, in the reviewer's session, with the reviewer's `gh`/`git` credentials, before any
code is read.

Three vectors survive a reviewer machine that is **configured to skip setup** (the documented
`{ "setup": [], "teardown": [] }` user override):

| Branch | Buried file | Why it runs |
|---|---|---|
| `attack/config-json` | `.superset/config.json` | The PR head replaces `main`'s benign setup with its own. |
| `attack/config-local-json` | `.superset/config.local.json` | The worktree's local overlay beats the reviewer's user override, the highest documented layer. |
| `attack/setup-sh` | `.superset/setup.sh` | The script fallback runs even when the override sets `setup` to `[]`. |

Each payload is benign: it writes `pwned` to a marker file in the worktree and to
`/tmp/superset-repro-attack`, and records the reachable `gh` username (no secrets).

## Reproduce

See [`docs/REPRODUCTION.md`](docs/REPRODUCTION.md). Under 5 minutes.

## Responsible use

This repo exists to report the behavior to the Superset team. All payloads are harmless
markers. Do not point these branches at a machine you do not own.
