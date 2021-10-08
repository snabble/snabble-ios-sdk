#!/bin/sh

phrase pull

if which swiftgen >/dev/null; then
    swiftgen
elif which mint >/dev/null; then
    mint run swiftgen/swiftgen
else
    echo "can't run swiftgen" >&2
    exit 1
fi
