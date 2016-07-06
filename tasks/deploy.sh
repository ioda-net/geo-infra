#!/usr/bin/env bash

HELP['sync-data']="manuel sync-data

Synchronise mapinfra data."
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

    local portal_git_repo="prod/${portal}"

    # Get the id of the current commits
    local current_mapinfra_commit=$(git rev-parse HEAD 2> /dev/null)
    pushd "${FRONT_DIR}"
        local current_front_commit=$(git rev-parse HEAD 2> /dev/null)
    popd

    # Get the id of the last deployed commit from mapinfra and geo-front
    pushd "${portal_git_repo}"
        local previous_tag=$(git tag | sort -nr | head -n 1)
        local previous_mapinfra_commit=$(_get-previous-commit "- mapinfra commit:")
        local previous_front_commit=$(_get-previous-commit "- front commit:")
    popd

    # Get the changelog for mapinfra
    local mapinfra_changelog=''
    if [[ -n "${previous_mapinfra_commit}" ]]; then
        mapinfra_changelog=$(_get-mapinfra-changelog)
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
                      grep -- "$1" |
                      head -n 1 |
                      awk '{print $4}')
    fi
}


function _get-mapinfra-changelog {
    local range="${previous_mapinfra_commit}..${current_mapinfra_commit}"
    echo $(git log "${range}" --oneline |
               grep -v "Merge branch '.*' into")
}


function _get-front-changelog {
    pushd "${FRONT_DIR}"
        local range="${previous_front_commit}..${current_front_commit}"
        echo $(git log "${range}" --oneline --no-merges)
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

- mapinfra commit: ${current_mapinfra_commit}
- front commit: ${current_front_commit}

MAPINFRA CHANGELOG:
${mapinfra_changelog}



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
        if [[ -z "$1" || -z "$2" ]]; then
            echo "You must specify a portal and a type for tomcat-copy-conf to work" >&2
            exit 1
        fi

        local infra_dir=$(_get-infra-dir "$2")
        pushd "${infra_dir}"
            local mfp_portal_dest="${MFP_APP_FOLDER}/$2/"
            if [[ ! -d "${mfp_portal_dest}" ]]; then
                mkdir -p "${mfp_portal_dest}"
            fi

            if [[ -d "$1/$2/print" ]]; then
                /usr/bin/cp -av "$1/$2/print"/* "${mfp_portal_dest}" > /dev/null
            else
                /usr/bin/cp -av print/* "${mfp_portal_dest}" > /dev/null
            fi
        popd
    fi
}


HELP['deploy-global-search-conf']="manuel deploy-global-search-conf

Deploy sphinx global configuration."
function deploy-global-search-conf {
    generate --type "prod" --search-global
    _prod-repo-release "search"
    execute-on-prod "cd \"${PROD_GIT_REPOS_LOCATION}/search\" && \
        git reset --hard && \
        git fetch && \
        git checkout \$(git tag | sort -nr | head -n 1) && \
        $(declare -f restart-service) && \
        $(declare -f reindex) && \
        restart-service search && \
        reindex"
}
