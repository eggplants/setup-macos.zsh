#!/usr/bin/env zsh

set -euo pipefail

cp ~/.Brewfile ./.Brewfile
git add ./.Brewfile
git diff --cached

echo -n "upload?"
read
git commit -m 'Update Brewfile'
git push
