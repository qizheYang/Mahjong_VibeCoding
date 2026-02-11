#!/bin/bash
# Deploy mahjong web + server to production.
# Usage: ./scripts/deploy.sh [web|server|all]
#   web    — build and deploy Flutter web only
#   server — deploy server code, recompile, restart
#   all    — both (default)

set -e

REMOTE="digitalocean"
WEB_DIR="/var/www/rehydratedwater.com/mahjong"
SERVER_DIR="/var/www/mahjong-server"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

deploy_web() {
  echo "==> Building Flutter web (production URL)..."

  # Temporarily switch to production URL
  sed -i.bak "s|ws://localhost:8080|wss://rehydratedwater.com/mahjong-ws|" \
    "$PROJECT_DIR/lib/ui/screens/title_screen.dart"

  BUILD_VERSION=$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "local")
  BUILD_TIME=$(date -u '+%Y-%m-%d %H:%M UTC')

  cd "$PROJECT_DIR"
  flutter build web --base-href "/mahjong/" --release \
    --dart-define=BUILD_VERSION="$BUILD_VERSION" \
    --dart-define=BUILD_TIME="$BUILD_TIME"

  # Restore localhost URL
  mv "$PROJECT_DIR/lib/ui/screens/title_screen.dart.bak" \
     "$PROJECT_DIR/lib/ui/screens/title_screen.dart"

  echo "==> Uploading web build..."
  rsync -az --delete "$PROJECT_DIR/build/web/" "$REMOTE:$WEB_DIR/"

  echo "==> Web deployed."
}

deploy_server() {
  echo "==> Uploading server source..."
  scp "$PROJECT_DIR/server/pubspec.yaml" "$REMOTE:$SERVER_DIR/pubspec.yaml"
  scp "$PROJECT_DIR/server/bin/server.dart" "$REMOTE:$SERVER_DIR/bin/server.dart"
  scp "$PROJECT_DIR"/server/lib/*.dart "$REMOTE:$SERVER_DIR/lib/"

  echo "==> Recompiling and restarting server..."
  ssh "$REMOTE" "cd $SERVER_DIR && dart pub get && dart compile exe bin/server.dart -o bin/mahjong_server_new && mv bin/mahjong_server_new bin/mahjong_server && systemctl restart mahjong-server"

  echo "==> Server deployed."
  ssh "$REMOTE" "systemctl status mahjong-server --no-pager | head -10"
}

MODE="${1:-all}"

case "$MODE" in
  web)    deploy_web ;;
  server) deploy_server ;;
  all)    deploy_web; deploy_server ;;
  *)      echo "Usage: $0 [web|server|all]"; exit 1 ;;
esac

echo "==> Done!"
