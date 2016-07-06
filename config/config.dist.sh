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


# Rsync options
set-var BWL 84000
set-var DATA_SRC "/var/geoportal/data/"
set-var DATA_DEST "geoportal-demo.local:/var/geoportal/data/"

# To execute rsync commands on a remote shell, uncomment the line below
env | grep -q 'RSYNC_RSH' || export RSYNC_RSH="ssh -l sit_prod"


# Where are the git repos on the production server
set-var PROD_GIT_REPOS_LOCATION "~geoportal/git"
set-var PROD_BARE_GIT_REPOS_LOCATION "https://git.geoportal-demo.local/git/"
set-var PROD_HOST "geoportal-demo"
set-var PROD_USER "sit_prod"
set-var PROD_DEPLOY_BRANCH "prod"


# Mapfish print configuration
set-var MFP_APP_FOLDER "/srv/tomcat/webapps/print/print-apps/"


# Front
set-var FRONT_DIR '../geo-front3/'
set-var DEFAULT_PORTAL 'demo'


# Databsase
set-var DEFAULT_DB_NAME "sit"
set-var DEFAULT_DB_PROD_NAME "sit_prod"
set-var DEFAULT_DB_HOST "localhost"
set-var DEFAULT_DB_SOURCE_HOST "geoportal-demo.local"
set-var DEFAULT_DB_PROD_HOST "prod.geoportal-demo.local"
set-var DEFAULT_DB_DUMP_FILE "/tmp/sit_full.backup"
set-var DEFAULT_DB_API_DUMP_FILE "/tmp/sit_api3.backup"
set-var DEFAULT_DB_SCHEMA_DUMP_FILE "/tmp/schema.sql"
set-var DEFAULT_DB_REPO "~geoportal/geo-db"


# Misc
set-var RELOAD_FEATURES_URL "http://api.geoportal-demo.local/features_reload"
set-var QUIET "false"
## Make sure SSH_CLIENT is set, even without a SSH connection
SSH_CLIENT="${SSH_CLIENT:-localhost}"


# Infra
set-var CUSTOMERS_INFRA_DIR "../"
