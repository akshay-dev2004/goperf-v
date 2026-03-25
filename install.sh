#!/bin/sh
set -eu

(set -o pipefail 2>/dev/null) && set -o pipefail

REPO="infraspecdev/goperf"
BIN_DIR="${BIN_DIR:-/usr/local/bin}"
VERSION="${VERSION:-latest}"

error() {
  echo "Error: $1" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || error "curl is required but not installed."

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
  darwin)
    OS_NAME="darwin"
    ;;
  linux)
    OS_NAME="linux"
    ;;
  mingw* | msys* | cygwin*)
    OS_NAME="windows"
    ;;
  *)
    error "Unsupported operating system: $OS"
    ;;
esac

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)            ARCH="amd64" ;;
  aarch64 | arm64)   ARCH="arm64" ;;
  *)                 error "Unsupported architecture: $ARCH" ;;
esac

if [ "$OS_NAME" = "darwin" ] && [ "$ARCH" = "amd64" ]; then
  error "macOS Intel (amd64) is not supported. Please build from source."
fi

BINARY_NAME="goperf-${OS_NAME}-${ARCH}"
EXE_NAME="goperf"
if [ "$OS_NAME" = "windows" ]; then
  BINARY_NAME="${BINARY_NAME}.exe"
  EXE_NAME="goperf.exe"
fi

if [ "$VERSION" = "latest" ]; then
  BINARY_URL="https://github.com/$REPO/releases/latest/download/$BINARY_NAME"
else
  BINARY_URL="https://github.com/$REPO/releases/download/$VERSION/$BINARY_NAME"
fi

if [ "$BIN_DIR" = "/usr/local/bin" ] && [ -d "$BIN_DIR" ] && [ ! -w "$BIN_DIR" ]; then
  BIN_DIR="$HOME/.local/bin"
fi

if [ ! -d "$BIN_DIR" ]; then
  if ! mkdir -p "$BIN_DIR" 2>/dev/null; then
    error "Cannot create directory: $BIN_DIR
Run the following as root, then retry:
  mkdir -p $BIN_DIR"
  fi
fi

if [ ! -w "$BIN_DIR" ]; then
  error "No write permission for: $BIN_DIR
Re-run with a writable directory:
  BIN_DIR=~/.local/bin sh install.sh
Or install as root:
  sudo sh install.sh"
fi

echo "Installing goperf..."
echo "  Platform : $OS_NAME/$ARCH"
echo "  Directory: $BIN_DIR"

if [ "$VERSION" = "latest" ]; then
  echo "  Downloading latest release..."
else
  echo "  Downloading release $VERSION..."
fi

TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'goperf.XXXXXX')
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

DOWNLOAD_PATH="$TMP_DIR/$EXE_NAME"

if ! curl -fL \
    --connect-timeout 10 \
    --retry 2 \
    --silent \
    --show-error \
    -o "$DOWNLOAD_PATH" \
    "$BINARY_URL"; then
  error "Failed to download binary from:
  $BINARY_URL

Possible reasons:
  - No internet connection
  - GitHub is unavailable
  - No release asset for $OS_NAME/$ARCH (version: $VERSION)

Browse releases manually:
  https://github.com/$REPO/releases"
fi

[ -s "$DOWNLOAD_PATH" ] || error "Downloaded binary is empty or corrupted."

echo "  Download complete 🎉"

if command -v install >/dev/null 2>&1; then
  install -m 755 "$DOWNLOAD_PATH" "$BIN_DIR/$EXE_NAME" \
    || error "Failed to install binary to $BIN_DIR/$EXE_NAME"
else
  cp "$DOWNLOAD_PATH" "$BIN_DIR/$EXE_NAME" \
    || error "Failed to copy binary to $BIN_DIR/$EXE_NAME"
  chmod 755 "$BIN_DIR/$EXE_NAME" \
    || error "Failed to make binary executable in $BIN_DIR/$EXE_NAME"
fi

echo ""
echo "✅ Installed: $BIN_DIR/$EXE_NAME"

RESOLVED=$(command -v "$EXE_NAME" 2>/dev/null || true)

if [ "$RESOLVED" != "$BIN_DIR/$EXE_NAME" ]; then
  if [ -z "$RESOLVED" ]; then
    echo ""
    echo "  Note: '$EXE_NAME' was not found in PATH."
    echo ""
    echo "   Add the following to your ~/.bashrc or ~/.zshrc:"
    echo ""
    echo "     export PATH=\"$BIN_DIR:\$PATH\""
    echo ""
    echo "   Then reload your shell:"
    echo ""
    echo "     source ~/.bashrc"
  fi
fi

echo ""
echo "Run 'goperf --help' to get started."
