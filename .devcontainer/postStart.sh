#!/usr/bin/env bash
set -e

MISE="$HOME/.local/bin/mise"
# Trust first, activating reads mise.local.toml too
"$MISE" trust
eval "$("$MISE" activate bash)"
"$MISE" install
sudo chmod 666 /ssh-agent
# So git over SSH, e.g. a git source in the Gemfile, doesn't stop to ask
mkdir -p ~/.ssh
ssh-keygen -F github.com >/dev/null 2>&1 || ssh-keyscan -t ed25519 github.com 2>/dev/null >> ~/.ssh/known_hosts

[ ! -f package.json ] || "$MISE" exec -- npm install
"$MISE" exec -- bundle install
# A Rails engine: its bin/rails has the dummy app's tasks under app:
"$MISE" exec -- bin/rails app:db:prepare
# The dummy app's styles, with those of vario and form_components
"$MISE" exec -- bin/rails app:tailwindcss:build
