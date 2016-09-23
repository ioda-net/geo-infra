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

HELP['generate']="manuel generate OPTIONS

Wrapper around scripts/generate.py. All the options are passed to the python script. Use
--help for more details."
function generate {
    "${GENERATE_CMD}" "$@"
}


HELP['render']="manuel render OPTIONS

Wrapper around scripts/render.py --front-dir \$FRONT_DIR. All the options are passed to the script.
Use --help for more details."
function render {
    "${RENDER_CMD}" --front-dir "${FRONT_DIR}" "$@"
}


HELP['generate-global-search-conf']="manuel generate-global-search-conf [TYPE] [INFRA_DIR]

Generate the global configuration for sphinx and restart searchd (if type is 'dev').

**Default values**

- *type* dev
- *infra_dir* \$INFRA_DIR"
function generate-global-search-conf {
    local portal_type="dev"
    local infra_dir

    if [[ "${1:-}" == 'prod' ]]; then
        portal_type=prod
        shift
        _load-prod-config
    elif [[ "${1:-}" == 'dev' ]]; then
        shift
        # If we are on dev, we set PROD_GIT_REPOS_LOCATION.
        PROD_GIT_REPOS_LOCATION="${INFRA_DIR}"
    fi

    if [[ -f "${INFRA_DIR}/config/dist/_common.dist.toml" ]]; then
        infra_dir="${INFRA_DIR}"
    elif [[ -n "${1:-}" ]]; then
        infra_dir="${INFRA_DIR}/$1"
    else
        echo "You must specify an infra directory as an argument or set INFRA_DIR to a customer infra dir" >&2
        exit 1
    fi

    generate --search-global \
        --infra-dir "${infra_dir}" \
        --type "${portal_type}" \
        --prod-git-repos-location "${PROD_GIT_REPOS_LOCATION:-}"

    if [[ "${portal_type}" == 'dev' ]]; then
        restart-service "search" "$@"
    fi
}


HELP['restart-service']="manuel restart-service SERVICE [INFRAS]

Restart the specified service.

If the service is infrastructure specific, you can pass the list of infras for which it must be restarted."
function restart-service {
    local prod_cmd="sudo_$1_restart"
    local infra_names=()
    if type "${prod_cmd}"  > /dev/null 2>&1; then
        "${prod_cmd}"
    else
        case "$1" in
            apache|apache2|httpd)
                _restart-apache
                ;;
            "search"|"searchd"|"sphinx")
                # $1 is the service name. After shift we have the infra names in \$@.
                shift
                _get-infra-names "$@"

                for infra_name in "${infra_names[@]}"; do
                    sudo "${SYSTEMCTL_CMD}" restart "searchd@${infra_name}.service"
                done
                ;;
            "tomcat")
                if ! sudo "${SYSTEMCTL_CMD}" restart tomcat.service; then
                    echo "Trying tomcat8.service"
                    sudo "${SYSTEMCTL_CMD}" restart tomcat8.service
                fi
                ;;
            *)
                if [[ -e "/usr/lib/systemd/system/$1.service" ]]; then
                    sudo "${SYSTEMCTL_CMD}" restart "$1.service"
                elif [[ -e "/usr/lib/systemd/system/${1}d.service" ]]; then
                    sudo "${SYSTEMCTL_CMD}" restart "${1}d.service"
                elif [[ -e "/usr/lib/systemd/system/${1}" ]]; then
                    sudo "${SYSTEMCTL_CMD}" restart "$1.service"
                else
                    echo '$1 service not found' >&2
                fi
        esac
    fi
}


function _restart-apache {
    if [[ -e '/usr/lib/systemd/system/httpd.service' ]]; then
        sudo "${SYSTEMCTL_CMD}" restart httpd.service
    else
        sudo "${SYSTEMCTL_CMD}" restart apache2.service
    fi
}


HELP['reindex']="manuel reindex [-i INFRA_DIR] [-p PORTALS]

Launch a reindexation of sphinx. Use one and only one of these options:

- -i INFRA_DIR to reindex everything for the specified infrastructure.
- -p PORTALS to reindex only these portals. The infrastructure directory will be determined
  automatically.

If launched without parameters, it will reindex everything."
function reindex {
    local infra_names=()
    local portal
    local reindex_type
    local index

    while ps aux | grep /usr/bin/indexer | grep -vq grep; do
        echo "WARNING: reindex already in progress. Waiting."
        sleep 10
    done

    if type "sudo_search_reindex" > /dev/null 2>&1; then
        sudo_search_reindex
    else
        if [[ -z "${1:-}" || "$1" == "-i" ]]; then
            # Remove -i from args list
            if [[ "${1:-}" == "-i" ]]; then
                shift
            fi
            _get-infra-names "$@"
            reindex_type="infras"
        elif [[ "${1:-}" == "-p" ]]; then
            # Remove -p from args list
            shift
            reindex_type="portals"
        else
            echo "You passed invalid arguments to reindex: $@" >&2
            echo "${HELP[reindex]}" >&2
            exit 1
        fi
        case "${reindex_type}" in
            "infras")
                _reindex-infras;;
            "portals")
                _reindex-portals "$@";;
        esac
    fi
}


function _get-infra-names {
    # Variable infra_names must come from the caller and be of type array.
    local name

    if [[ -f "${INFRA_DIR}/config/dist/_common.dist.toml" ]]; then
        # INFRA_DIR points to an infrastructure directory
        name=$(basename "${INFRA_DIR}")
        infra_names+=("${name}")
    elif [[ -n "${1:-}" ]]; then
        # We passed an infra names as a parameters
        infra_names+=$@
    else
        # Loop over all infras and reindex all.
        for possible_infra_dir in $(ls "${INFRA_DIR}"); do
            if [[ -f "${INFRA_DIR}/${possible_infra_dir}/config/dist/_common.dist.toml" ]]; then
                name=$(basename "${INFRA_DIR}/${possible_infra_dir}")
                infra_names+=("${name}")
            fi
        done
    fi

    if [[ "${#infra_names[@]}" -eq 0 ]]; then
        echo "Found on infrastructure with \$INFRA_DIR=${INFRA_DIR} and params $@"
        return
    fi
}


function _reindex-infras {
    # Variable infra_names must come from the caller and be of type array.
    local infra_name

    for infra_name in "${infra_names[@]}"; do
        local cmd=(sudo /usr/bin/indexer
            --verbose
            --rotate
            --config "/etc/sphinx/${infra_name}.conf"
            --all)
        if [[ "${QUIET}" == "true" ]]; then
            cmd+=("--quiet")
        fi
        "${cmd[@]}"
    done

    restart-service search "$@"
}


function _reindex-portals {
    local indexes=()
    local infra_names=()
    local infra_name

    for portal in "$@"; do
        indexes=()
        infra_name=$(basename $(_get-infra-dir "${portal}"))
        if [[ ! ("${infra_names[@]:-}" =~ "${infra_name}") ]]; then
            infra_names+=("${infra_name}")
        fi
        local cmd=(sudo /usr/bin/indexer
            --verbose
            --rotate
            --config "/etc/sphinx/${infra_name}.conf")
        if [[ "${QUIET}" == "true" ]]; then
            cmd+=("--quiet")
        fi
        _get-indexes "${portal}"
        for index in "${indexes[@]}"; do
            cmd+=("${index}")
        done
        echo "Reindexing ${portal}"
        "${cmd[@]}"
    done

    for infra_name in "${infra_names[@]}"; do
        restart-service search "${infra_name}"
    done
}


function _get-indexes {
    # Variable indexes must come from the caller and be of type array.
    local portal="$1"
    local portal_type='dev'
    local infra_dir=$(_get-infra-dir "${portal}")
    local search_conf_dir="${infra_dir}/${portal_type}/${portal}/search"
    local index

    pushd "${search_conf_dir}"
        # When computing the list of indexes, we need to exclude the {portal}_locations index
        # which is not plain. If we don't, the reindex command will exit with a non zero status
        # code.
        for index in $(grep -E --only-matching --no-filename "^index (${portal}_[^{]+)$" *.conf |
                cut -d ' ' -f 2 |
                grep -v "${portal}_locations"); do
            indexes+=("${index}")
        done
    popd
}


HELP['test-map-files']="manuel test-map-files [TYPE] PORTAL

Test the map files of given type for the specified portal.

**Default values**

- *type* dev"
function test-map-files {
    local portal
    local portal_type
    _set-portal-type "$@"
    local infra_dir=$(_get-infra-dir "${portal}")

    extent=$(cat "${infra_dir}/config/dist/${portal}.dist.toml" |
                    grep '^extent = ' |
                    cut -f 2 -d '=' |
                    sed 's/\"//g; s/\[//g; s/\]//g; s/,//g; s/^ //g')
    # We must use eval for the extent to be 4 numbers as shp2img expects
   shp2img="shp2img -m ${infra_dir}/${portal_type}/${portal}/map/portals/${portal}.map \
            -all_debug 0 \
            -map_debug 1 \
            -s 1920 1080 \
            -e ${extent} \
            -o /tmp/${portal}.png"
    if ! eval "${shp2img}"; then
        echo " ###***### test-map-files FAILED for ${portal_type} ${portal}"
    fi
}


function _set-portal-type {
    # Don't make these variables local. We need them in the parent function (they must be local there).
    if [[ -z "${2:-}" ]]; then
        portal_type=dev
        portal="$1"
    else
        portal_type="$1"; shift
        portal="$1"
    fi
}


function _get-infra-dir {
    # Find the infrastructure directory from a portal name.
    local portal="$1"; shift
    local portal_cfg_file="config/dist/${portal}.dist.toml"
    local infra_dir

    if [[ -f "${INFRA_DIR}/${portal_cfg_file}" ]]; then
        infra_dir="${INFRA_DIR}"
    elif [[ -z "${infra_dir:-}" ]]; then
        for possible_infra_dir in $(ls "${INFRA_DIR}"); do
            if [[ -f "${INFRA_DIR}/${possible_infra_dir}/${portal_cfg_file}" ]]; then
                infra_dir="${INFRA_DIR}/${possible_infra_dir}"
            fi
        done
    fi

    if [[ -z "${infra_dir:-}" ]]; then
        echo "ERROR: Failed to find infra_dir for ${portal} in ${INFRA_DIR}" >&2
        exit 1
    else
        echo "${infra_dir}"
    fi
}


HELP['execute-on-prod']="manuel execute-on-prod CMD

Execute the given command on the production server.

It's possible to run the following commands:

* sudo_apache2_restart
* sudo_search_reindex
* sudo_search_restart
* sudo_tomcat_copyconf
* sudo_tomcat_restart
"
function execute-on-prod {
    ssh "${PROD_USER}@${PROD_HOST}" "$1"
}


HELP['revert']="manuel revert PORTAL

Revert the given portal to the previous release on production."
function revert {
    if [[ -z "$1" ]]; then
        echo "Revert requires a portal name" >&2
        exit 1
    fi

    execute-on-prod "cd \"${PROD_GIT_REPOS_LOCATION}/$1\" && \
        git fetch && \
        git checkout \$(git tag | sort -nr | head -n 2 | tail -n 1)"
}


HELP['reload-features']="manuel reload-features

Ask the API to reload the features."
function reload-features {
    local body
    if ! body=$(curl --netrc -f "${RELOAD_FEATURES_URL}" 2> /dev/null); then
        echo "Reload features failed:" >&2
        echo -e "${body}" >&2
        exit 1
    fi
}


HELP['init-prod-repo']="manuel init-prod-repo PORTAL

Clone the prod repo from the git server (the repo must exists there) and commit a dummy file. The
repo is then clone on the production server."
function init-prod-repo {
    _load-prod-config

    local bare_repo="${PROD_BARE_GIT_REPOS_LOCATION}/$1.git"

    pushd "${INFRA_DIR}/prod/"
        git clone "${bare_repo}"
        cd "$1"
        touch init
        git add -A .
        git commit -m "Init repository"
        git push -u origin master
        execute-on-prod "cd ${PROD_GIT_REPOS_LOCATION} && git clone ${bare_repo}"
    popd
}


HELP['help-update']="manuel help-update

Update help texts and images from the help website from Swisstopo."
function help-update {
    generate --help-update
}


HELP['help-site']="manuel help-site [TYPE] PORTAL

Generate the help website for PORTAL and TYPE.

**Default values**

- *type* dev"
function help-site {
    local portal_type
    local portal
    _set-portal-type "$@"
    local infra_dir=$(_get-infra-dir "${portal}")

    generate --type "${portal_type}" \
        --portal "${portal}" \
        --infra-dir "${infra_dir}" \
        --help-site
}


HELP['verify-sphinx-conf']="manuel verify-sphinx-conf

Check the configuration of sphinx."
function verify-sphinx-conf {
    if ! indextool --checkconfig -c "/etc/sphinx/sphinx.conf" > /dev/null 2>&1; then
        local number_missed_index=$(indextool --checkconfig -c "/etc/sphinx/sphinx.conf" | grep "^missed index(es)" | wc -l)
        if (( ${number_missed_index} == 0 )); then
            indextool --checkconfig -c "/etc/sphinx/sphinx.conf"
            exit 1
        fi
    fi
}


HELP['clean']="manuel clean [TYPE] PORTAL

Clean the generated files for the given type and portal.

**Default Values**

- *type* dev"
function clean {
    local portal_type
    local portal
    _set-portal-type "$@"

    # Leave path unquoted for glob expansion
    rm -rf ${portal_type}/${portal}/*

    pushd "${FRONT_DIR}"
        # Leave path unquoted for glob expansion
        rm -rf ${portal_type}/${portal}/*
        rm -f src/TemplateCacheModule.js
        rm -f src/js/Gf3Plugins.js
        rm -f test/deps
    popd
}


HELP['pushd']="Silent version of builtin pushd"
function pushd {
    command -p pushd "$@" > /dev/null
}


HELP['popd']="Silent version of builtin popd"
function popd {
    command -p popd > /dev/null
}


HELP['vhost']="manuel vhost [TYPE] PORTAL...

Create the vhost files for the given portals.
"
function vhost {
    local portal_type='dev'
    local portal
    local infra_dir
    if [[ "${1:-}" == 'prod' ]]; then
        portal_type=prod
        _load-prod-config
        shift
    elif [[ "${1:-}" == 'dev' ]]; then
        shift
    fi

    for portal in "$@"; do
        infra_dir=$(_get-infra-dir "${portal}")
        generate --type "${portal_type}" \
            --portal "${portal}" \
            --infra-dir "${infra_dir}" \
            --prod-git-repos-location "${PROD_GIT_REPOS_LOCATION:-}" \
            --verbose \
            --vhost
    done

    if [[ "${portal_type}" == "dev" ]] && sudo /usr/sbin/apachectl -t; then
        echo 'restarting apache';
        restart-service apache
    fi
}


function _load-prod-config {
    # When deploying on prod, we must do sync-data once. In order for that to work,
    # we need to have SRC_DATA and DEST_DATA defined once. Hence the hard requirement
    # on INFRA_DIR.
    local customer_config_file="${INFRA_DIR}/config/config.dist.sh"
    local customer_override="${INFRA_DIR}/config/config.sh"

    if [[ ! -f "${customer_config_file}" ]]; then
        echo "Failed to load production configuration: ${INFRA_DIR}/config.dist.sh doesn't exists." >&2
        echo "You may want to set INFRA_DIR in config/config.sh or in your environment to a customer infra dir" >&2
        exit 1
    fi

    _load-customer-config
}


function _load-dev-config {
    local infra_dir=$(_get-infra-dir "${1}")
    local customer_override="${infra_dir}/config/config.sh"
    local customer_config_file="${infra_dir}/config/config.dist.sh"

    _load-customer-config
}


function _load-customer-config {
    # customer_config_file and customer_override must be set
    source config/config.dist.sh
    source config/config.sh 2> /dev/null || echo "INFO: config/config.sh not found"
    source "${customer_config_file}"
    source "${customer_override}" 2> /dev/null || echo "INFO: ${customer_override} not found"

    # Make sure INFRA_DIR does not end with a '/' and is absolute.
    INFRA_DIR="${INFRA_DIR%/}"
    INFRA_DIR=$(realpath "${INFRA_DIR}")
}


HELP['build-doc']="manuel build-doc

Build the doc from the files in docs for all languages. The output will be in docs/_build/html for
English and docs/_build/html/<lang> This doesn't update the po files."
function build-doc {
    local lang

    python3 scripts/get-manuel-doc.py > docs/manuel.md
    pushd "${DOC_DIR}"
        "${SPHINX_CMD}" -b html -d "${DOC_BUILD_DIR}/doctrees" . "${DOC_BUILD_DIR}/html"
        "${SPHINX_INT_CMD}" build
        for lang in "${DOC_LANGUAGES[@]}"; do
            "${SPHINX_CMD}" -b html -d "${DOC_BUILD_DIR}/doctrees" -D language=fr . "${DOC_BUILD_DIR}/html/${lang}"
        done
    popd
}


HELP['update-doc-translations']="manuel update-doc-translations

Update the po files based on text from English documents. This will not build the documentation."
function update-doc-translations {
    local lang

    pushd "${DOC_DIR}"
        echo "Extract strings to translate"
        "${SPHINX_CMD}" -b gettext . locale/pot > /dev/null
        for lang in "${DOC_LANGUAGES[@]}"; do
            echo "Prepare po for ${lang}"
            "${SPHINX_INT_CMD}" update -p locale/pot -l "${lang}" > /dev/null
        done
    popd
}


HELP['build-doc-all']="manuel build-doc-all

This is equivalent to 'manuel clean-doc && manuel update-doc-translations && manuel build-doc'"
function build-doc-all {
    clean-doc && update-doc-translations && build-doc
}


HELP['build-doc-customer']="manuel build-doc-customer

Build the documentation from the files in customer-infra/docs. The output will be in customer-infra/docs/_build/html"
function build-doc-customer {
    local customer_doc_dir="${INFRA_DIR}/docs"

    if [[ ! -d "${customer_doc_dir}" ]]; then
        echo "ERROR: folder ${customer_doc_dir} doesn't exist. Check that INFRA_DIR points to a
specific infra directory and that it contains a doc folder." >&2
        exit 1
    fi

    pushd "${customer_doc_dir}"
        "${SPHINX_CMD}" -b html -d "${DOC_BUILD_DIR}/doctrees" . "${DOC_BUILD_DIR}/html"
    popd
}


HELP['clean-doc']="manuel clean-doc

Remove the built files for the _build folder of the documentation"
function clean-doc {
    pushd "${DOC_DIR}/${DOC_BUILD_DIR}"
        rm -rf html doctrees
    popd
}
