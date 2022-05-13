#!/bin/bash

set -e

REPO_FULLNAME=$(jq -r ".repository.full_name" "$GITHUB_EVENT_PATH")

echo "## Initializing git repo..."
git init
echo "## Setting this directory as safe..."
git config --global --add safe.directory $(pwd)
echo "### Adding git remote..."
git remote add origin https://x-access-token:$ACCESS_TOKEN@github.com/$REPO_FULLNAME.git
echo "### Getting branch"
BRANCH=${GITHUB_REF#*refs/heads/}

if [[ $BRANCH == refs/tags* ]]; then
  echo "## The push was a tag, aborting!"
  exit
fi

echo "### git fetch $BRANCH ..."
git fetch origin $BRANCH
echo "### Branch: $BRANCH (ref: $GITHUB_REF )"
git checkout $BRANCH

echo "## Login into git..."
git config --global user.email "x0f5c3@tutanota.com"
git config --global user.name "x0f5c3"

echo "## Ignore workflow files (we may not touch them)"
git update-index --assume-unchanged .github/workflows/*

# Start release

git fetch --tags

echo "## Detecting current version"
OLD_VERSION=$(git describe --tags $(git rev-list --tags --max-count=1))  || exit 0
echo "## $OLD_VERSION"

NEW_VERSION=$(cat $ROOT_CMD | grep 'Version: "*"' | grep -oP "v\d*\.\d*\.\d*")

echo "## Version in commit detected: $NEW_VERSION!"

if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
  echo "## Version did not change. Aborting!"
else
  echo "## Version change detected!"

  git tag "$NEW_VERSION"

  echo "## Staging changes..."
  git add .
  echo "## Commiting files..."
  git commit -m "ci: release new version" || true
  echo "## Pushing to $BRANCH"
  git push -u origin $BRANCH --tags
fi
