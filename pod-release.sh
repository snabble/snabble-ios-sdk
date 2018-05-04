#!/bin/sh

VERSION=$(awk '/s.version.*=/ { print substr($3,2,length($3)-2) }' Snabble.podspec)

git add .
git commit -m "release v$VERSION"
git tag $VERSION
git push origin master --tags
unset SNABBLE_DEV
pod trunk push Snabble.podspec --allow-warnings
