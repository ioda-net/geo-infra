#!/usr/bin/env bash

###############################################################################
# geo-infra Scripts and templates to create and manage geoportals
# Copyright (c) 2015-2016, sigeom sa
# Copyright (c) 2015-2016, Ioda-Net Sàrl
#
# Contact : contact (at)  geoportal (dot) xyz
# Repository : https://github.com/ioda-net/geo-infra
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
###############################################################################

HELP['lint']="manuel lint [INFRA_DIR]

Launch lint for all json and csv files and report errors.
If portal is given, only the files in the portal infra dir will be linted.
Otherwise, all files in INFRA_DIR are linted."
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
Otherwise, all files in INFRA_DIR are linted."
function jsonlint {
    ERRORS=false
    local lint_dir="${INFRA_DIR}"
    if [[ -n "${1:-}" ]]; then
        lint_dir="$1"
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
Otherwise, all files in INFRA_DIR are linted."
function csvlint {
    ERRORS=false
    local lint_dir="${INFRA_DIR}"
    if [[ -n "${1:-}" ]]; then
        lint_dir="$1"
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
