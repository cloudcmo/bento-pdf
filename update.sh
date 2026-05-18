#!/usr/bin/env bash
#
# update.sh — fetch the latest BentoPDF Simple Mode release,
# replace local files, commit, and push (triggers Netlify deploy).
#
# Usage:
#   ./update.sh              # uses latest release
#   ./update.sh v2.8.4       # pins to a specific version
#
set -euo pipefail

REPO="alam00000/bentopdf"

# --- sanity checks ----------------------------------------------------------
if [[ ! -d .git ]]; then
  echo "❌ Not inside a git repo. cd into your bentopdf-self-hosted folder first."
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "❌ Working tree has uncommitted changes. Commit or stash first."
  git status --short
  exit 1
fi

# --- resolve version --------------------------------------------------------
if [[ "${1:-}" != "" ]]; then
  VERSION="${1#v}"  # strip leading 'v' if present
  echo "→ Using pinned version: v${VERSION}"
else
  echo "→ Looking up latest BentoPDF release…"
  VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep -m1 '"tag_name"' \
    | sed -E 's/.*"v?([^"]+)".*/\1/')
  echo "→ Latest is v${VERSION}"
fi

# --- already up to date? ----------------------------------------------------
CURRENT=""
if [[ -f .bentopdf-version ]]; then
  CURRENT=$(cat .bentopdf-version)
fi

if [[ "$CURRENT" == "$VERSION" ]]; then
  echo "✓ Already on v${VERSION}. Nothing to do."
  exit 0
fi

echo "→ Updating from ${CURRENT:-(unknown)} to v${VERSION}"

# --- download ---------------------------------------------------------------
ZIP_URL="https://github.com/${REPO}/releases/download/v${VERSION}/dist-simple-${VERSION}.zip"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "→ Downloading ${ZIP_URL}"
curl -fL -o "${TMPDIR}/dist.zip" "$ZIP_URL"

echo "→ Unzipping"
unzip -q "${TMPDIR}/dist.zip" -d "${TMPDIR}/unpacked"

# Find the actual content root — the zip sometimes contains a single
# top-level folder, sometimes not.
if [[ -f "${TMPDIR}/unpacked/index.html" ]]; then
  SRC="${TMPDIR}/unpacked"
else
  SRC=$(find "${TMPDIR}/unpacked" -maxdepth 2 -name index.html -type f -print -quit | xargs dirname)
fi

if [[ -z "$SRC" || ! -f "$SRC/index.html" ]]; then
  echo "❌ Couldn't find index.html in the downloaded archive. Bailing."
  exit 1
fi

# --- swap files -------------------------------------------------------------
echo "→ Removing old files (preserving .git, .gitignore, update.sh, .bentopdf-version)"
find . -mindepth 1 -maxdepth 1 \
  ! -name '.git' \
  ! -name '.gitignore' \
  ! -name 'update.sh' \
  ! -name '.bentopdf-version' \
  ! -name 'README.md' \
  -exec rm -rf {} +

echo "→ Copying new files"
# -a preserves attrs; trailing /. copies hidden files too if any
cp -a "${SRC}/." .

# Record the version we just installed
echo "$VERSION" > .bentopdf-version

# --- commit + push ----------------------------------------------------------
echo "→ Committing"
git add -A
git commit -m "Update BentoPDF to v${VERSION}"

echo "→ Pushing — Netlify will auto-deploy"
git push

echo ""
echo "✅ Done. BentoPDF updated to v${VERSION}."
echo "   Check the deploy at https://app.netlify.com"