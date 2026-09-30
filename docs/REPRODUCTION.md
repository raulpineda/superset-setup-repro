# Reproduction

Superset CLI + host-service **1.31.0**, macOS. The same steps map to the app: instead of the
`workspaces create` command, click **Create workspace from PR** and pick the PR.

## Threat model

- The reviewer registers this repo as a Superset project.
- `main` carries a benign `.superset/config.json`.
- The reviewer follows the documented advice to **not run untrusted setup**: they place a user
  override that skips setup (see `reviewer-override.example.json`).
- A contributor (no write access to `main`) opens a PR that looks unrelated — a doc fix, a small
  feature — and buries a `.superset/` change in it.
- The reviewer opens a workspace from that PR to read the diff. The buried command runs first.

## Set up the reviewer machine (the defense that should hold)

The docs say the user override at `~/.superset/projects/<abs-repo-path>/config.json` is the
highest-priority layer, and `{ "setup": [], "teardown": [] }` "skips setup entirely". Apply it:

```sh
REPO=$(git -C /path/to/superset-setup-repro rev-parse --show-toplevel)
mkdir -p "$HOME/.superset/projects$REPO"
cp reviewer-override.example.json "$HOME/.superset/projects$REPO/config.json"
```

## Run each vector

For branch `<b>` with its PR number `<N>`:

```sh
superset workspaces create --local --project <project-id> --name repro-<b> --pr <N> --json
sleep 10
cat /tmp/superset-repro-attack        # the PR's command ran, despite the override
superset workspaces delete <workspace-id> --local
rm -f /tmp/superset-repro-attack
```

## Expected vs actual

| Vector | Expected with override in place | Actual (1.31.0) |
|---|---|---|
| `attack/config-json` | setup skipped | PR's `config.json` runs |
| `attack/config-local-json` | setup skipped | PR's `config.local.json` runs, overriding the override |
| `attack/setup-sh` | setup skipped | PR's `setup.sh` runs |

## Where the code decides this

`Superset.app/Contents/Resources/app.asar` → `dist/main/host-service.js` (1.31.0):

- `loadSetupConfig` merges `projectConfig` (main checkout) < `worktreeConfig` (PR head) <
  `userConfig`, then lays the **worktree's** `config.local.json` on top of the result. The
  PR-controlled overlay wins.
- `resolveScript` falls through empty command arrays to `<worktree>/.superset/<key>.sh`, so a
  committed `setup.sh` runs even when every config sets `setup` to `[]`.
- The setup terminal starts with `worktreePath` (the PR checkout) as its working directory,
  runs as the host user, and inherits that user's `gh`/`git` credentials.
