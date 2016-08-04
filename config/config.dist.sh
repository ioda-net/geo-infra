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
set-var INFRA_DIR "../"
