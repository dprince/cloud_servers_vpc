#!/bin/bash
# Script to generate a SRPM (and optionally an RPM as well).
# If an arg is specified both the SRPM and RPM will get built.

# Author: dan.prince
# Date: Feb. 17th 2010

BUILD_OPTS="-bs" # Default to source RPM only
(( "$#" >= 1 )) && { echo "Building all."; BUILD_OPTS="-ba"; }

CONTRIB_DIR="$PWD/$(dirname $0)"
[ $CONTRIB_DIR == '.' ] && CONTRIB_DIR="$PWD"

# clean the rpmbuild directory
for DIR in SOURCES BUILD BUILDROOT SRPMS RPMS; do
	[ -d $CONTRIB_DIR/rpmbuild/$DIR/ ] || mkdir $CONTRIB_DIR/rpmbuild/$DIR/
	rm -Rf $CONTRIB_DIR/rpmbuild/$DIR/*
done

# create staging directory
TAR_TMP_DIR=$(mktemp -d)
mkdir $TAR_TMP_DIR/cloud-servers-vpc
cp -a $CONTRIB_DIR/../* $TAR_TMP_DIR/cloud-servers-vpc

# create tar file in SOURCES
mkdir -p "$CONTRIB_DIR/rpmbuild/SOURCES/"
cd $TAR_TMP_DIR
tar czf $CONTRIB_DIR/rpmbuild/SOURCES/cloud-servers-vpc.tar.gz cloud-servers-vpc
cd -

rm -Rf "$TAR_TMP_DIR" #cleanup

rpmbuild "$BUILD_OPTS" --define "_topdir $CONTRIB_DIR/rpmbuild" \
  "$CONTRIB_DIR/rpmbuild/SPECS/cloud-servers-vpc.spec"
