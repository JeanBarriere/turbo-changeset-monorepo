#!/bin/sh

GIT_BRANCH=$(git branch --show-current)

# build apps & packages
pnpm turbo build

# if we are in main, run release
if [ "$GIT_BRANCH" = "main" ]; then
  echo "Publishing the main branch"
  pnpm changeset publish
else
  echo "Publishing the $GIT_BRANCH branch"
  # get the version from the branch (release/{package}/{version})
  VERSION=$(echo $GIT_BRANCH | cut -d'/' -f 3)
  # if there is a version, run release
  if [ -n "$VERSION" ]; then
    echo "Publishing under the version $VERSION tag"
    # get mode and tag from changeset pre.json
    CHANGESET_MODE=$(cat .changeset/pre.json | jq -r '.mode')
    CHANGESET_TAG=$(cat .changeset/pre.json | jq -r '.tag')
    # if the mode is "pre" then the tag is the `tag` value, publish
    if [ "$CHANGESET_MODE" = "pre" ]; then
      echo "Publishing under the $CHANGESET_TAG tag"
      pnpm changeset publish --tag $VERSION-$CHANGESET_TAG
    # otherwise publish under the latest tag
    else
      echo "Publishing under the latest tag"
      pnpm changeset publish --tag $VERSION-latest
    fi
  else
    echo "cannot publish: branch $GIT_BRANCH is not a release branch"
  fi
fi
