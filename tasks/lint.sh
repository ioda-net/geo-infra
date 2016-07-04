#!/usr/bin/bash

HELP['lint']="manuel lint [PORTAL]

Launch lint for all json and csv files and report errors.
If portal is given, only the files in the portal infra dir will be linted.
Otherwise, all files in CUSTOMERS_INFRA_DIR are linted."
function lint {
    jsonlint "${1:-}"
    csvlint "${1:-}"

    if [[ "${ERRORS}" == "true" ]]; then
        echo -e '\n`./manuel lint` failed. Exiting.'
        exit 1
    fi
}


HELP['jsonlint']="manuel jsonlint [PORTAL]

Launch lint for all json files and report errors.
If portal is given, only the files in the portal infra dir will be linted.
Otherwise, all files in CUSTOMERS_INFRA_DIR are linted."
function jsonlint {
    ERRORS=false
    local lint_dir="${CUSTOMERS_INFRA_DIR}"
    if [[ -n "${1:-}" ]]; then
        lint_dir=$(_get-infra-dir "$1")
    fi

    for jsonfile in $(find "${lint_dir}" -name "*.json" | grep -v 'infra/dev' | grep -v 'infra/prod'); do
        local output=$(python3 -m json.tool "${jsonfile}" 2>&1 > /dev/null)
        if [[ $? -ne 0 ]]; then
            echo "${jsonfile}"
            echo -e "${output}"
            ERRORS=true
        fi
    done
}


HELP['csvlint']="manuel csvlint [PORTAL]

Launch lint for all csv files and report errors.
If portal is given, only the files in the portal infra dir will be linted.
Otherwise, all files in CUSTOMERS_INFRA_DIR are linted."
function csvlint {
    ERRORS=false
    local lint_dir="${CUSTOMERS_INFRA_DIR}"
    if [[ -n "${1:-}" ]]; then
        lint_dir=$(_get-infra-dir "$1")
    fi

    if ! type csvclean > /dev/null 2>&1; then
        echo "WARNINGS: csvclean is not found on this system. CSV files won't be linted"
        return 0
    fi

    for csvfile in $(find "${lint_dir}" -name "*.csv" | grep -v 'infra/dev' | grep -v 'infra/prod'); do
        local output=$(csvclean -n "${csvfile}" 2>&1)
        if [[ "${output}" != "No errors." ]]; then
            echo "${csvfile}"
            echo -e "${output}"
            ERRORS=true
        fi
    done
}
