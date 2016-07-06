#!/usr/bin/env bash

declare -A HELP_FRONT
HELP_FRONT['build-test-conf']="manuel front build-test-conf

Generate the configuration files for karma and protractor."
HELP_FRONT['test']="manuel front test

Launch the unit tests against the development code."
HELP_FRONT['test-prod']="manuel front test-prod PORTAL

Launch the unit tests against the given portal in production. Don't generate the files.
You may wish to run 'manuel front prod PORTAL' before this."
HELP_FRONT['lint']="manuel front lint

Launch the JS linter for the frontend."
HELP_FRONT['test-integration']="manuel front test-integration

Launch the integration tests for dev. webdriver-manager must be running."
HELP_FRONT['test-integration-prod']="manuel front test-integration-prod PORTAL

Launch the integration tests for prod against PORTAL. You may wish to run 'manuel front prod'
before it. webdriver-manager must be running."
HELP_FRONT['dev']="manuel front dev PORTAL

Generate the given portal for dev."
HELP_FRONT['prod']="manuel front prod PORTAL

Generate the given portal for prod. To generate even with uncommited changes in the frontend, add
the --force option at as first parameter."
HELP_FRONT['watch']="manuel front watch PORTAL

Watch and regenerate the given portal for prod each time a file is modified. Doesn't take into
account modifications made to the index.nunjucks.html file."


HELP['front']="manuel front TASK [PORTAL]

Execute TASK for the frontend. Use:
- 'manuel front list' to list available tasks
- 'manuel front help task' to get help for a given task"
function front {
    local task="$1"; shift
    local force
    if [[ "${1:-}" == "--force" ]]; then
        force="$1"
        shift
    fi
    local portal
    if [[ -n "${1:-}" ]]; then
        portal="$1"; shift
    fi
    local list='Available tasks for front
- build-test-conf
- test
- test-prod
- lint
- test-integration
- test-integration-prod
- dev
- prod
- watch'

    case "${task}" in
        'build-test-conf')
            _build-test-conf;;
        'dev')
            _front-dev;;
        'help')
            [[ -n "${HELP_FRONT[${portal}]}" ]] && echo "${HELP_FRONT[${portal}]}" || echo "No task named ${portal}." >&2;;
        'list')
            echo "${list}";;
        'test-integration')
           _launch-test-integration;;
        'prod')
            _front-prod;;
        'watch')
            _front-watch;;
        *)  # All other tasks execute directly in front directory
            pushd "${FRONT_DIR}"
                _launch-task-in-front-dir
            popd;;
    esac
}


function _launch-task-in-front-dir {
    case "${task}" in
        'lint')
            "${GJSLINT_CMD}" -r src/components src/js --jslint_error=all;;
        'test')
            "${KARMA_CMD}" start test/karma-conf.dev.js --single-run;;
        'test-integration-prod')
            "${PROTRACTOR_CMD}" test/protractor-conf.prod.js \
                       --params.type=prod \
                       --params.portal="${portal:-${DEFAULT_PORTAL}}"|| : ;;
        'test-prod')
            local test_portal="${portal:-${DEFAULT_PORTAL}}"
            output=$("${KARMA_CMD}" start test/karma-conf.prod.js --portal="${test_portal}" --single-run 2>&1) || {
                echo "Tests failed for ${test_portal}" >&2
                echo "${output}"
                return 1
            };;
    esac
}


function _build-test-conf {
    local tmp=$(mktemp -d)

    _build-template-cache
    _build-plugins "dev" ${DEFAULT_PORTAL}
    pushd "${FRONT_DIR}"
        cp -r --parent src/js/*.js \
           src/components/**/*.js \
           src/components/*.js \
           src/TemplateCacheModule.js "${tmp}/"

        "${CLOSUREBUILDER_CMD}" \
                --root="${tmp}" \
                --root=node_modules/google-closure-library \
                --namespace="geoadmin" \
                --namespace="__ga_template_cache__" \
                --output_mode=list |
            tr ' ' '\n' |
            grep -v '\-\-js' |
            sed "s#${tmp}/src/##" |
            awk -v q="'" -v t=',' '{print q $1 q t}' |
            sed 's#node_modules#../node_modules#g' |
            grep -v "''," > test/deps

        rm -f 'test/karma-conf.dev.js'
        rm -f 'test/karma-conf.prod.js'
        rm -f 'test/protractor-conf.dev.js'
        rm -f 'test/protractor-conf.prod.js'
    popd

    render --type 'dev' --test
    render --type 'prod' --test

    rm -rf "${tmp}"
}


function _front-dev {
    local portal_type='dev'
    local infra_dir=$(_get-infra-dir "${portal}")
    local output="${infra_dir}/${portal_type}/${portal}"
    local js_deps_file="${output}/deps.js"
    local style_output="${output}/style"
    local css_file="${style_output}/app.css"

    _build-plugins "${portal_type}" "${portal}"
    _build-index "${portal_type}" "${portal}"

    pushd "${FRONT_DIR}"
        _mkdir "${output}"
        _mkdir "${style_output}"
        _copy-files "${output}"
        _build-deps-js "${js_deps_file}"
        _build-app-css "${css_file}"
    popd
}


function _front-prod {
    local tmp=$(mktemp -d -t geofront3.XXXXXXXXXX)
    local portal_type='prod'
    local infra_dir=$(_get-infra-dir "${portal}")
    local output="${infra_dir}/prod/${portal}"
    local build_js="${output}/lib/build.js"
    local build_closure="${tmp}/build-closure.js"
    local style_output="${output}/style"
    local css_file="${style_output}/app.css"
    local lib_output="${output}/lib"

    pushd "${FRONT_DIR}"
        if ! _work-tree-clean && [[ -z "${force:-}" ]]; then
            echo "Uncommited changes in geo-front3. Exiting."
            exit 1
        fi
        git checkout -q "${PROD_DEPLOY_BRANCH}"
    popd

    _build-plugins "${portal_type}" "${portal}"
    _build-index "${portal_type}" "${portal}"
    _build-template-cache

    pushd "${FRONT_DIR}"
        _mkdir "${output}"
        _mkdir "${style_output}"
        _mkdir "${lib_output}"
        _build-app-css-clean "${css_file}"
        _copy-files-prod "${output}" "${style_output}" "${lib_output}"
        _annotate "${tmp}"
        _compile-closure "${tmp}" "${build_closure}"
        _uglify-libs "${build_js}"
        cat "${build_closure}" >> "${build_js}"
        rm -rf "${tmp}"
    popd
}


function _front-watch {
    # $portal comes from front.

    local portal_type='dev'
    local infra_dir=$(_get-infra-dir "${portal}")
    local output="${infra_dir}/${portal_type}/${portal}"
    local js_deps_file="${output}/deps.js"
    local style_output="${output}/style"
    local css_file="${style_output}/app.css"
    local mapinfra_dir=$(pwd)

    trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

    _build-plugins "${portal_type}" "${portal}"
    _build-index "${portal_type}" "${portal}"

    pushd "${FRONT_DIR}"
        _mkdir "${output}"
        _mkdir "${style_output}"
        _copy-files "${output}"
        _build-deps-js "${js_deps_file}"
        _build-app-css "${css_file}"

        _watch
    popd
}


function _launch-test-integration {
    # Prepare mapinfra
    front dev coverage

    # Launch tests
    pushd "${FRONT_DIR}"

        "${ISTANBUL_CMD}" instrument \
                          -o dev/coverage \
                          -x '*.nunjucks.*' \
                          -x '*.mako*' \
                          -x 'lib/**/*' \
                          --variable '__coverage__' \
                          src

        "${PROTRACTOR_CMD}" test/protractor-conf.dev.js \
                   --params.type=dev \
                   --params.portal="${portal:-coverage}" || :

        "${ISTANBUL_CMD}" report \
                          --include 'coverage/integration/json/**/*.json' \
                          --dir 'coverage/integration' \
                          html
    popd
}
