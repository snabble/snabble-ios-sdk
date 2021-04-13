#!/bin/sh

set -o pipefail

TODAY=$(date +%Y-%m-%d)
CHANGELOG_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" CHANGELOG.md)

POD_VERSION=$(awk '/s.version.*=/ { print substr($3,2,length($3)-2) }' Snabble.podspec)

perl -pi -e "s/= \".*\"/= \"$POD_VERSION\"/" Snabble/Core/API/APIVersion.swift
SDK_VERSION=$(awk '/version =/ { print substr($6,2,length($6)-2) }' Snabble/Core/API/APIVersion.swift)

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
if (cd ../iOS-App; bundle install >/dev/null; bundle exec fastlane unittests); then
    echo "unit tests passed!"
else
    echo "tests failed"
    exit 1
fi

echo building sample app...
if (cd Example; pod install; xcodebuild -scheme SnabbleSampleApp -workspace SnabbleSampleApp.xcworkspace -configuration Debug build | xcpretty); then
    echo "sample app passed!"
else
    echo "build failed"
    exit 1
fi

echo checking RN wrapper compatibility...
if [ -d ../react-native-snabble ]; then
    (
    cd ../react-native-snabble
    perl -pi -e "s/, \"= .*\"/, \"= $POD_VERSION\"/" ios/Snabble-ReactNative.podspec
    cd Sample/ios
    pod install
    if SKIP_BUNDLING=YES xcodebuild CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGN_IDENTITY="" -scheme Sample -workspace Sample.xcworkspace -configuration Debug build | xcpretty; then
        echo "building RN sample passed"
    else
        echo "building RN sample failed"
        exit 1
    fi
    )
fi

echo "updating strings file..."
phrase pull

git add .
git commit -m "release v$POD_VERSION"
git tag $POD_VERSION
git push origin main --tags
