HELP['test-config-generation']="manuel test-config-generation

Check that the configuration are correctly generated. It relies on the demo portal from
customer-infra (https://github.com/ioda-net/customer-infra)."
function test-config-generation {
    local infra_dir
    local type
    local error_output="/tmp/geo-infra-test-config-stderr"
    local output="/tmp/geo-infra-test-config-stdout"
    local errors=false
    local with_portal
    local dist_only
    local types=('dev' 'prod')
    local dist_types=(true false)
    local portal_types=(true false)
    local generate_config_cmd
    local common_file
    local portal_file

    # Check that we are in customer infra
    if grep -q 'customer-infra$' <<< "${INFRA_DIR}"; then
        infra_dir="${INFRA_DIR}"
    elif [[ -d "${INFRA_DIR}/customer-infra" ]]; then
        infra_dir="${INFRA_DIR}/customer-infra"
    else
        echo "Cannot find customer-infra" >&2
        exit 1
    fi

    # Correct results
    pushd "${TEST_CFG_LOAD_ORDER_RESULTS_DIR}"
        for result_file in *; do
            sed -i "s#@INFRA_DIR@#${infra_dir}#g" "${result_file}"
        done
    popd

    echo "---- Testing configuration ----"
    for type in "${types[@]}"; do
        for dist_only in "${dist_types[@]}"; do
            for with_portal in "${portal_types[@]}"; do
                echo "Testing configuration, type ${type}, dist_only: ${dist_only}, load_portal: ${with_portal}"
                common_file="${infra_dir}/config/${type}/_common.${type}.toml"
                portal_file="${infra_dir}/config/${type}/demo.${type}.toml"
                if "${dist_only}"; then
                    _backup-config-files-test
                else
                    _create-config-files-test
                fi

                generate_config_cmd=(generate --type "${type}"
                    --infra-dir "${infra_dir}"
                    --config
                    --debug)
                if "${with_portal}"; then
                    generate_config_cmd+=(--portal 'demo')
                fi

                "${generate_config_cmd[@]}" > "${output}" 2> "${error_output}"
                _test-config-loaded-files

                if "${dist_only}"; then
                    _restaure-config-files-test
                fi
            done
        done
    done

    # Revert results files
    git checkout "${TEST_CFG_LOAD_ORDER_RESULTS_DIR}"

    if "${errors}"; then
        echo "FAILED" >&2
        exit 1
    else
        echo "SUCCESS"
    fi
}


function _test-config-loaded-files {
    local result_file_name="${type}"
    local diff_output

    if "${with_portal}"; then
        result_file_name="${result_file_name}_portal"
    else
        result_file_name="${result_file_name}_no_portal"
    fi

    if "${dist_only}"; then
        result_file_name="${result_file_name}_dist_only"
    fi

    if ! cmp -s "${error_output}" "${TEST_CFG_LOAD_ORDER_RESULTS_DIR}/${result_file_name}"; then
        echo "FAILURE:" >&2
        diff -u "${error_output}" "${TEST_CFG_LOAD_ORDER_RESULTS_DIR}/${result_file_name}" >&2 || :
        errors=true
    fi
}


function _backup-config-files-test {
    # common_file, portal_file
    if [[ -f "${common_file}" ]]; then
        mv "${common_file}" "${common_file}.bak"
    fi

    if [[ -f "${portal_file}" ]]; then
        mv "${portal_file}" "${portal_file}.bak"
    fi
}


function _restaure-config-files-test {
    # common_file, portal_file
    if [[ -f "${common_file}.bak" ]]; then
        mv "${common_file}.bak" "${common_file}"
    fi

    if [[ -f "${portal_file}.bak" ]]; then
        mv "${portal_file}.bak" "${portal_file}"
    fi
}


function _create-config-files-test {
    # common_file, portal_file
    touch "${common_file}"
    touch "${portal_file}"
}

