#!/bin/sh

# Exit any previous pre mode
pnpm changeset pre exit

# check if we are looking for unstable release
if [ "$1" = "unstable" ]; then
  echo "Unstable release mode"

  # check if there is any major changeset in progress
  if grep -qe "major" -R .changeset/*.md; then
    echo "Major changeset detected, entering pre next-major mode"
    pnpm changeset pre enter next-major
  else
    echo "No major changeset detected, checking branch for beta tag"
    GIT_BRANCH=$(git branch --show-current)
    # get the version from the branch (release/{package}/{version})
    VERSION=$(echo $GIT_BRANCH | grep -Eow "[0-9]*$")
    # if the branch is not main and there is a version, enter pre beta mode
    if [ "$GIT_BRANCH" != "main" ] && [ -n "$VERSION" ]; then
      echo "Entering pre beta-v$VERSION mode"
      pnpm changeset pre enter beta-v$VERSION
    else
      echo "No version detected, entering pre beta mode"
      pnpm changeset pre enter beta
    fi
  fi
else
  echo "Stable release mode"
  PACKAGE_DIR=$1;
  # get package name
  PACKAGE_NAME=$(cd $PACKAGE_DIR && pnpm pkg get name | jq -r '.')
  # all available packages
  PKG_NAMES="[\"@pkges/web\", \"@pkges/docs\", \"@pkges/libui\", \"@pkges/utils\", \"@pkges/runner\"]"
  # remove $PACKAGE_NAME from JSONPKGNAMES
  NEWCONFIG=$(echo $PKG_NAMES | jq --arg PACKAGE_NAME "$PACKAGE_NAME" -r 'map(select(. != $PACKAGE_NAME))')
  # new file
  TMP_FILE=$(mktemp)
  # create new config
  jq --argjson CONFIG "$NEWCONFIG" '.ignore=$CONFIG' .changeset/config.json > $TMP_FILE
  # save old config
  mv .changeset/config.json .changeset/config.json.bak
  # replace old config with new config
  mv $TMP_FILE .changeset/config.json
fi

# update versions
pnpm changeset version

# if we are in stable mode, restore the old config
if [ "$1" != "unstable" ]; then
  PACKAGE_DIR=$1;
  git add $PACKAGE_DIR;
  git checkout -- packages/
  git checkout -- apps/
  git checkout -- runner/
  git checkout -- .changeset/pre.json
  pnpm changeset version # (will update pre.json) with files removed
  git restore --staged $PACKAGE_DIR;
  mv .changeset/config.json.bak .changeset/config.json
fi
