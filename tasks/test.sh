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
    local global_dist_file="config/global.toml"
    local common_dist_file
    local portal_dist_file
    local template_dist_file
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

    common_dist_file="${infra_dir}/config/dist/_common.dist.toml"
    portal_dist_file="${infra_dir}/config/dist/demo.dist.toml"
    template_dist_file="${infra_dir}/config/_template.dist.toml"

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

    if "${errors}"; then
        echo "FAILED" >&2
        exit 1
    else
        echo "SUCCESS"
    fi
}


function _test-config-loaded-files {
    # portal_file, portal_dist_file, common_dist_file, global_dist_file, common_file,
    # error_output, dist_only, with_portal and errors must be set.
    local n=1

    # Test global.toml
    grep -q "Loaded config file: ${global_dist_file}$" <<< $(cut -f$n -d$'\n' "${error_output}") || {
        echo "FAILURE: ${global_dist_file} not loaded" >&2
        errors=true
    }
    let "n++"

    # Test common.dist.toml
    grep -q "Loaded config file: ${common_dist_file}$" <<< $(cut -f$n -d$'\n' "${error_output}") || {
        echo "FAILURE: ${common_dist_file} not loaded" >&2
        errors=true
    }
    let "n++"

    # Test portal.dist.toml
    if "${with_portal}"; then
        grep -q "Loaded config file: ${portal_dist_file}$" <<< $(cut -f$n -d$'\n' "${error_output}") || {
            echo "FAILURE: ${portal_dist_file} not loaded" >&2
            errors=true
        }
        let "n++"

        grep -q "Loaded template file: ${template_dist_file} (template, values not loaded)$" <<< $(cut -f$n -d$'\n' "${error_output}") || {
            echo "FAILURE: ${template_dist_file} not loaded" >&2
            errors=true
        }
        let "n++"
    fi

    # Test common.type.toml
    if "${dist_only}"; then
        grep -q "Config file not found: ${common_file}$" <<< $(cut -f$n -d$'\n' "${error_output}") || {
            echo "FAILURE: ${common_file} was loaded. Expected not found." >&2
            errors=true
        }
    else
        grep -q "Loaded config file: ${common_file}$" <<< $(cut -f$n -d$'\n' "${error_output}") || {
            echo "FAILURE: ${common_file} not loaded" >&2
            errors=true
        }
    fi
    let "n++"

    # Test portal.type.toml
    if "${with_portal}"; then
        if "${dist_only}"; then
            grep -q "Config file not found: ${portal_file}$" <<< $(cut -f$n -d$'\n' "${error_output}") || {
                echo "FAILURE: ${portal_file}$ was loaded. Expected not found." >&2
                errors=true
            }
        else
            grep -q "Loaded config file: ${portal_file}$" <<< $(cut -f$n -d$'\n' "${error_output}") || {
                echo "FAILURE: ${portal_file} not loaded" >&2
                errors=true
            }
        fi
        let "n++"
    fi

    # Since we increment n after each test, it should be higher than the number of lines.
    # We correct this.
    let "n--"
    local number_lines=$(cat "${error_output}" | wc -l)
    if [[ "$n" -ne "${number_lines}" ]]; then
        echo "FAILURE: untested lines in ${error_output}. Stopped at ${n}/${number_lines}." >&2
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

