#!/bin/bash

CODE_KEYS=/tmp/c-l10nkeys
STR_KEYS=/tmp/s-l10nkeys
STR_EN_KEYS=/tmp/s-en-l10nkeys
STR_DE_KEYS=/tmp/s-de-l10nkeys

# check that keys used in code actually occur in the twine file
find Snabble -name "*.swift" | 
    xargs grep "\"Snabble.*\".localized()" | 
    sed 's/.*\"\(Snabble.*\)\".localized().*/\1/' | 
    sort | uniq >$CODE_KEYS

# check for keys present in the strings file that aren't used
twine generate-localization-file i18n/Snabble.twine --lang en --format apple Snabble/UI/en.lproj/SnabbleLocalizable.strings --tags ios --untagged
grep ^\" Snabble/UI/en.lproj/SnabbleLocalizable.strings | sed 's/\"\(.*\)\" = \".*/\1/' | sort | uniq >$STR_KEYS

echo "keys used in code but not found in the strings file:"
comm -23 $CODE_KEYS $STR_KEYS

# echo
# echo "keys found in the strings file but not used in code:"
# comm -13 $CODE_KEYS $STR_KEYS

# check keys in the app's de and en strings files

(cd ../iOS-App; twine generate-all-localization-files i18n/i18n.twine Sources --tags ios --untagged --format apple)

echo
grep ^\" ../iOS-App/Sources/en.lproj/Localizable.strings | sed 's/\"\(.*\)\" = \".*/\1/' | sort | uniq >$STR_EN_KEYS
echo "keys used in code but not found in the app's en strings file:"
comm -23 $CODE_KEYS $STR_EN_KEYS

echo
grep ^\" ../iOS-App/Sources/de.lproj/Localizable.strings | sed 's/\"\(.*\)\" = \".*/\1/' | sort | uniq >$STR_DE_KEYS
echo "keys used in code but not found in the app's de strings file:"
comm -23 $CODE_KEYS $STR_DE_KEYS

# check keys in knauber's de strings files

echo
grep ^\" ../knauber-ios/Sources/de.lproj/Localizable.strings | sed 's/\"\(.*\)\" = \".*/\1/' | sort | uniq >$STR_DE_KEYS
echo "keys used in code but not found in knauber's de strings file:"
comm -23 $CODE_KEYS $STR_DE_KEYS

# check keys in wasgau's de strings files

echo
grep ^\" ../wasgau-ios/Sources/de.lproj/Localizable.strings | sed 's/\"\(.*\)\" = \".*/\1/' | sort | uniq >$STR_DE_KEYS
echo "keys used in code but not found in wasgau's de strings file:"
comm -23 $CODE_KEYS $STR_DE_KEYS
