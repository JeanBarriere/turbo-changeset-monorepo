#!/bin/sh

SCRIPT_DIR=${0%/*};
ROOT_DIR=${SCRIPT_DIR%/*}
# get the current package version
CURRENT_DIR=${PWD##*/} # get the current directory name
PKG_NAME=$(cat package.json | jq -r '.name') # extract the package name
# get the tag from the last stable release in pre.json
PKG_VERSION=$(cat ${ROOT_DIR}/.changeset/pre.json | jq --arg PKG_NAME "$PKG_NAME" -r '.initialVersions | to_entries | map(select(.key == $PKG_NAME) | .value)[]')
PKG_TAG=$(echo "$PKG_NAME@$PKG_VERSION") # generate the git tag of that package last stable release
PKG_VERSION_MAJOR=$(echo $PKG_VERSION | cut -d '.' -f 1) # extract the current major version

# check if the tag exists
if git rev-parse --verify $PKG_TAG > /dev/null 2>&1; then
  # get the first breaking change since that version
  # reverse logs from HEAD to the last tag (git log)
  # find the first breaking change commit sha (grep + cut)
  COMMIT_SHA=$(git log $PKG_TAG..HEAD --oneline --reverse | grep -m 1 ")\!" | cut -d ' ' -f 1)

  if [ -z "$COMMIT_SHA" ]; then
    echo "No breaking change found since $PKG_TAG"
    exit 0
  else
    echo "Breaking change found in commit $COMMIT_SHA since $PKG_TAG"
  fi
else
  echo "Tag $PKG_TAG does not exist"
  # get the tag from package.json version
  PKG_VERSION=$(cat package.json | jq -r '.version') # extract the package version
  PKG_TAG=$(echo "$PKG_NAME@$PKG_VERSION") # generate the git tag of that package last stable release
  PKG_VERSION_MAJOR=$(echo $PKG_VERSION | cut -d '.' -f 1) # extract the current major version


  if git rev-parse --verify $PKG_TAG > /dev/null 2>&1; then
    echo "Tag $PKG_TAG found"
  else
    echo "Tag $PKG_TAG not found"
    exit 0
  fi

  COMMIT_SHA=$(git log $PKG_TAG..HEAD --oneline --reverse | grep -m 1 ")\!" | cut -d ' ' -f 1)

  if [ -z "$COMMIT_SHA" ]; then
    echo "No breaking change found since $PKG_TAG"
    exit 0
  else
    echo "Breaking change found in commit $COMMIT_SHA since $PKG_TAG"
  fi
fi

# check if branch exists
if git rev-parse --verify release/${CURRENT_DIR}/${PKG_VERSION_MAJOR} > /dev/null 2>&1; then
  echo "Branch release/${CURRENT_DIR}/${PKG_VERSION_MAJOR} already exists"
  exit 0
fi

# otherwise, checkout to the commit before the breaking change
git checkout $COMMIT_SHA^1

# create a new branch for the stable release, detached from the breaking change commit
git switch --create release/${CURRENT_DIR}/${PKG_VERSION_MAJOR}

# sync files from .github to match the main branch
git checkout origin/main -- ${ROOT_DIR}/.github/workflows

# commit the changes
git add ${ROOT_DIR}/.github/workflows
git commit -m "chore: checkout .github/workflows files from main branch"

# push the new branch to the remote
git push origin release/${CURRENT_DIR}/${PKG_VERSION_MAJOR}
