#!/bin/bash

BRANCH=support-4.9

LOCALIZATION_REPO_URL=https://github.com/Evolveum/midpoint-localization
PRISM_REPO_URL=https://github.com/Evolveum/prism
MIDPOINT_REPO_URL=https://github.com/Evolveum/midpoint

LOCALIZATION_LATEST_COMMIT_HASH=`git ls-remote $LOCALIZATION_REPO_URL $BRANCH | cut -f 1`
PRISM_LATEST_COMMIT_HASH=`git ls-remote $PRISM_REPO_URL $BRANCH | cut -f 1`
MIDPOINT_LATEST_COMMIT_HASH=`git ls-remote $MIDPOINT_REPO_URL $BRANCH | cut -f 1`

echo $LOCALIZATION_LATEST_COMMIT_HASH
echo $PRISM_LATEST_COMMIT_HASH
echo $MIDPOINT_LATEST_COMMIT_HASH

sed -i -e "s/^\(ARG LOCALIZATION_RELEASE_REVISION=\).*$/\1$LOCALIZATION_LATEST_COMMIT_HASH/g" Dockerfile
sed -i -e "s/^\(ARG PRISM_RELEASE_REVISION=\).*$/\1$PRISM_LATEST_COMMIT_HASH/g" Dockerfile
sed -i -e "s/^\(ARG RELEASE_REVISION=\).*$/\1$MIDPOINT_LATEST_COMMIT_HASH/g" Dockerfile

