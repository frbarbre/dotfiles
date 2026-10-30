#!/usr/bin/env bash
# Apps that aren't in Homebrew or the App Store. Skips anything already installed.
set -euo pipefail
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

install_dmg() { # name url
  echo "Installing $1..."
  curl -fsSL -o "$TMP/$1.dmg" "$2"
  local mnt; mnt="$(hdiutil attach -nobrowse -readonly "$TMP/$1.dmg" | tail -1 | cut -f3)"
  cp -R "$mnt/$1.app" /Applications/
  hdiutil detach -quiet "$mnt"
}

install_zip() { # name url
  echo "Installing $1..."
  curl -fsSL -o "$TMP/$1.zip" "$2"
  ditto -xk "$TMP/$1.zip" "$TMP/$1"
  cp -R "$TMP/$1/$1.app" /Applications/
}

# Orca: personal fork (it updates itself after install)
[ -d /Applications/Orca.app ] || \
  install_dmg Orca "https://github.com/frbarbre/orca/releases/latest/download/orca-macos-arm64.dmg"

# Scrawl: newest build from its update feed
if [ ! -d /Applications/Scrawl.app ]; then
  url="$(curl -fsSL https://scrawl.kitlangton.com/appcast.xml | grep -oE 'url="[^"]+arm64\.zip"' | head -1 | cut -d'"' -f2)"
  install_zip Scrawl "$url"
fi

# NotchNook: no stable direct download (and lo.cafe DNS is flaky), so open the site
[ -d /Applications/NotchNook.app ] || { echo "NotchNook: download it from https://lo.cafe/notchnook"; open https://lo.cafe/notchnook; }
