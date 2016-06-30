# Rsync options
set-var DATA_SRC "/run/media/jenselme/WDATA/sigeom/mapinfra/data/"
set-var DATA_DEST "/run/media/jenselme/WDATA/sigeom/mapinfra/data/"

# To execute rsync commands on a remote shell, uncomment the line below
# env | grep -q 'RSYNC_RSH' || RSYNC_RSH="ssh -l sit_prod"
export RSYNC_RSH=""


# Where are the git repos on the production server
set-var PROD_GIT_REPOS_LOCATION "/home/jenselme/prod"
set-var PROD_BARE_GIT_REPOS_LOCATION "http://git.geofedora/git"
set-var PROD_HOST "geofedora"
set-var PROD_USER "jenselme"
set-var PROD_DEPLOY_BRANCH "devel"


# Mapfish print configuration
set-var MFP_APP_FOLDER "/usr/share/tomcat/webapps/print/print-apps"


# Misc
set-var RELOAD_FEATURES_URL "http://api.geofedora/features_reload"
