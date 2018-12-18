#!/bin/sh

TODAY=$(date +%Y-%m-%d)
CHANGELOG_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" CHANGELOG.md)

if [ "$TODAY" != "$CHANGELOG_DATE" ]; then
    echo "CHANGELOG is not up-to-date?"
    exit 1
fi

echo running unit tests...
if (cd ../iOS-whitelabel; fastlane unittests); then
    echo "passed!"
else
    echo "tests failed"
    exit 1
fi

echo building sample app...
if (cd Example; xcodebuild -scheme Snabble-Example -workspace Snabble.xcworkspace build); then
    echo "passed!"
else
    echo "build failed"
    exit 1
fi

VERSION=$(awk '/s.version.*=/ { print substr($3,2,length($3)-2) }' Snabble.podspec)

git add .
git commit -m "release v$VERSION"
git tag $VERSION
git push origin master --tags
unset SNABBLE_DEV
pod trunk push Snabble.podspec --allow-warnings
