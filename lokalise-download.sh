#!/usr/bin/env zsh
# 
# Lokalise CLI v2 can be found here: https://github.com/lokalise/lokalise-cli-2-go
#
# Setting the environment variable LOKALISE2_TOKEN is necessary to execute this script.

function lokalise {
    lokalise2 \
        --token $LOKALISE2_TOKEN \
        --project-id $1 \
        file download \
        --format strings \
        --directory-prefix "%LANG_ISO%.lproj" \
        --original-filenames=true \
        --unzip-to $2 \
        --include-comments=false \
        --include-description=false \
        --export-empty-as=base  \
        --placeholder-format=ios \
        --add-newline-eof \
        $@
}

# sdk
lokalise 3931709465f04f20a1bc18.55914019 Sources/UI/Resources

# sample
lokalise 8964099365f434ac71f546.06213099 Example/Snabble
