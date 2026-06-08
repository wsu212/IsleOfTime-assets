#!/usr/bin/env bash
#
# Generate 256x256 PNG thumbnails for every source PNG under each tracked
# directory. Outputs to <dir>/thumb/<name>.png. Idempotent: skips files whose
# source mtime is older than the existing thumbnail.
#
# Usage:
#   scripts/generate-thumbnails.sh           # incremental, all tracked dirs
#   scripts/generate-thumbnails.sh --force   # rebuild all
#
# Add new source dirs by appending to SOURCE_DIRS below.
#
# Requires: macOS `sips` (built-in).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
THUMB_SIZE=256
SOURCE_DIRS=(volumes figures_v2)

FORCE=0
if [[ "${1:-}" == "--force" ]]; then
    FORCE=1
fi

if ! command -v sips >/dev/null 2>&1; then
    echo "error: sips not found (this script requires macOS)" >&2
    exit 1
fi

shopt -s nullglob

total_generated=0
total_skipped=0

for rel_dir in "${SOURCE_DIRS[@]}"; do
    SRC_DIR="$REPO_ROOT/$rel_dir"
    OUT_DIR="$SRC_DIR/thumb"

    if [[ ! -d "$SRC_DIR" ]]; then
        echo "warning: source dir not found, skipping: $SRC_DIR" >&2
        continue
    fi

    mkdir -p "$OUT_DIR"

    sources=("$SRC_DIR"/*.png)
    if (( ${#sources[@]} == 0 )); then
        echo "warning: no PNG sources in $SRC_DIR, skipping" >&2
        continue
    fi

    generated=0
    skipped=0
    printf "[%s]\n" "$rel_dir"
    for src in "${sources[@]}"; do
        name="$(basename "$src")"
        out="$OUT_DIR/$name"

        if (( FORCE == 0 )) && [[ -f "$out" && "$out" -nt "$src" ]]; then
            skipped=$((skipped + 1))
            continue
        fi

        # sips resamples to fit within THUMB_SIZE x THUMB_SIZE while
        # preserving aspect. Source covers are already square (1024x1024),
        # so output is exactly 256x256.
        sips -Z "$THUMB_SIZE" "$src" --out "$out" >/dev/null
        generated=$((generated + 1))
        printf "  thumb  %s\n" "$name"
    done

    printf "  → generated: %d, skipped (up-to-date): %d → %s\n\n" \
        "$generated" "$skipped" "$OUT_DIR"

    total_generated=$((total_generated + generated))
    total_skipped=$((total_skipped + skipped))
done

printf "done — total generated: %d, total skipped: %d\n" \
    "$total_generated" "$total_skipped"
