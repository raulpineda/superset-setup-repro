# Reproduction

Superset CLI + host-service **1.31.0**, macOS. The same steps map to the app: instead of the
`workspaces create` command, click **Create workspace from PR** and pick the PR.

## Threat model

- The reviewer registers this repo as a Superset project.
- `main` carries a benign `.superset/config.json`.
- The reviewer may follow the documented advice to not run untrusted setup, by placing a user
  override (see below).
- A contributor (no write access to `main`) opens a PR that looks unrelated — a doc fix, a small
  chore — and buries a `.superset/` change in it.
- The reviewer opens a workspace from that PR to read the diff. The buried command runs first.

## Set up the reviewer machine

The user override at `~/.superset/projects/<abs-repo-path>/config.json` is the highest-priority
layer per the docs. Two variants:

```sh
REPO=$(git -C /path/to/superset-setup-repro rev-parse --show-toplevel)
mkdir -p "$HOME/.superset/projects$REPO"
# skip: docs say this "skips setup entirely"
printf '{"setup":[],"teardown":[]}\n'          > "$HOME/.superset/projects$REPO/config.json"
# or guard: a non-empty no-op
printf '{"setup":["true"],"teardown":["true"]}\n' > "$HOME/.superset/projects$REPO/config.json"
```

## Run each vector

```sh
superset workspaces create --local --project <project-id> --name repro --pr <N> --json
sleep 10
cat /tmp/superset-repro-attack        # if present, the PR's command ran
superset workspaces delete <workspace-id> --local
rm -f /tmp/superset-repro-attack
```

## Observed results (1.31.0)

| PR vector | No override | `skip` `[]` | `guard` `["true"]` |
|---|---|---|---|
| `attack/config-json` (`config.json`) | runs | skipped | skipped |
| `attack/setup-sh` (`setup.sh`) | runs | runs | skipped |
| `attack/config-local-json` (`config.local.json`) | runs | runs | runs |

`config.local.json` is the strongest vector: no documented reviewer config stops it.

## Credential reach

The setup terminal runs as the host user, in the worktree, and inherits that user's
credentials. A separate probe (recorded only non-secret facts) showed `gh api user --jq .login`
exit 0 with a real username, `gh auth status` exit 0, and `git ls-remote` exit 0. The setup
environment exposes `SUPERSET_*` variables (`SUPERSET_ROOT_PATH`, `SUPERSET_WORKSPACE_PATH`,
`SUPERSET_ORGANIZATION_ID`, and others). No secret was printed.

## Where the code decides this

`Superset.app/Contents/Resources/app.asar` → `dist/main/host-service.js` (1.31.0):

- `loadSetupConfig` merges `projectConfig` (main checkout) < `worktreeConfig` (PR head) <
  `userConfig` (the reviewer's override), then lays the **worktree's** `config.local.json` on
  top of the merged result via `applyLocalOverlay`. The PR-controlled overlay wins over the
  override. This is the `config.local.json` vector.
- `resolveScript` runs `nonEmptyStrings(config[key])`; when that is empty it falls through to
  `<worktree>/.superset/<key>.sh`, then `<repo>/.superset/<key>.sh`. An empty override lets the
  PR's `setup.sh` run. This is the `setup.sh` vector.
- `startSetupTerminalIfPresent` starts the setup terminal with `worktreePath` (the PR checkout)
  as the working directory, as the host user, inheriting `gh`/`git` credentials.
- "Verified PR head" (`assertRefMatchesExpectedOid`) means only that the fetched commit matches
  GitHub's `headRefOid`. It does not gate what the head may execute.
