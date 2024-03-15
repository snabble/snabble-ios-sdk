alias lokalise-download="lokalise2 file --config lokalise.yml download --format strings --directory-prefix "%LANG_ISO%.lproj" --original-filenames=true --unzip-to ./Sources/UI/Resources --include-comments=false  --include-description=false --export-empty-as=base  --placeholder-format=ios"
#!/usr/bin/env zsh
# 
# Lokalise CLI v2 can be found here: https://github.com/lokalise/lokalise-cli-2-go
#
# Setting the environment variable LOKALISE2_TOKEN is necessary to execute this script.

# Project specific parameters:
PROJECT_ID=3931709465f04f20a1bc18.55914019
RES_PATH=Sources/UI/Resources
DIRECTORY_PREFIX="%LANG_ISO%.lproj"

# lokalise2 \
#     --token $LOKALISE2_TOKEN \
#     --project-id $PROJECT_ID \
#     file download \
#     --format strings \
#     --directory-prefix $DIRECTORY_PREFIX \
#     --original-filenames=true \
#     --unzip-to $RES_PATH \
#     --include-comments=false \
#     --include-description=false \
#     --export-empty-as=base  \
#     --placeholder-format=ios

lokalise2 \
    --token $LOKALISE2_TOKEN \
    --project-id $PROJECT_ID \
    file download \
    --format xml \
    --unzip-to .
