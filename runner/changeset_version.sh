#!/bin/sh

# Exit any previous pre mode
pnpm changeset pre exit

# check if we are looking for unstable release
if [ "$1" = "unstable" ]; then
  echo "Unstable release mode"

  # check if there is any major changeset in progress
  if grep -qe "major" -R .changeset; then
    echo "Major changeset detected, entering pre next-major mode"
    pnpm changeset pre enter next-major
  else
    echo "No major changeset detected, entering pre beta mode"
    pnpm changeset pre enter beta
  fi
fi

pnpm changeset version
