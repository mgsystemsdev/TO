#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DB_URL="${DATABASE_URL:-postgresql://miguelgonzalez@localhost:5432/dmrb}"

if [[ "$DB_URL" == "postgresql://miguelgonzalez@localhost:5432/dmrb" ]] && ! psql "$DB_URL" -c 'SELECT 1' >/dev/null 2>&1; then
  LEGACY_ENV="$ROOT/../dmrb-legacy/.env"
  if [[ -f "$LEGACY_ENV" ]]; then
    DB_URL="$(grep -E '^DATABASE_URL=' "$LEGACY_ENV" | head -1 | cut -d= -f2- | tr -d '"')"
  fi
fi

if [[ -z "$DB_URL" ]]; then
  echo "Set DATABASE_URL or create a local Postgres database named dmrb."
  exit 1
fi

install_app() {
  local dir="$1"
  echo "→ npm install in $dir"
  (cd "$ROOT/$dir" && npm install)
}

write_env() {
  local file="$1"
  shift
  if [[ -f "$file" ]]; then
    echo "  skip $file (already exists)"
    return
  fi
  printf '%s\n' "$@" > "$file"
  echo "  wrote $file"
}

echo "Installing dependencies..."
install_app "Workflow Dmrb"
install_app "total ui"
install_app "uploads"

echo "Writing .env files..."
write_env "$ROOT/Workflow Dmrb/.env" \
  "DATABASE_URL=$DB_URL" \
  "PORT=3000"

write_env "$ROOT/total ui/.env" \
  "DATABASE_URL=$DB_URL" \
  "PORT=3002"

write_env "$ROOT/uploads/.env" \
  "DATABASE_URL=$DB_URL" \
  "PORT=3001"

echo
echo "Done. Start each app in its own terminal:"
echo "  cd \"$ROOT/Workflow Dmrb\" && npm start   # http://localhost:3000"
echo "  cd \"$ROOT/uploads\" && npm start         # http://localhost:3001"
echo "  cd \"$ROOT/total ui\" && npm start        # http://localhost:3002"
