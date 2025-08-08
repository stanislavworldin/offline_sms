#!/usr/bin/env bash
set -Eeuo pipefail

# DEBUG helpers
log() { echo "[deploy_pages] $*"; }
die() { echo "[deploy_pages][ERROR] $*" >&2; exit 1; }

# Config
# Derive GitHub user/repo from origin to avoid hardcoding
ORIGIN_URL="$(git remote get-url origin)"
# Extract user
GH_USER="$(echo "$ORIGIN_URL" | sed -E 's#.*github.com[:/ ]([^/]+)/.*#\1#')"
# Extract repo name robustly and strip optional .git suffix
GH_REPO_RAW="${ORIGIN_URL##*/}"
GH_REPO="${GH_REPO_RAW%.git}"

BASE_HREF=${BASE_HREF:-"/${GH_REPO}/"}
# Choose web renderer (html|canvaskit). HTML is safer on GH Pages.
WEB_RENDERER=${WEB_RENDERER:-"html"}
BUILD_DIR="example/build/web"

# Ensure we are at repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

current_branch="$(git rev-parse --abbrev-ref HEAD)"
log "Current branch: $current_branch"

# Ensure clean working tree unless FORCE=1
if [[ "${FORCE:-0}" != "1" ]]; then
  if [[ -n "$(git status --porcelain)" ]]; then
    die "Working tree not clean. Commit or stash changes, or run with FORCE=1"
  fi
fi

log "Building web app with base-href: $BASE_HREF"
pushd example >/dev/null
  flutter clean
  rm -rf build .dart_tool
  flutter pub get
  flutter build web --release --base-href "$BASE_HREF"
popd >/dev/null

# Stash build into a temporary directory because switching branch will change files
TMP_DIR="$(mktemp -d)"
log "Copying build to temp: $TMP_DIR"
cp -R "$BUILD_DIR"/. "$TMP_DIR"/

log "Switching to gh-pages"
if git show-ref --verify --quiet refs/heads/gh-pages; then
  git checkout gh-pages
else
  git checkout -b gh-pages || die "Failed to create gh-pages"
fi
git pull --ff-only || true

log "Clearing gh-pages tracked files"
git ls-files -z | xargs -0 git rm -f -q || true

log "Copying fresh build to gh-pages root"
cp -R "$TMP_DIR"/. .

# Disable Jekyll to avoid asset processing on GH Pages
touch .nojekyll

# SPA fallback for deep links
if [[ -f index.html ]]; then
  cp index.html 404.html
fi

log "Committing and pushing to origin/gh-pages"
git add -A
git commit -m "deploy(pages): fresh build" || log "Nothing to commit"
git push origin gh-pages

log "Returning to $current_branch"
git checkout "$current_branch"

log "Cleanup temp: $TMP_DIR"
rm -rf "$TMP_DIR"

log "Done. Visit: https://${GH_USER}.github.io/${GH_REPO}/"


