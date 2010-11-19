#!/bin/bash
# Author: dprince

if (( $# < 2 )); then
	echo "Create tagged releases."
	echo "usage: tag.sh <branch> <version>"
	echo "example: tag.sh \"master\" \"1.0.0\""
	exit 1
fi
BRANCH=$1
VERSION=$2
UNDERSCORE_VERSION=${2//\./_}

function fail {
	echo "$1" && exit 1
}

[ -d .git ] || fail "Run this command from the top level of the project."

git branch $UNDERSCORE_VERSION $BRANCH || fail "Failed to create branch."
git checkout $UNDERSCORE_VERSION || fail "Failed to checkout branch."

#update version information
sed -e "s|^CLOUD_SERVERS_VPC_VERSION.*|CLOUD_SERVERS_VPC_VERSION=\"$VERSION\"|" \
 -i config/environment.rb \
  || fail "Failed to update environment.rb file with version: $VERSION."
git commit -a -m "Updating version information for tag: $VERSION" \
  || fail "Failed to commit version information."

git tag $VERSION
git push origin $UNDERSCORE_VERSION
git push origin --tags
git checkout master
