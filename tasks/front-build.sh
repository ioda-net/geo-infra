#!/usr/bin/env bash


function _annotate {
    local tmp="$1"; shift;

    _mkdir "${tmp}/src"
    _annotate-file "src/TemplateCacheModule.js" "${tmp}"

    for file in $(find src/components -name '*.js'); do
        _mkdir "${tmp}/${file%/*}"
        _annotate-file "${file}" "${tmp}"
    done

    _mkdir "${tmp}/src/js"
    for file in $(find src/js -name '*.js'); do
        _annotate-file "${file}" "${tmp}"
    done
}


function _annotate-file {
    local file="$1"; shift;
    local output="$1"; shift;

    "${ANNOTATE_CMD}" -a "${file}" > "${output}/${file}"
}


function _copy-files {
    local output="$1"; shift;

    cp -au src/* "${output}/"
}


function _copy-files-prod {
    local output="$1"; shift;
    local style_output="$1"; shift;
    local lib_output="$1"; shift;

    cp -au src/style/ultimate-datatable.css "${style_output}"
    cp -au src/style/font* "${style_output}"
    cp -au src/lib/Cesium "${output}"
    cp -au src/checker "${output}"
    cp -au src/lib/IE "${lib_output}"
    cp -au src/lib/d3.min.js "${lib_output}"
}


function _mkdir {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
    fi
}


function _build-deps-js {
    local output_file="$1"; shift;

    "${DEPSWRITER_CMD}" \
           --root_with_prefix="src/components components" \
           --root_with_prefix="src/js js" > "${output_file}"
}


function _build-app-css {
    local output_file="$1"; shift;
    local errors

    # Filter data uri embedding errors only. Since grep exits with 1 status code if no line matched, we capture the lines in errors and print them if needed.
    # See http://unix.stackexchange.com/questions/122692/redirecting-only-stderr-to-a-pipe and http://burgerbum.com/stderr_pipe.html
    errors=$( "${LESSC_CMD}" --relative-urls src/style/app.less 2> "${output_file}" 3>&1 1>&2 2>&3 | grep -v 'Skipped data-uri embedding' || :)
    if [[ -n "${errors}" ]]; then
        echo "${errors}" >&2
    fi
}


function _build-app-css-clean {
    local output_file="$1"; shift;
    local errors

    # Filter data uri embedding errors only. Since grep exits with 1 status code if no line matched, we capture the lines in errors and print them if needed.
    # See http://unix.stackexchange.com/questions/122692/redirecting-only-stderr-to-a-pipe and http://burgerbum.com/stderr_pipe.html
    errors=$( "${LESSC_CMD}" --relative-urls --clean-css src/style/app.less 2> "${output_file}" 3>&1 1>&2 2>&3 | grep -v 'Skipped data-uri embedding' || :)
    if [[ -n "${errors}" ]]; then
        echo "${errors}" >&2
    fi
}


function _build-index {
    local portal
    local portal_type
    local must_change_dir='false'
    _set-portal-type "$@"

    render --type "${portal_type}" --portal "${portal}" --index
}


function _build-plugins {
    local portal_type
    local portal
    _set-portal-type "$@"

    render --plugins --type "${portal_type}" --portal "${portal}"
}


function _build-template-cache {
    render --template-cache
}


function _build-appcache {
    local portal_type
    local portal
    _set-portal-type "$@"

    render --appcache --type "${portal_type}" --portal "${portal}"
}


function _compile-closure {
    local tmp="$1"; shift;
    local build_closure="$1"; shift;

    js_files=$("${CLOSUREBUILDER_CMD}" \
           --root="${tmp}" \
           --root=node_modules/google-closure-library \
           --namespace="geoadmin" \
           --namespace="__ga_template_cache__" \
           --output_mode=list |
        sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ --js /g' |
        sed -r 's/(.*)/ --js \1/g')
    # eval required to remove quotes around js_files
    eval "${CLOSURE_CMD}" \
         ${js_files} \
         --jscomp_error checkVars \
         --compilation_level SIMPLE \
         --externs externs/ol.js \
         --externs externs/ol3-cesium.js \
         --externs externs/Cesium.externs.js \
         --externs externs/angular.js \
         --externs externs/jquery.js \
         --externs externs/spinner.js \
         --externs externs/slip.js > "${build_closure}"
}


function _uglify-libs {
    local build_js="$1"; shift;
    local libs=( 'src/lib/jquery.js'
                 'src/lib/bootstrap.js'
                 'src/lib/moment-with-customlocales.js'
                 'src/lib/typeahead-0.9.3.js'
                 'src/lib/angular.js'
                 'src/lib/proj4js-compressed.js'
                 'src/lib/EPSG21781.js'
                 'src/lib/EPSG2056.js'
                 'src/lib/EPSG32631.js'
                 'src/lib/EPSG32632.js'
                 'src/lib/ol3.js'
                 'src/lib/spin.js'
                 'src/lib/slip.js'
                 'src/lib/polyfill.js'
                 'src/lib/angular-translate.js'
                 'src/lib/angular-translate-loader-static-files.js'
                 'src/lib/ultimate-datatable.js'
                 'src/lib/fastclick.js'
                 'src/lib/localforage.js'
                 'src/lib/filesaver.js' )

    echo > "${build_js}"
    for lib in ${libs[@]}; do
         "${UGLIFY_CMD}" "${lib}" >> "${build_js}"
         echo >> "${build_js}"
    done
}


function _watch {
    # This function relies on the variable defined in _front-watch

    while true; do
        changed=$(inotifywait -r -e close_write,moved_to,create "$(pwd)/src" | awk '{print $3}')

        if [[ "${changed}" == *.nunjucks.html ]]; then
            echo "$(date) Rebuilding indexes"
            pushd "${mapinfra_dir}"
                _build-index "${portal_type}" "${portal}"
            popd
        elif [[ "${changed}" == *.less ]]; then
            echo "$(date) Rebuilding app.css"
            _build-app-css "${css_file}"
        elif [[ "${changed}" == *.js ]]; then
            echo "$(date) Rebuilding deps"
            _build-deps-js "${js_deps_file}"
            _copy-files "${output}"
        else
            echo "$(date) Copy files"
            _copy-files "${output}"
        fi
    done
}


function build-mfp {
    local path2mf="${1:-../forks/mapfish-print}"
    local mapinfra_dir="$(pwd)"
    local patchesdir="${mapinfra_dir}/patches"
    local mapinfra_print_dir="${mapinfra_dir}/in/print"
    local output_dir="core/build/libs/"

    pushd "${path2mf}"
        rm -rf ${output_dir}/*.war
        git checkout gf3

        for mfp_patch in $patchesdir/mfp-*; do
            patch -p1 < "${mfp_patch}"
        done

        echo "Building MFP"
        ./gradlew clean > /dev/null 2>&1
        ./gradlew build > /dev/null 2>&1 || :
        echo "Done building"

        mkdir print
        mv ${output_dir}/*.war print
        pushd print
            unzip -q *.war
            rm -rf *.war
            rm -rf print-apps

            zip -q -r print.war *

            mv print.war "${mapinfra_print_dir}"
        popd

        git reset -q --hard
        rm -rf print
    popd
}

