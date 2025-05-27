#!/usr/bin/env bash

# This script sets up a local development environment similar to the GitHub Actions lint workflow.

set -e

# Install python3 and pip if not already installed (Debian/Ubuntu).
if command -v apt-get >/dev/null; then
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip
fi

# Upgrade pip and install Python packages used in CI
pip3 install --upgrade pip
pip3 install jmespath yamllint ansible-lint ansible

cat <<'EOM'
Environment ready. You can run:
  yamllint .
  ansible-lint
EOM

