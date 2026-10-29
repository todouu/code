#!/bin/sh
# Install or update Code into ~/.local (no root needed).
#   curl -fsSL https://raw.githubusercontent.com/todouu/code/master/custom/install.sh | sh
#   sh install.sh --uninstall
# Env: CODE_REPO (default todouu/code), CODE_PREFIX (default ~/.local),
#      CODE_NO_SANDBOX=1 (launch with --no-sandbox, see README.md)
set -eu

REPO="${CODE_REPO:-todouu/code}"
PREFIX="${CODE_PREFIX:-$HOME/.local}"
APP="$PREFIX/code.app"
BIN="$PREFIX/bin"
DESKTOP="${XDG_DATA_HOME:-$HOME/.local/share}/applications/code.desktop"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/512x512/apps"

if [ "${1:-}" = "--uninstall" ]; then
  rm -rf "$APP" "$BIN/code" "$BIN/code-update" "$DESKTOP" "$ICON_DIR/code.png"
  echo "Removed. User data stays in ~/.config/Code and ~/.local/share/Code."
  exit 0
fi

[ "$(uname -m)" = "x86_64" ] || { echo "Only x86_64 is built." >&2; exit 1; }

echo "Looking for the latest release of $REPO ..."
URL="$(curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=10" \
  | grep -o '"browser_download_url": *"[^"]*linux-x64-[^"]*\.tar\.gz"' \
  | head -n1 | sed 's/.*"\(https[^"]*\)"/\1/')"
[ -n "$URL" ] || { echo "No tar.gz release found in $REPO." >&2; exit 1; }
VERSION="$(basename "$URL" .tar.gz | sed 's/.*linux-x64-//')"

if [ -f "$APP/.version" ] && [ "$(cat "$APP/.version")" = "$VERSION" ]; then
  echo "Already up to date ($VERSION)."
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "Downloading $VERSION ..."
curl -fL --progress-bar "$URL" -o "$TMP/code.tar.gz"
curl -fsSL "$URL.sha256" -o "$TMP/code.sha256"
EXPECT="$(awk '{print $1; exit}' "$TMP/code.sha256")"
ACTUAL="$(sha256sum "$TMP/code.tar.gz" | awk '{print $1}')"
[ "$EXPECT" = "$ACTUAL" ] || { echo "Checksum mismatch." >&2; exit 1; }

mkdir -p "$PREFIX" "$BIN" "$(dirname "$DESKTOP")" "$ICON_DIR" "$TMP/new"
tar -xzf "$TMP/code.tar.gz" -C "$TMP/new"
echo "$VERSION" > "$TMP/new/.version"

# swap: a running instance keeps its already-open files
rm -rf "$APP.old"
[ -d "$APP" ] && mv "$APP" "$APP.old"
mv "$TMP/new" "$APP"
rm -rf "$APP.old"

# Electron needs either a root-owned SUID chrome-sandbox or unprivileged user namespaces.
NOSANDBOX=""
if [ "${CODE_NO_SANDBOX:-}" = "1" ] || { [ -f "$BIN/code" ] && grep -q -- '--no-sandbox' "$BIN/code" 2>/dev/null; }; then
  NOSANDBOX="--no-sandbox"
fi
if [ -z "$NOSANDBOX" ]; then
  if [ "$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || echo 0)" = "1" ] \
     || [ "$(cat /proc/sys/kernel/unprivileged_userns_clone 2>/dev/null || echo 1)" = "0" ]; then
    echo "WARNING: this system restricts unprivileged user namespaces, Code may fail to start."
    echo "         Re-run with CODE_NO_SANDBOX=1 to launch with --no-sandbox (less secure), see README.md."
  fi
fi

rm -f "$BIN/code"
if [ -n "$NOSANDBOX" ]; then
  printf '#!/bin/sh\nexec "%s/bin/code" --no-sandbox "$@"\n' "$APP" > "$BIN/code"
  chmod +x "$BIN/code"
else
  ln -s "$APP/bin/code" "$BIN/code"
fi

printf '#!/bin/sh\nexec sh -c "curl -fsSL https://raw.githubusercontent.com/%s/master/custom/install.sh | sh"\n' "$REPO" > "$BIN/code-update"
chmod +x "$BIN/code-update"

cp "$APP/resources/app/resources/linux/code.png" "$ICON_DIR/code.png" 2>/dev/null \
  || echo "Note: icon not found in the archive, the launcher will have no icon."
cat > "$DESKTOP" <<DESK
[Desktop Entry]
Name=Code
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=$APP/code${NOSANDBOX:+ $NOSANDBOX} %F
Icon=$ICON_DIR/code.png
Type=Application
StartupNotify=false
StartupWMClass=code
Categories=TextEditor;Development;IDE;
Keywords=vscode;
Actions=new-empty-window;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=$APP/code${NOSANDBOX:+ $NOSANDBOX} --new-window %F
Icon=$ICON_DIR/code.png
DESK
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$(dirname "$DESKTOP")" 2>/dev/null || true

echo "Installed Code $VERSION to $APP"
case ":$PATH:" in *":$BIN:"*) ;; *) echo "Note: add $BIN to your PATH." ;; esac
