# Manuel
To generate this file, use `python3 scripts/get-manuel-doc.py > docs/manuel.md`

## build-doc
manuel build-doc

Build the doc from the files in docs for all languages. The output will be in docs/_build/html for
English and docs/_build/html/<lang> This doesn't update the po files.


## build-doc-all
manuel build-doc-all

This is equivalent to 'manuel clean-doc && manuel update-doc-translations && manuel build-doc'


## build-doc-customer
manuel build-doc-customer

Build the documentation from the files in customer-infra/docs. The output will be in customer-infra/docs/_build/html


## clean
manuel clean [TYPE] PORTAL

Clean the generated files for the given type and portal.

**Default Values**

- *type* dev


## clean-doc
manuel clean-doc

Remove the built files for the _build folder of the documentation


## config
manuel config [TYPE] PORTAL

Print the configuration for the given type and portal. It will also print the config files that
are parsed in the order they are parsed. To only get the config, redirect error output to /dev/null.
To discard the config, redirect the standard output to /dev/null.

If you have jq installed, you can get any section from the JSON like that:
manuel config demo 2> /dev/null | jq '.mapserver'

**Default values**

- *type* dev


## csvlint
manuel csvlint [PORTAL]

Launch lint for all csv files and report errors.
If portal is given, only the files in the portal infra dir will be linted.
Otherwise, all files in INFRA_DIR are linted.


## db-ddl-track
manuel db-ddl-track [DB_HOST [DB_NAME [REPO [SCHEMA_DUMP_FILE [DB_OWNER]]]]]

Work with DDL database, if any changes is detected from previous state
Download the db schema, and create a new git tag
commit and push to specific repository.

This task is normally run from cron

**Default values**

- *host* \$DEFAULT_DB_SOURCE_HOST
- *database* \$DEFAULT_DB_NAME
- *repo* \$DEFAULT_DB_REPO
- *dump file* \$DEFAULT_DB_SCHEMA_DUMP_FILE
- *db_owner* \$DEFAULT_DB_OWNER



## db-dump
manuel db-dump [HOST [DATABASE [BACKUP_FILE [DB_OWNER]]]]

Dump DATABASE from HOST to BACKUP_FILE.

**Default values**

- *host* \$DEFAULT_DB_SOURCE_HOST
- *database* \$DEFAULT_DB_NAME
- *backup_file* \$DEFAULT_DB_DUMP_FILE
- *db_owner* \$DEFAULT_DB_OWNER


## db-dump-roles
manuel db-dump-roles [HOST [SUPER_USER]]

Dump the roles know to a pg HOST to STDIN.

**Default values**

- *host* \$DEFAULT_DB_SOURCE_HOST


## db-grant-update
manuel db-grant-update [HOST [DATABASE [DB_OWNER]]]

Fix the right for DATABASE on HOST.

**Default values**

- *host* \$DEFAULT_DB_HOST
- *database* \$DEFAULT_DB_NAME
- *db_owner* \$DEFAULT_DB_OWNER


## db-prod-patch
manuel db-prod-patch [PATCH_FILE [HOST [DATABASE [DB_OWNER]]]]

Update the production database with associated patch

**Default values**

- *patchfile* /var/tmp/patch.sql
- *host* \$DEFAULT_DB_PROD_HOST
- *database* \$DEFAULT_DB_PROD_NAME
- *owner* \$DEFAULT_DB_OWNER



## db-update
manuel db-update [HOST [DATABASE [BACKUP_FILE [DB_SUPER_USER [DB_OWNER]]]]]

Update DATABASE on HOST from BACKUP_FILE.

**Default values**

- *host* \$DEFAULT_DB_HOST
- *database* \$DEFAULT_DB_NAME
- *backup_file* \$DEFAULT_DB_DUMP_FILE
- *db_user_user* \$DEFAULT_DB_SUPER_USER
- *db_owner* \$DEFAULT_DB_OWNER


## deploy
manuel deploy PORTAL1 [PORTAL2 [PORTAL3] …]

Generate a production version of the targeted portals and deploy it.


## deploy-global-search-conf
manuel deploy-global-search-conf

Deploy sphinx global configuration.


## deploy-portal
manuel deploy-portal PORTAL

Deploy the given portal on production. Don't build anything.


## deploy-vhost
manuel deploy-vhost [INFRA_DIR]

Deploy the vhost generated in prod/vhost.d to the production server.
**This doesn't generate the vhost for prod.**

You can specify a specific INFRA_DIR. If INFRA_DIR is not specified, it will loop over all the infra directories it finds in INFRA_DIR.


## dev
manuel dev PORTAL1 [PORTAL2 [PORTAL3] …]

Generate a development version of the targeted portals.



## dev-full
manuel dev-full PORTAL1 [PORTAL2 [PORTAL3] …]

Generate a development version of the targeted portals. It will also
triger a reindex for sphinx, test the map files of each portal and copy tomcat configuration.


## execute-on-prod
manuel execute-on-prod CMD

Execute the given command on the production server.

It's possible to run the following commands:

* sudo_apache2_restart
* sudo_search_reindex
* sudo_search_restart
* sudo_tomcat_copyconf
* sudo_tomcat_restart



## front
manuel front TASK [PORTAL]

Execute TASK for the frontend. Use:
- 'manuel front list' to list available tasks
- 'manuel front help task' to get help for a given task


## generate
manuel generate OPTIONS

Wrapper around scripts/generate.py. All the options are passed to the python script. Use
--help for more details.


## generate-global-search-conf
manuel generate-global-search-conf [TYPE] [INFRA_DIR]

Generate the global configuration for sphinx and restart searchd (if type is 'dev').

**Default values**

- *type* dev
- *infra_dir* \$INFRA_DIR


## generate-tests-conf
manuel generate-tests-conf

Generate the configuration for units tests (dev and prod). This is equivalent to:
'manuel front build-test-conf'. DEFAULT_PORTAL must be set.


## help
manuel help TASK

Display the help for TASK.


## help-site
manuel help-site [TYPE] PORTAL

Generate the help website for PORTAL and TYPE.

**Default values**

- *type* dev


## help-update
manuel help-update

Update help texts and images from the help website from Swisstopo.


## init-prod-repo
manuel init-prod-repo PORTAL

Clone the prod repo from the git server (the repo must exists there) and commit a dummy file. The
repo is then clone on the production server.


## jsonlint
manuel jsonlint [PORTAL]

Launch lint for all json files and report errors.
If portal is given, only the files in the portal infra dir will be linted.
Otherwise, all files in INFRA_DIR are linted.


## launch-tests
manuel launch-tests

Launch the unit tests against the development code. This is equivalent to 'manuel front test'


## lint
manuel lint [INFRA_DIR]

Launch lint for all json and csv files and report errors.
If portal is given, only the files in the portal infra dir will be linted.
Otherwise, all files in INFRA_DIR are linted.


## lint-code
manuel lint-code

Launch gslint on the javascript code. This is equivalent to 'manuel front lint'


## popd
Silent version of builtin popd


## prod
manuel prod PORTAL1 [PORTAL2 [PORTAL3] …]

Generate a production version of the targeted portals. To generate even
with uncommitted changes or without changing branch, add the --force option as first parameter.

This task can be launch with portals from different infrastructures if --force is given.


## pushd
Silent version of builtin pushd


## reindex
manuel reindex [INFRA_DIR]

Launch a full reindexation of sphinx.


## reload-apache
manuel reload-apache




## reload-features
manuel reload-features

Ask the API to reload the features.


## render
manuel render OPTIONS

Wrapper around scripts/render.py --front-dir \$FRONT_DIR. All the options are passed to the script.
Use --help for more details.


## restart-service
manuel restart-service SERVICE [INFRAS]

Restart the specified service.

If the service is infrastructure specific, you can pass the list of infras for which it must be restarted.


## revert
manuel revert PORTAL

Revert the given portal to the previous release on production.


## sync-data
manuel sync-data

Synchronise the data.


## test-config-generation
manuel test-config-generation

Check that the configuration are correctly generated. It relies on the demo portal from
customer-infra (https://github.com/ioda-net/customer-infra).


## test-map-files
manuel test-map-files [TYPE] PORTAL

Test the map files of given type for the specified portal.

**Default values**

- *type* dev


## tomcat-copy-conf
manuel tomcat-copy-conf TYPE PORTAL

Copy the generated MFP configuration files into tomcat's MFP directory. Use the
files from TYPE and PORTAL.


## update-doc-translations
manuel update-doc-translations

Update the po files based on text from English documents. This will not build the documentation.


## verify-sphinx-conf
manuel verify-sphinx-conf

Check the configuration of sphinx.


## vhost
manuel vhost [TYPE] PORTAL...

Create the vhost files for the given portals.



## watch
manuel watch PORTAL

Watch and rebuild a portal on change. This is equivalent to 'manuel front watch PORTAL'
