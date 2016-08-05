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


# Commands
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


# Where are the git repos on the production server
set-var PROD_HOST "demo.geoportal.prod"
set-var PROD_USER "geo_prod"
set-var PROD_GIT_REPOS_LOCATION "~geo_prod/git"
set-var PROD_BARE_GIT_REPOS_LOCATION "https://git.geoportal.prod/git/"
set-var PROD_DEPLOY_BRANCH "devel"


# Rsync options
set-var BWL 84000
set-var DATA_SRC "/var/geoportal/data/"
set-var DATA_DEST "demo.geoportal.prod:/var/geoportal/data/"

# To execute rsync commands on a remote shell, uncomment the line below
# Never used set-var
env | grep -q 'RSYNC_RSH' || export RSYNC_RSH="ssh -l geo_prod"


# Mapfish print configuration
set-var MFP_APP_FOLDER "/srv/tomcat/webapps/print/print-apps/"
set-var MFP_BUILD_BRANCH gf3


# Front
set-var FRONT_DIR '../geo-front3/'
set-var DEFAULT_PORTAL 'demo'


# Databsase
set-var DEFAULT_DB_NAME "geo_dev"
set-var DEFAULT_DB_PROD_NAME "geo_prod"
set-var DEFAULT_DB_HOST "localhost"
set-var DEFAULT_DB_SOURCE_HOST "db.geoportal.local"
set-var DEFAULT_DB_PROD_HOST "db.geoportal.prod"
set-var DEFAULT_DB_DUMP_FILE "/var/tmp/geo_dev_full.backup"
set-var DEFAULT_DB_API_DUMP_FILE "/var/tmp/geo_prod_api3.backup"
set-var DEFAULT_DB_SCHEMA_DUMP_FILE "/var/tmp/geo_dev_schema.sql"
set-var DEFAULT_DB_REPO "~geo_dev/git/geo-db"
set-var DEFAULT_DB_SUPER_USER "root"
set-var DEFAULT_DB_OWNER "geo_dba"


# Misc
set-var RELOAD_FEATURES_URL "http://demo.geoportal.local/api/features_reload"
set-var QUIET "false"
set-var ALIAS_FILE '.aliases'
## Make sure SSH_CLIENT is set, even without a SSH connection
SSH_CLIENT="${SSH_CLIENT:-localhost}"


# Infra
# INFRA_DIR can point either to a specific infra directory, for instance:
# set-var INFRA_DIR "../geoportal-infras/customer-infra"
# or point to in the folder which contains all the infra directories. For instance:
# set-var INFRA_DIR ".."
set-var INFRA_DIR "../"
