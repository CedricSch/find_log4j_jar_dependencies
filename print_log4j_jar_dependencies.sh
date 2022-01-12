#!/bin/bash

function checkIfCommandExistsOrExit() {
    local COMMAND=$1
    if ! command -v "$COMMAND" &> /dev/null
    then
        printColor RED "Command \"$COMMAND\" could not be found. Aborting program."
        exit 1
    else
        printColor GREEN "Command \"$COMMAND\" found. Continue with program."
    fi
}

function printColor() {
    local COLOR=$1
    local MESSAGE=$2
    local CODE=
    local NC='\033[0m'

    case $COLOR in
        RED)
            CODE='\033[0;31m'
            ;;

        YELLOW)
            CODE="\033[0;33m"
            ;;

        GREEN)
            CODE='\033[0;32m'
            ;;

        *)
            CODE='\033[0;39m'
            ;;
    esac

    echo -e "${CODE}${MESSAGE}${NC}"
}

function repeat(){
    local COLOR=$1
    local N=$2
    local MESSAGE=$3

    for (( i=1; i<=$N; i++ )); do
        echo -n "-"
    done

    printColor $COLOR "$MESSAGE"
}

function findJars() {
    local UNZIP_DIR=$1
    local JAR_FILE=$2
    local DEPTH=$3
    local SEARCH_TERM=$4

    local RND=$(echo $RANDOM | base64 | head -c 20)
    local FILE_NAME=$(basename -s ".jar" "$JAR_FILE")
    local FILE_FILTER="*.jar"
    local UNZIP_DIR_RES="$UNZIP_DIR/${FILE_NAME}_${RND}"

    if [[ "$JAR_FILE" == *"$SEARCH_TERM"* ]]; then
        repeat RED $(( $DEPTH * 2 )) "> MATCH ${FILE_NAME}.jar;$JAR_FILE"
    elif [[ $DEPTH == 0 ]]; then
        repeat YELLOW $(( $DEPTH * 2 )) "> ${FILE_NAME}.jar;$JAR_FILE"
    fi

    unzip -o -j -q -d "$UNZIP_DIR_RES" "$JAR_FILE" "$FILE_FILTER" 2>/dev/null

    local UNZIP_ERRNO=$?

    if [[ "$DEPTH" > 0 ]]; then
        printColor RED "Removing file $JAR_FILE"
        rm "$JAR_FILE"
    fi

    if [[ "$UNZIP_ERRNO" == 0 ]]
    then
        local JAR_PATHS=()
        readarray -d '' JAR_PATHS < <(find "$UNZIP_DIR_RES" -mount -type f -iname "*.jar" -print0)

        for jar_file in "${JAR_PATHS[@]}"
        do 
            findJars "$UNZIP_DIR_RES" "$jar_file" $(($DEPTH + 1)) "$SEARCH_TERM"
        done
    fi
}

function tryMakeUnzipDir() {
    local UNZIP_DIR=$1

    if [[ -d "$UNZIP_DIR" ]]
    then
        printColor RED "$UNZIP_DIR already exists."
    else
        printColor GREEN "Creating $UNZIP_DIR."
        mkdir -p "$UNZIP_DIR"
    fi
}

function start() {
    local SEARCH_DIR=$1
    local UNZIP_DIR=$2
    local SEARCH_TERM=$3
    local JAR_PATHS=()

    checkIfCommandExistsOrExit "unzip"
    checkIfCommandExistsOrExit "find"
    checkIfCommandExistsOrExit "readarray"

    tryMakeUnzipDir "$UNZIP_DIR"

    readarray -d '' JAR_PATHS < <(find "$SEARCH_DIR" -mount -type f -iname "*.jar" -print0)

    printColor YELLOW "Found ${#JAR_PATHS[@]} .jar file(s) in $SEARCH_DIR"

    for jar_file in "${JAR_PATHS[@]}"
    do 
       findJars "$UNZIP_DIR" "$jar_file" 0 "$SEARCH_TERM"
    done

    printColor RED "Please remove the directory \"$UNZIP_DIR\"."
}

GLOBAL_PATH="${1:-~/temp}"
GLOBAL_RND=$(echo $RANDOM | base64 | head -c 20)

if [[ ! -d "$GLOBAL_PATH" ]]
then
  printColor RED "$GLOBAL_PATH not a valid directory"
  exit 1
fi

start "$GLOBAL_PATH" "/tmp/java_jars_${GLOBAL_RND}" "log4j"
