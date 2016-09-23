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

HELP['sync-data']="manuel sync-data

Synchronise the data."
function sync-data {
    if [[ -d "${DATA_SRC}" ]] && [[ -n "${DATA_DEST}" ]]; then
        rsync --stats -avh -P --no-o --no-g --delete --bwlimit="${BWL}" "${DATA_SRC}" "${DATA_DEST}"
    else
        echo "Source '${DATA_SRC}' or '${DATA_DEST}' is empty. Not synching data." >&2
        exit 1
    fi
}


HELP['deploy-portal']="manuel deploy-portal PORTAL

Deploy the given portal on production. Don't build anything."
function deploy-portal {
    _prod-repo-release "$1"
    _update-prod-repos "$1"
}


function _prod-repo-release {
    # Takes one argument, the portal name.
    local portal="$1"; shift;
    local infra_dir=$(_get-infra-dir "${portal}")
    local portal_git_repo="${infra_dir}/prod/${portal}"

    # Get the id of the current commits
    local current_geo_infra_commit=$(git rev-parse HEAD 2> /dev/null)
    pushd "${FRONT_DIR}"
        local current_front_commit=$(git rev-parse HEAD 2> /dev/null)
    popd

    # Get the id of the last deployed commit from geo-infra and geo-front
    pushd "${portal_git_repo}"
        local previous_tag=$(git tag | sort -nr | head -n 1)
        local previous_geo_infra_commit=$(_get-previous-commit "- (.+)infra commit:")
        local previous_front_commit=$(_get-previous-commit "- front commit:")
    popd

    # Get the changelog for geo-infra
    local geo_infra_changelog=''
    if [[ -n "${previous_geo_infra_commit}" ]]; then
        geo_infra_changelog=$(_get-geo-infra-changelog)
    fi

    # Get the changelog for front & updates from Swisstopo

    local front_changelog=''
    local front_update_from_swisstopo=''
    if [[ -n "${previous_front_commit}" ]]; then
        front_changelog=$(_get-front-changelog)
        front_update_from_swisstopo=$(_get-update-from-swisstopo)
    fi

    pushd "${portal_git_repo}"
        _commit-new-front
    popd
}


function _get-previous-commit {
    if [[ -z "${previous_tag}" ]]; then
        # First push, no changelog
        echo ""
    else
        echo $(git show "${previous_tag}" |
                      grep -E -- "$1" |
                      head -n 1 |
                      awk '{print $4}')
    fi
}


function _get-geo-infra-changelog {
    local range="${previous_geo_infra_commit}..${current_geo_infra_commit}"
    echo "$(git log "${range}" --oneline |
               grep -v "Merge branch '.*' into")"
}


function _get-front-changelog {
    pushd "${FRONT_DIR}"
        local range="${previous_front_commit}..${current_front_commit}"
        echo "$(git log "${range}" --oneline --no-merges)"
    popd
}


function _get-update-from-swisstopo {
    local front_update_from_swisstopo=''
    pushd "${FRONT_DIR}"
        local range="${previous_front_commit}..${current_front_commit}"
        # Get the update list from Swisstopo
        local changes
        for merge_commit in $(git log "${range}" --oneline |
                                     grep "Merge branch 'master' into" |
                                     awk '{print $1}'); do
            changes=$(git log "${merge_commit}" -1 --pretty=format:"%B" |
                             tail -n +3)
            front_update_from_swisstopo="${front_update_from_swisstopo}${changes}"
        done
    popd

    echo "${front_update_from_swisstopo}"
}


function _commit-new-front {
    _exit-current-dir-not-git-root

    echo "Commiting modifications"
    git add -A . &> /dev/null
    local commit_message="release ${portal} $(date +"%Y-%m-%d-%H-%M-%S") by ${USER} on ${HOSTNAME}  from ${SSH_CLIENT}

- geo-infra commit: ${current_geo_infra_commit}
- front commit: ${current_front_commit}

GEO-INFRA CHANGELOG:
${geo_infra_changelog}



FRONT CHANGELOG:
${front_changelog}


UPDATES FROM SWISSTOPO:
${front_update_from_swisstopo}"

    # If there's nothing to commit, we stop the function here.
    if ! git commit -m "${commit_message}" > /dev/null; then
        echo "Nothing changed on repo $(pwd)."
    else
        local tag_message="${USER} ${HOSTNAME} ${SSH_CLIENT}"
        git tag -a -m "${tag_message}" $(date +"%Y-%m-%d-%H-%M-%S") &> /dev/null

        echo "Pushing updated repo"
        git push --quiet
        git push --tags --quiet
    fi
}


function _exit-current-dir-not-git-root {
    if ! [[ $(git rev-parse --show-toplevel) -ef $(pwd) ]]; then
        echo "ERROR: $(pwd) is not a git repository. Exiting." >&2
        exit 2
    fi
}


function _update-prod-repos {
    execute-on-prod "export MFP_APP_FOLDER=\"${MFP_APP_FOLDER}\" && \
        export CP_CMD=\"${CP_CMD}\" && \
        $(declare -f tomcat-copy-conf) && \
        cd ${PROD_GIT_REPOS_LOCATION}/$1 && \
        echo \"Updating remote repo with new version\" && \
        git reset --hard --quiet && \
        git fetch --quiet && \
        git checkout \$(git tag | sort -nr | head -n 1) --quiet && \
        echo \"Copy tomcat's configuration\" && \
        tomcat-copy-conf 'prod' \"$1\""
}


function _work-tree-clean {
    local git_status_output=$(git status --porcelain)
    if [ -z "${git_status_output}" ] ; then
        return 0
    else
        return 1
    fi
}


HELP['tomcat-copy-conf']="manuel tomcat-copy-conf TYPE PORTAL

Copy the generated MFP configuration files into tomcat's MFP directory. Use the
files from TYPE and PORTAL."
function tomcat-copy-conf {
    if type sudo_tomcat_copyconf > /dev/null 2>&1; then
        sudo_tomcat_copyconf "$2"
    else
        if [[ -z "${1:-}" || -z "${2:-}" ]]; then
            echo "You must specify a portal and a type for tomcat-copy-conf to work" >&2
            exit 1
        fi

        local type="$1"; shift
        local portal="$1"; shift

        local mfp_portal_dest="${MFP_APP_FOLDER}/${portal}/"
        if [[ ! -d "${mfp_portal_dest}" ]]; then
            mkdir -p "${mfp_portal_dest}"
        fi

        if [[ "${type}" == "prod" ]]; then
            if [[ -d "${infra_dir}/${type}/${portal}/print" ]]; then
                "${CP_CMD}" -av ${type}/${portal}/print/* "${mfp_portal_dest}" > /dev/null
            else
                "${CP_CMD}" -av print/* "${mfp_portal_dest}" > /dev/null
            fi
        else
            local infra_dir=$(_get-infra-dir "${portal}")
            if [[ -d "${infra_dir}/${type}/${portal}/print" ]]; then
                "${CP_CMD}" -av "${infra_dir}/${type}/${portal}/print"/* "${mfp_portal_dest}" > /dev/null
            else
                "${CP_CMD}" -av print/* "${mfp_portal_dest}" > /dev/null
            fi
        fi
    fi
}


HELP['deploy-global-search-conf']="manuel deploy-global-search-conf

Deploy sphinx global configuration."
function deploy-global-search-conf {
    _load-prod-config

    generate-global-search-conf "prod"
    pushd "${INFRA_DIR}/prod/search"
        local message="release search $(date +"%Y-%m-%d-%H-%M-%S")"
        git add -A .
        if git ci -am "${message}"; then
            git tag -a -m "${message}" $(date +"%Y-%m-%d-%H-%M-%S")
            git push
            git push --tags
        fi
    popd

    execute-on-prod "cd \"${PROD_GIT_REPOS_LOCATION}/search\" && \
        git reset --hard && \
        git fetch && \
        git checkout \$(git tag | sort -nr | head -n 1) && \
        $(declare -f restart-service) && \
        $(declare -f reindex) && \
        restart-service search && \
        reindex"
}


HELP['reload-apache']="manuel reload-apache

"
function reload-apache {
    local prod_cmd="sudo_apache_reload"

    if type "${prod_cmd}" > /dev/null 2>&1; then
        "${prod_cmd}"
    elif sudo /usr/sbin/apachectl -t; then
        if [[ -e '/usr/lib/systemd/system/httpd.service' ]]; then
            sudo "${SYSTEMCTL_CMD}" reload httpd.service
        else
            sudo "${SYSTEMCTL_CMD}" reload apache2.service
        fi
    fi
}


HELP['deploy-vhost']="manuel deploy-vhost [INFRA_DIR]

Deploy the vhost generated in prod/vhost.d to the production server.
**This doesn't generate the vhost for prod.**

You can specify a specific INFRA_DIR. If INFRA_DIR is not specified, it will loop over all the infra directories it finds in INFRA_DIR."
function deploy-vhost {
    _load-prod-config

    local infra_dir="${1:-}"
    local possible_infra_dir
    local vhost_dir
    local repos_to_deploy=()
    local commit_message

    if [[ -n "${infra_dir}" && -d "${INFRA_DIR}/${infra_dir}/${PROD_VHOST_OUTPUT}" ]]; then
        repos_to_deploy+=("${INFRA_DIR}/${infra_dir}/${PROD_VHOST_OUTPUT}")
    elif [[ -d "${INFRA_DIR}/${PROD_VHOST_OUTPUT}" ]]; then
        repos_to_deploy+=("${INFRA_DIR}/${PROD_VHOST_OUTPUT}")
    else
        for possible_infra_dir in $(ls "${INFRA_DIR}"); do
            if [[ -d "${INFRA_DIR}/${possible_infra_dir}/${PROD_VHOST_OUTPUT}" ]]; then
                repos_to_deploy+=("${INFRA_DIR}/${possible_infra_dir}/${PROD_VHOST_OUTPUT}")
            else
                echo "No vhost to deploy in ${INFRA_DIR}/${possible_infra_dir}"
            fi
        done
    fi

    # Exit now if no vhosts, exit here:
    if [[ "${#repos_to_deploy[@]}" -eq 0 ]]; then
        echo "Found no vhosts to deploy."
        return
    fi

    for vhost_dir in "${repos_to_deploy[@]}"; do
        pushd "${vhost_dir}"
            echo "Deploying vhosts for ${vhost_dir}"
            _exit-current-dir-not-git-root
            git add -A .
            commit_message="Update production vhost $(date +"%Y-%m-%d-%H-%M-%S")

    Added:
$(git diff --name-only --diff-filter=A --cached)

    Modified:
$(git diff --name-only --diff-filter=M --cached)"
            if ! git commit -am "${commit_message}"; then
                echo "Nothing to commit in $(pwd)"
                echo "Continuing."
                continue
            fi
            git tag -a -m "Release production vhost $(date +"%Y-%m-%d-%H-%M-%S")" $(date +"%Y-%m-%d-%H-%M-%S")

            git push
            git push --tags
            execute-on-prod "cd \"${PROD_GIT_REPOS_LOCATION}/vhosts.d\" && \
                git reset --hard && \
                git fetch && \
                git checkout \$(git tag | sort -nr | head -n 1) && \
                $(declare -f reload-apache) && \
                reload-apache"
            echo "Done"
        popd
    done
}

