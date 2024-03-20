#!/usr/bin/env zsh
# 
# Lokalise CLI v2 can be found here: https://github.com/lokalise/lokalise-cli-2-go
#
# Setting the environment variable LOKALISE2_TOKEN is necessary to execute this script.

# Project specific parameters:
SDK_PROJECT_ID=3931709465f04f20a1bc18.55914019
SAMPLE_PROJECT_ID=8964099365f434ac71f546.06213099
SDK_PATH=Sources/UI/Resources
SAMPLE_PATH=Example/Snabble
DIRECTORY_PREFIX="%LANG_ISO%.lproj"

lokalise2 \
    --token $LOKALISE2_TOKEN \
    --project-id $SDK_PROJECT_ID \
    file download \
    --format strings \
    --directory-prefix $DIRECTORY_PREFIX \
    --original-filenames=true \
    --unzip-to $SDK_PATH \
    --include-comments=false \
    --include-description=false \
    --export-empty-as=base  \
    --placeholder-format=ios \
    --add-newline-eof

lokalise2 \
    --token $LOKALISE2_TOKEN \
    --project-id $SAMPLE_PROJECT_ID \
    file download \
    --format strings \
    --directory-prefix $DIRECTORY_PREFIX \
    --original-filenames=true \
    --unzip-to $SAMPLE_PATH \
    --include-comments=false \
    --include-description=false \
    --export-empty-as=base  \
    --placeholder-format=ios \
    --add-newline-eof
