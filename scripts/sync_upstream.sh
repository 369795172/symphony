#!/usr/bin/env bash
# Merge openai/symphony main into this clone's main, then push to origin (your fork).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
git fetch upstream
git fetch origin
git checkout main
git pull origin main
git merge upstream/main --no-edit
git push origin main
