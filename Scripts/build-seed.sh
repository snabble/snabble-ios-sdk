#!/bin/bash

# get a seed database from the server

# set -xv

DIR=$(dirname $0)
if [ -r "$DIR/.seed-defaults" ]; then
    . "$DIR/.seed-defaults"
fi

FORCE=0

USAGE="usage: $0 [-f|--force] [-v|--app-version VERSION] [-h|--host HOST] [-p|--project PROJECT] [-j|--jwt TOKEN] [-t|--target DIR]"

while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -f|--force)
        FORCE=1
        shift
        ;;
        -h|--host)
        HOST="$2"
        shift; shift
        ;;
        -p|--project)
        PROJECT="$2"
        shift; shift
        ;;
        -j|--jwt)
        PROJECT="$2"
        shift; shift
        ;;
        -t|--target)
        TARGET_DIR="$2"
        shift; shift
        ;;
        -v|--app-version)
        APP_VERSION="$2"
        shift; shift
        ;;
        -?|--help)
        echo $USAGE
        exit
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done

if [ -z "$HOST" -o -z "$PROJECT" -o -z "$JWT" -o -z "$APP_VERSION" ]; then
    echo "$0: 'app-version', 'host', 'project' and 'jwt' are required"
    echo $USAGE
    exit 1
fi

DB_URL="https://$HOST/api/$PROJECT/appdb"
METADATA_URL="https://$HOST/api/$PROJECT/metadata/app/ios/$APP_VERSION"

if [ -z "$TARGET_DIR" ]; then
    if [ -z "$PROJECT_DIR" ]; then
        echo "PROJECT_DIR not set, assuming './Seed' as TARGET_DIR" >&2
        TARGET_DIR=./Seed
    else
        TARGET_DIR=${PROJECT_DIR}/Knauber/Database/Seed
    fi
fi

mkdir -p $TARGET_DIR

if [ $FORCE -eq 1 ]; then
    rm -f $TARGET_DIR/seed.zip
fi

if [ ! -f $TARGET_DIR/seed.zip ]
then
    DIR=/tmp/db.$$
    mkdir $DIR
    DB=$DIR/products.sqlite3
    curl -H "Client-Token: $JWT" $DB_URL -so $DB
    DB_REV=$(sqlite3 $DB 'select value from metadata where key="revision"')
    zip -jmq9 $TARGET_DIR/seed.zip $DB
    rmdir $DIR

    if [ -z "$DB_REV" ]; then
        echo "error getting database"
        rm -f $TARGET_DIR/seed.zip $TARGET_DIR/seedRevision
        exit 1
    else
        echo $DB_REV>$TARGET_DIR/seedRevision
        echo "got new seed $DB_REV from $HOST"
    fi

    curl $METADATA_URL -so $TARGET_DIR/seedIndex.json
else
    R=$(cat $TARGET_DIR/seedRevision)
    echo "seed $R already exists"
fi
