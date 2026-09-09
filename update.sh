#!/bin/bash
set -euo pipefail

BRANCH=support-4.8

TAG=${1:-}

LOCALIZATION_REPO_URL=https://github.com/Evolveum/midpoint-localization
PRISM_REPO_URL=https://github.com/Evolveum/prism
MIDPOINT_REPO_URL=https://github.com/Evolveum/midpoint

resolve_branch_commit() {
  local repo_url=$1
  git ls-remote "$repo_url" "$BRANCH" | cut -f 1
}

resolve_tag_commit() {
  local repo_url=$1
  local hash
  # Prefer the peeled (^{}) line so annotated tags resolve to the commit they point to.
  hash=$(git ls-remote "$repo_url" "refs/tags/$TAG" "refs/tags/$TAG^{}" | awk '{print $1, $2}' | { grep -F "^{}" || true; } | head -1 | cut -d' ' -f1)
  if [ -z "$hash" ]; then
    hash=$(git ls-remote "$repo_url" "refs/tags/$TAG" | head -1 | cut -f 1)
  fi
  if [ -z "$hash" ]; then
    echo "Tag $TAG not found in $repo_url" >&2
    exit 1
  fi
  echo "$hash"
}

if [ -n "$TAG" ]; then
  VERSION=${TAG#v}
  LOCALIZATION_LATEST_COMMIT_HASH=$(resolve_tag_commit "$LOCALIZATION_REPO_URL")
  PRISM_LATEST_COMMIT_HASH=$(resolve_tag_commit "$PRISM_REPO_URL")
  MIDPOINT_LATEST_COMMIT_HASH=$(resolve_tag_commit "$MIDPOINT_REPO_URL")
  echo "tag: $TAG (version: $VERSION)"
else
  LOCALIZATION_LATEST_COMMIT_HASH=$(resolve_branch_commit "$LOCALIZATION_REPO_URL")
  PRISM_LATEST_COMMIT_HASH=$(resolve_branch_commit "$PRISM_REPO_URL")
  MIDPOINT_LATEST_COMMIT_HASH=$(resolve_branch_commit "$MIDPOINT_REPO_URL")
  echo "branch: $BRANCH (HEAD)"
fi

echo "localization: $LOCALIZATION_LATEST_COMMIT_HASH"
echo "prism: $PRISM_LATEST_COMMIT_HASH"
echo "midpoint: $MIDPOINT_LATEST_COMMIT_HASH"

sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i -e "$1" "$2"
  else
    sed -i '' -e "$1" "$2"
  fi
}

# Dockerfile
sed_inplace "s/^\(ARG LOCALIZATION_RELEASE_REVISION=\).*\$/\1$LOCALIZATION_LATEST_COMMIT_HASH/g" Dockerfile
sed_inplace "s/^\(ARG PRISM_RELEASE_REVISION=\).*\$/\1$PRISM_LATEST_COMMIT_HASH/g" Dockerfile
sed_inplace "s/^\(ARG RELEASE_REVISION=\).*\$/\1$MIDPOINT_LATEST_COMMIT_HASH/g" Dockerfile

if [ -n "$TAG" ]; then
  sed_inplace "s/^\(ARG BASE_REVISION=\).*\$/\1$TAG/g" Dockerfile

  # pom.xml: project's own version (4-space indent, top of file)
  sed_inplace "s/^\(    <version>\)[0-9][0-9.]*\(<\/version>\)\$/\1$VERSION\2/" pom.xml
  # pom.xml: model-impl / admin-gui dependency versions (12-space indent)
  sed_inplace "s/^\(            <version>\)[0-9][0-9.]*\(<\/version>\)\$/\1$VERSION\2/" pom.xml
fi
