# superset-setup-repro

Security reproduction for **Superset project lifecycle scripts** (`.superset/config.json`).

Tested on Superset CLI + host-service **1.31.0 and 1.32.0** (macOS). The result matrix below
is identical on both versions.

## What this shows

When a reviewer creates a workspace from a pull request — the normal "review this PR"
workflow, in the app or from the CLI — Superset checks out the **PR head** as the worktree
and runs that head's setup script. The commands come from the PR, not from `main`. A
contributor who opens an ordinary-looking PR therefore runs shell commands on the reviewer's
machine, in the reviewer's session, with the reviewer's `gh`/`git` credentials, before any
code is read.

The reviewer's documented defenses are a **user override** placed at
`~/.superset/projects/<abs-repo-path>/config.json`:

- **skip** — `{ "setup": [], "teardown": [] }`, which the docs say "skips setup entirely".
- **guard** — `{ "setup": ["true"], "teardown": ["true"] }`, a non-empty no-op.

Three branches carry the same benign payload by three routes. Their reach differs:

| Branch | Buried file | No override | `skip` `[]` | `guard` `["true"]` |
|---|---|---|---|---|
| `attack/config-json` | `.superset/config.json` | **runs** | blocked | blocked |
| `attack/setup-sh` | `.superset/setup.sh` | **runs** | **runs** | blocked |
| `attack/config-local-json` | `.superset/config.local.json` | **runs** | **runs** | **runs** |

`config.local.json` beats every documented defense: the worktree's local overlay is applied
on top of the user override. `setup.sh` beats the empty `skip` config through the script
fallback. `config.json` runs only when the reviewer set no override — the default install.

Each payload is benign: it writes `pwned` to `PWNED.txt` in the worktree and to
`/tmp/superset-repro-attack`, and records the reachable `gh` username (no secrets).

## Reproduce

See [`docs/REPRODUCTION.md`](docs/REPRODUCTION.md). Under 5 minutes.

## Responsible use

This repo exists to report the behavior to the Superset team. All payloads are harmless
markers. Do not point these branches at a machine you do not own.
