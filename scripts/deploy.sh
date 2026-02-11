#!/bin/bash
# Deploy mahjong web + server to production.
# Usage: ./scripts/deploy.sh [web|server|all]
#   web    — build Flutter web, push to rehydratedwater.com repo (webhook syncs to server)
#   server — upload server code via SSH, recompile, restart
#   all    — both (default)

set -e

REMOTE="digitalocean"
SERVER_DIR="/var/www/mahjong-server"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_REPO_DIR="/tmp/rehydratedwater-deploy"

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

  echo "==> Pushing web build to rehydratedwater.com repo..."

  # Clone or update the target repo
  if [ -d "$TARGET_REPO_DIR/.git" ]; then
    cd "$TARGET_REPO_DIR"
    git pull origin main
  else
    rm -rf "$TARGET_REPO_DIR"
    git clone git@github.com:qizheYang/rehydratedwater.com.git "$TARGET_REPO_DIR"
    cd "$TARGET_REPO_DIR"
  fi

  # Replace mahjong directory
  rm -rf mahjong
  cp -r "$PROJECT_DIR/build/web" mahjong

  # Commit and push
  git add mahjong
  git commit -m "Manual deploy mahjong $(date -u '+%Y-%m-%d %H:%M UTC')" || echo "No changes to commit"
  git push origin main

  echo "==> Web deployed (webhook will sync to server)."
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
