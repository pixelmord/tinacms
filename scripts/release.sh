#!/bin/bash

# Terminate after the first line that fails (returns nonzero exit code)
set -e

source $(dirname $0)/require_clean_work_tree.sh

# 0.1. Confirm Action
read -p "Create a new release? Type the word 'release' to confirm: "
if [[ ! $REPLY =~ ^release$ ]]
then
  echo "Release canceled."
  exit 1
fi

#0.2. Ensure no uncommitted changes
require_clean_work_tree

# 1. Update Matser
git checkout master
git pull

# 2. Update Latest
git checkout latest
git pull
git merge master

# 3. Run a Fresh Build
npm run hard-reset

# 4. Generate CHANGELOGs and Git Tags
#    You must have GH_TOKEN in your environment variables
lerna version \
  --yes \
  --conventional-commits \
  --conventional-graduate \
  --allow-branch latest \
  --create-release github \
  -m "chore(publish): latest" \
  --ignore-changes '**/*.md' '**/*.test.tsx?' '**/package-lock.json' '**/tsconfig.json' \
  --no-granular-pathspec

# 5. Publish to NPM
lerna publish from-package --yes

# 7. Backmerge to master
git checkout master
git merge latest
git push
