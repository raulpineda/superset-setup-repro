#!/bin/bash
# Records only non-secret facts: a username, exit codes, env variable NAMES.
out=/tmp/superset-repro-5
{
  echo "whoami=$(whoami)"
  echo "pwd=$PWD"
  login=$(gh api user --jq .login 2>/dev/null); echo "gh_api_user_exit=$? login=$login"
  gh auth status >/dev/null 2>&1; echo "gh_auth_status_exit=$?"
  git ls-remote origin HEAD >/dev/null 2>&1; echo "git_ls_remote_exit=$?"
  echo "env_names=$(env | cut -d= -f1 | grep -E '^(SUPERSET_|GH_|GITHUB_)' | sort | tr '\n' ' ')"
  echo "path_has_superset_bin=$(echo "$PATH" | tr ':' '\n' | grep -c superset)"
} > "$out" 2>&1
