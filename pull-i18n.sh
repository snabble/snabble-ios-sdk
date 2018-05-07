#!/bin/bash
git fetch i18n
git subtree pull --prefix i18n i18n master --squash
