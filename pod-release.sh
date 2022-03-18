#!/bin/sh

set -o pipefail

TODAY=$(date +%Y-%m-%d)
CHANGELOG_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" documentation/Changelog.md)

POD_VERSION=$(awk '/s.version.*=/ { print substr($3,2,length($3)-2) }' Snabble.podspec)

perl -pi -e "s/= \".*\"/= \"$POD_VERSION\"/" Snabble/Core/API/APIVersion.swift
SDK_VERSION=$(awk '/version =/ { print substr($6,2,length($6)-2) }' Snabble/Core/API/APIVersion.swift)

# feature flags
RUN_UNITTESTS=YES
BUILD_SAMPLE_APP=YES
COMMIT_AND_RELEASE=YES

trap "exit" INT

if [ "$POD_VERSION" != "$SDK_VERSION" ]; then
    echo "Versions in podspec and APIVersion don't match ($POD_VERSION vs $SDK_VERSION)"
    exit 1
fi

if [ "$TODAY" != "$CHANGELOG_DATE" ]; then
    echo "CHANGELOG is not up-to-date?"
    exit 1
fi

echo "updating strings..."
sh ./phrase-pull.sh

if [ "$RUN_UNITTESTS" == "YES" ]; then
    echo running unit tests...
    if (cd ../iOS-App; bundle install >/dev/null; bundle exec fastlane unittests); then
        echo "unit tests passed!"
    else
        echo "tests failed"
        exit 1
    fi
fi

if [ "$BUILD_SAMPLE_APP" == "YES" ]; then
    echo building sample app...
    if (cd Example; bundle exec pod install; xcodebuild CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGN_IDENTITY="" -scheme SnabbleSampleApp -workspace SnabbleSampleApp.xcworkspace -configuration Debug build | bundle exec xcpretty); then
        echo "sample app passed!"
        if Example/Pods/SwiftLint/swiftlint; then
            echo "SwiftLint passed!"
        else
            echo "SwiftLint found violation(s)"
            exit 1
        fi
    else
        echo "build failed"
        exit 1
    fi
fi

if [ "$COMMIT_AND_RELEASE" == "YES" ]; then
    git add .
    git commit -m "release v$POD_VERSION"
    git tag $POD_VERSION
    git push origin main --tags
fi
