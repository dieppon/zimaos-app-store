#!/usr/bin/env bash
# Scaffold a new app package in Apps/<app-folder>/docker-compose.yml
# from templates/docker-compose.yml.
#
# Usage:
#   ./scripts/new_app.sh <app-folder> <title> [category] [port]
#
# Examples:
#   ./scripts/new_app.sh vaultwarden "Vaultwarden" Productivity "8080"
#   ./scripts/new_app.sh navidrome Navidrome Media "4533"
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

APP_FOLDER="${1:-}"
TITLE="${2:-}"
CATEGORY="${3:-Others}"
PORT="${4:-8080}"

VALID_CATEGORIES="Media Productivity Home Networking AI Finance Social Developer Others"

if [[ -z "$APP_FOLDER" || -z "$TITLE" ]]; then
  echo "Usage: $0 <app-folder> <title> [category] [port]" >&2
  echo "Categories: $VALID_CATEGORIES" >&2
  exit 1
fi

if ! echo "$VALID_CATEGORIES" | grep -qw "$CATEGORY"; then
  echo "error: invalid category '$CATEGORY'. Valid: $VALID_CATEGORIES" >&2
  exit 1
fi

if [[ ! "$APP_FOLDER" =~ ^[a-z0-9][a-z0-9._-]*$ ]]; then
  echo "error: app folder must be lowercase (letters, digits, . _ -)" >&2
  exit 1
fi

DEST="$ROOT/Apps/$APP_FOLDER"
if [[ -e "$DEST" ]]; then
  echo "error: $DEST already exists" >&2
  exit 1
fi

mkdir -p "$DEST"
sed -e "s|APP_FOLDER|$APP_FOLDER|g" \
    -e "s|App Title|$TITLE|g" \
    -e "s|^  category: Others|  category: $CATEGORY|" \
    -e "s|\"8080\"|\"$PORT\"|g" \
    "$ROOT/templates/docker-compose.yml" > "$DEST/docker-compose.yml"

echo "Created $DEST/docker-compose.yml"
echo "Next steps:"
echo "  1. Edit the image tag, description, icon, and links."
echo "  2. Validate: bash scripts/build_dist.sh"
