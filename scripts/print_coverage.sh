#!/bin/sh

if ! command -v lcov >/dev/null 2>&1; then
  echo "Error: lcov is not installed."
  echo ""
  echo "To install it, use:"
  echo "  sudo dnf install lcov     # For Fedora/RHEL"
  echo "  sudo apt install lcov     # For Debian/Ubuntu"
  exit 1
fi

lcov --summary coverage/lcov.info | grep 'lines' | awk '{print $2}' | tr -d '%'
