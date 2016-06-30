#!/usr/bin/bash

HELP['lint']="manuel lint

Launch lint for all json and csv files and report errors."
function lint {
    jsonlint
    csvlint

    if [[ "${ERRORS}" == "true" ]]; then
        echo -e '\n`./manuel lint` failed. Exiting.'
        exit 1
    fi
}


HELP['jsonlint']="manuel jsonlint

Launch lint for all json files and report errors."
function jsonlint {
    ERRORS=false
    for jsonfile in $(find in -name "*.json"); do
        local output=$(python3 -m json.tool "${jsonfile}" 2>&1 > /dev/null)
        if [[ $? -ne 0 ]]; then
            echo "${jsonfile}"
            echo -e "${output}"
            ERRORS=true
        fi
    done
}


HELP['csvlint']="manuel csvlint

Launch lint for all csv files and report errors."
function csvlint {
    ERRORS=false
    if ! type csvclean > /dev/null 2>&1; then
        echo "WARNINGS: csvclean is not found on this system. CSV files won't be linted"
        return 0
    fi

    for csvfile in $(find in -name "*.csv"); do
        local output=$(csvclean -n "${csvfile}" 2>&1)
        if [[ "${output}" != "No errors." ]]; then
            echo "${csvfile}"
            echo -e "${output}"
            ERRORS=true
        fi
    done
}
