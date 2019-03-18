#!/bin/sh

TODAY=$(date +%Y-%m-%d)
CHANGELOG_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" CHANGELOG.md)

POD_VERSION=$(awk '/s.version.*=/ { print substr($3,2,length($3)-2) }' Snabble.podspec)
SDK_VERSION=$(awk '/version =/ { print substr($5,2,length($5)-2) }' Snabble/Core/API/APIVersion.swift)

trap "exit" INT

if [ "$POD_VERSION" != "$SDK_VERSION" ]; then
    echo "Versions in podspec and APIVersion don't match ($POD_VERSION vs $SDK_VERSION)"
    exit 1
fi

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

git add .
git commit -m "release v$POD_VERSION"
git tag $POD_VERSION
git push origin master --tags
unset SNABBLE_DEV
pod trunk push Snabble.podspec --allow-warnings
