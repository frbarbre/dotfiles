#!/usr/bin/env bash
# macOS preferences. Add `defaults write` lines here as you change settings you care about.
set -euo pipefail

# Example: show file extensions in Finder
# defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# killall Finder

# Screen Sharing can only be enabled in System Settings; a launchctl-enabled service
# refuses clients with "Screen sharing is not permitted". Open the pane instead.
open "x-apple.systempreferences:com.apple.Sharing-Settings.extension"
