#!/usr/bin/env bash
# Orchestrate the forge pipeline for a single PR:
#   volley (codex round 1 → opus round 2) → hunt-spec (codex) → blind-blind-merge
#   (opus + codex parallel) → apply → verify → hunt-code (gemini) → volley-clean
#
# Expects:
#   - cleanroom at /tmp/refactor-eq-workdir/cleanroom/$PR with REFACTOR_SPEC.md,
#     FORGE_INPUT_DIFF.patch, FORGE_ALLOWED_FILES.txt
#   - forge working dir at /tmp/refactor-eq-workdir/forge/$PR
#
# Caller decides sharpened-spec review (round 2 of volley) and volley-clean. This
# script handles the automatable codex/opus/gemini invocations and surfaces
# their outputs for the caller to decide on.
set -euo pipefail
: "${PR:?}"
CR=/tmp/refactor-eq-workdir/cleanroom/$PR
FORGE=/tmp/refactor-eq-workdir/forge/$PR
echo "Forge PR $PR — cleanroom $CR, forge $FORGE"
ls "$CR/REFACTOR_SPEC.md" "$CR/FORGE_INPUT_DIFF.patch" "$CR/FORGE_ALLOWED_FILES.txt"
ls -d "$FORGE"
echo "Ready."
