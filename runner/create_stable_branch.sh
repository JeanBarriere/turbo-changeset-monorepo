#!/bin/sh

# get the current package version
CURRENT_DIR=${PWD##*/} # get the current directory name
PKG=$(pnpm pkg get name version --json) # get the package name and version
PKG_NAME=$(echo $PKG | jq -r '.name') # extract the package name
PKG_VERSION=$(echo $PKG | jq -r '.version') # extract the package version
PKG_TAG=$(echo "$PKG_NAME@$PKG_VERSION") # generate the git tag of that package last stable release
PKG_VERSION_MAJOR=$(echo $PKG_VERSION | cut -d '.' -f 1) # extract the current major version

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

# check if branch exists
if git rev-parse --verify release/${CURRENT_DIR}/${PKG_VERSION_MAJOR} > /dev/null 2>&1; then
  echo "Branch release/${CURRENT_DIR}/${PKG_VERSION_MAJOR} already exists"
  exit 0
fi

# otherwise, checkout to the commit before the breaking change
git checkout $COMMIT_SHA^1

# create a new branch for the stable release, detached from the breaking change commit
git switch -c release/${CURRENT_DIR}/${PKG_VERSION_MAJOR}

# push the new branch to the remote
git push origin release/${CURRENT_DIR}/${PKG_VERSION_MAJOR}
