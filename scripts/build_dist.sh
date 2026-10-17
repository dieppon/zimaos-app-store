#!/usr/bin/env bash
# Build the v2 store output (dist/) locally using IceWhale's official builder.
#
# Usage:
#   ./scripts/build_dist.sh [base-url]
#
#   base-url  Public HTTPS URL where dist/ will eventually be hosted
#             (e.g. https://cdn.jsdelivr.net/gh/you/zimaos-app-store@gh-pages).
#             Defaults to a placeholder; asset links inside dist/ will use it,
#             so set the real URL before publishing.
#
# Requirements:
#   - python3 (3.11+ recommended; 3.9 may work)
#   - network access (fetches the official build script on first run,
#     pip dependencies, and Docker Hub image metadata)
#   - rsvg-convert (only needed if your apps use SVG icons:
#     macOS: brew install librsvg / Debian-Ubuntu: apt install librsvg2-bin)
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$ROOT/.cache/build-tools"
OUT="$ROOT/dist"
BASE_URL="${1:-${BASE_URL:-https://example.com/dieppon-app-store}}"

ACTION_REPO_RAW="https://raw.githubusercontent.com/IceWhaleTech/build-appstore-action/main"

echo "==> Preparing build tools in $TOOLS"
mkdir -p "$TOOLS/scripts"

if [[ ! -f "$TOOLS/scripts/build_appstore.py" ]]; then
  curl -fsSL "$ACTION_REPO_RAW/scripts/build_appstore.py" -o "$TOOLS/scripts/build_appstore.py"
fi
if [[ ! -f "$TOOLS/requirements.txt" ]]; then
  curl -fsSL "$ACTION_REPO_RAW/requirements.txt" -o "$TOOLS/requirements.txt"
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 not found" >&2
  exit 1
fi

VENV="$TOOLS/venv"
VPY="$VENV/bin/python"
if [[ ! -x "$VPY" ]]; then
  rm -rf "$VENV"
  python3 -m venv "$VENV"
fi
"$VPY" -m pip install --quiet --upgrade pip
"$VPY" -m pip install --quiet -r "$TOOLS/requirements.txt"

if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "warning: rsvg-convert not found — SVG icons cannot be converted."
  echo "         Install it with: brew install librsvg (macOS) or"
  echo "         apt install librsvg2-bin (Debian/Ubuntu). PNG icons are fine."
fi

echo "==> Building store into $OUT (base-url: $BASE_URL)"
"$VPY" -u "$TOOLS/scripts/build_appstore.py" \
  --source "$ROOT" \
  --output "$OUT" \
  --base-url "$BASE_URL" \
  --cache-file "$ROOT/.cache/build_appstore/image-size-cache.json" \
  --digest-cache-file "$ROOT/.cache/build_appstore/image-digest-cache.json" \
  --report-json "$OUT/build-report.json" \
  --report-title "dieppon's App Store Build"

echo
echo "==> Done. Store output is in: $OUT"
echo "    - $OUT/index.json        (app listing)"
echo "    - $OUT/store.json        (store identity)"
echo "    - $OUT/apps/<app-id>/    (per-app compose, meta.json, assets)"
