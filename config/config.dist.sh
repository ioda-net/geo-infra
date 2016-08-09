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

HELP['set-var']="set-var variable_name value

Set the global variable_name to value if variable_name is not an env variable."
function set-var {
    local var="$1"; shift;
    local value="$1"; shift;

    if [[ -n "${var}" && -n "${value}" ]]; then
        env | grep -q "${var}" || eval "${var}='${value}'"
    fi
}


# Commands used to build geo-front3. They must be either absolute (or in the PATH) or relative to
# the geo-front3 directory. Normally, this shouldn't be changed.
set-var KARMA_CMD "./node_modules/karma/bin/karma"
set-var PROTRACTOR_CMD 'protractor'
set-var ISTANBUL_CMD "./node_modules/istanbul/lib/cli.js"
set-var ANNOTATE_CMD "./node_modules/.bin/ng-annotate"
set-var DEPSWRITER_CMD "./node_modules/google-closure-library/closure/bin/build/depswriter.py"
set-var CLOSUREBUILDER_CMD "./node_modules/google-closure-library/closure/bin/build/closurebuilder.py"
set-var GJSLINT_CMD 'gjslint'
set-var CLOSURE_CMD "java -jar node_modules/google-closure-compiler/compiler.jar"
set-var LESSC_CMD "./node_modules/.bin/lessc"
set-var UGLIFY_CMD "./node_modules/.bin/uglifyjs"
set-var RENDER_CMD "./scripts/render.py"
set-var GENERATE_CMD "./scripts/generate.py"


# Pathes
## Keep in sync with global.toml#dest.vhost This is used to know where are the vhosts we have to
## deploy on the production server.
set-var PROD_VHOST_OUTPUT "prod/vhosts.d"
set-var TEST_CFG_LOAD_ORDER_RESULTS_DIR "tasks/tests_results/load_order"
## Location of geo-front3
set-var FRONT_DIR '../geo-front3/'


# MapFish Print configuration
## Where to copy generated MapFish Print applications (directory containing config.yaml, the
## templates and the images).
set-var MFP_APP_FOLDER "/srv/tomcat/webapps/print/print-apps/"
## Where to look for the sources of MapFish Print. Used in 'manuel build-mfp' if no argument is given.
set-var MFP_SOURCE_PATH "../forks/mapfish-print"
## The branch to use to build MapFish Print
set-var MFP_BUILD_BRANCH gf3


# Front
# DEFAULT_PORTAL is used to generate the test configuration with the proper plugins.
set-var DEFAULT_PORTAL 'demo'


# Misc
## If "true", some commands will be less verbose.
set-var QUIET "false"
## Where to search for aliases.
set-var ALIAS_FILE '.aliases'
## Make sure SSH_CLIENT is set, even without a SSH connection.
SSH_CLIENT="${SSH_CLIENT:-localhost}"


# Infra
# INFRA_DIR can point either to a specific infra directory, for instance:
# set-var INFRA_DIR "../geoportal-infras/customer-infra"
# or point to in the folder which contains all the infra directories. For instance:
# set-var INFRA_DIR ".."
set-var INFRA_DIR "../"
