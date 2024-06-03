#!/bin/sh

GIT_BRANCH=$(git branch --show-current)
# get the version from the branch (release/{package}/{version})
VERSION=$(echo $GIT_BRANCH | cut -d'/' -f 3)

# build apps & packages
pnpm turbo build

# if we are in main, run release
if [ "$GIT_BRANCH" = "main" ]; then
  echo "Publishing the main branch"
  pnpm changeset publish
# if there is a version, run release
elif [[ "$VERSION" =~ ^[0-9]+$ ]]; then
  echo "Publishing $GIT_BRANCH branch under the version $VERSION tag"
  # get mode and tag from changeset pre.json
  CHANGESET_MODE=$(cat .changeset/pre.json | jq -r '.mode')
  # if the mode is not "pre" then publish under custom latest tag
  if [ "$CHANGESET_MODE" != "pre" ]; then
    echo "Publishing under the latest-v$VERSION tag"
    pnpm changeset publish --tag latest-v$VERSION
  else
    pnpm changeset publish
  fi
else
  echo "cannot publish: branch $GIT_BRANCH is not a release branch"
fi
