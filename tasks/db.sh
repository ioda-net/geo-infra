#!/usr/bin/env bash

function _db-drop {
    psql -h "${host}" -d postgres -U root <<EOF
-- Kill all db connexions
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE datname = '${database}'
  AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS ${database};
EOF
}


function _db-create {
    psql -h "${host}" -d postgres -U root <<EOF
CREATE DATABASE ${database}
  WITH OWNER = sit_dba
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       LC_COLLATE = 'fr_CH.UTF-8'
       LC_CTYPE = 'fr_CH.UTF-8'
       TEMPLATE = template0
       CONNECTION LIMIT = -1;

ALTER DATABASE ${database}
  SET search_path = userdata, public, pg_catalog;
EOF
}


function _db-restore {
    echo "Restoring ${database}"
    # root superuser is needed to recreate extension
    pg_restore -h "${host}" -d "${database}" -U root  --jobs 4 "${backup_file}"
    psql -h "${host}" -d "${database}" -U root  -c "REASSIGN OWNED BY root TO sit_dba;"

    psql -h "${host}" -d "${database}" -U sit_dba --no-password  -c "ALTER DATABASE ${database} SET search_path = userdata, public, postgis, topology, pg_catalog;"

    db-grant-update "${host}" "${database}"
}


HELP['db-grant-update']="manuel db-grant-update [HOST [DATABASE]]

Fix the right for DATABASE on HOST.

**Default values**

- *host* ${DEFAULT_DB_HOST}
- *database* ${DEFAULT_DB_NAME}"
function db-grant-update {
    local host=${1:-${DEFAULT_DB_HOST}}
    local database=${2:-${DEFAULT_DB_NAME}}
    echo "Adjusting rights on ${database}"
    psql -h "${host}" -d "${database}" -U sit_dba --no-password -q -f ./scripts/slq/db-grant-update.sql > /dev/null 2>&1
}


HELP['db-update']="manuel db-update [HOST [DATABASE [BACKUP_FILE]]]

Update DATABASE on HOST from BACKUP_FILE.

**Default values**

- *host* ${DEFAULT_DB_HOST}
- *database* ${DEFAULT_DB_NAME}
- *backup_file* ${DEFAULT_DB_DUMP_FILE}"
function db-update {
    local host=${1:-${DEFAULT_DB_HOST}}
    local database=${2:-${DEFAULT_DB_NAME}}
    local backup_file="${3:-${DEFAULT_DB_DUMP_FILE}}"

    _db-drop

    _db-create

    _db-restore
}


HELP['db-dump']="manuel db-dump [HOST [DATABASE [BACKUP_FILE]]]

Dump DATABASE from HOST to BACKUP_FILE.

**Default values**

- *host* ${DEFAULT_DB_SOURCE_HOST}
- *database* ${DEFAULT_DB_NAME}
- *backup_file* ${DEFAULT_DB_DUMP_FILE}"
function db-dump {
    local host=${1:-${DEFAULT_DB_SOURCE_HOST}}
    local database=${2:-${DEFAULT_DB_NAME}}
    local backup_file="${3:-${DEFAULT_DB_DUMP_FILE}}"

    pg_dump -h "${host}" -U sit_dba \
      --no-password \
      --format custom \
      --blobs \
      --compress 6 \
      --encoding UTF8 \
      --verbose \
      --file "${backup_file}" \
      "${database}"

}


HELP['db-dump-roles']="manuel db-dump-roles [HOST]

Dump the roles know to a pg HOST to STDIN.

**Default values**

- *host* ${DEFAULT_DB_SOURCE_HOST}"
function db-dump-roles {
    local host=${1:-${DEFAULT_DB_SOURCE_HOST}}
    pg_dumpall -h "${host}" -U root --roles-only
}


HELP['db-dev2prod']="manuel db-dev2prod [HOST [DATABASE [BACKUP_FILE [BACKUP_API_FILE]]]]

Deploy the dev database saved in BACKUP_FILE to DATABASE on HOST. Restore the api3 schema from
BACKUP_API_FILE.

**Default values**

- *host* ${DEFAULT_DB_PROD_HOST}
- *database* ${DEFAULT_DB_PROD_NAME}
- *backup_file* ${DEFAULT_DB_DUMP_FILE}
- *backup_api_file* ${DEFAULT_DB_API_DUMP_FILE}"
function db-dev2prod {
    local host=${1:-${DEFAULT_DB_PROD_HOST}}
    local database=${2:-${DEFAULT_DB_PROD_NAME}}
    local backup_file="${3:-${DEFAULT_DB_DUMP_FILE}}"
    local backup_api_file="${4:-${DEFAULT_DB_API_DUMP_FILE}}"

    if [ ! -s "${backup_file}" ]; then
      echo "Dump dev file ${backup_file} empty or missing !"
      exit 1
    fi

    #First we need to backup api3 schema to save the tables there.
    pg_dump -h "${host}" -U sit_dba --no-password -Fc --schema api3 -v -f "${backup_api_file}" ${database}

    _db-drop

    _db-create

    _db-restore

    # Restore api3 table shortcut and files with -c clean option.
    pg_restore --host "${host}" -U sit_dba --no-password --dbname "${database}" -c --jobs 2 "${backup_api_file}"
}

HELP['db-prod-patch']="manuel db-prod-patch [PATCH_FILE [HOST [DATABASE]]]

Update the production database with associated patch

**Default values**

- *patchfile* /var/tmp/patch.sql
- *host* ${DEFAULT_DB_PROD_HOST}
- *database* ${DEFAULT_DB_PROD_NAME}
"
function db-prod-patch {
    local patch_file="${1:-/var/tmp/patch.sql}"
    local host=${2:-${DEFAULT_DB_PROD_HOST}}
    local database=${3:-${DEFAULT_DB_PROD_NAME}}

    if [ ! -s "${patch_file}" ]; then
      echo "Patch file ${patch_file} empty or missing !"
      exit 1
    fi

    # run patch file
    psql --host "${host}" -U sit_dba --no-password --dbname "${database}" -f "${patch_file}"
}


HELP['db-ddl-track']="manuel db-ddl-track

Work with DDL sit_dev database, if any changes is detected from previous state
Download the db schema, and create a new git tag
commit and push to specific repository ( sit/sit_db )

This task is normally run from cron

**Default values**

- *host* ${DEFAULT_DB_SOURCE_HOST}
- *database* ${DEFAULT_DB_NAME}
- *repo* ${DEFAULT_DB_REPO}
- *dump file* ${DEFAULT_DB_SCHEMA_DUMP_FILE}
"
function db-ddl-track {
    local host=${1:-${DEFAULT_DB_SOURCE_HOST}}
    local database=${2:-${DEFAULT_DB_NAME}}
    local repo=${3:-${DEFAULT_DB_REPO}}
    local dump_file=${4:-${DEFAULT_DB_SCHEMA_DUMP_FILE}}

    db_version=$(psql -t --host "${host}" -U "sit_dba" --no-password --dbname "${database}" -c "select * from zzversion order by version DESC limit 1")

    cd "$repo"
    _exit-current-dir-not-git-root

    /usr/bin/pg_dump -h ${host} -U sit_dba --no-password --schema-only --no-owner -f ${repo}/${dump_file} ${database}

    git add -A .

    # If there's nothing to commit, we stop the function here.
    if ! git commit -m "release $(date +"%Y-%m-%d-%H-%M-%S") $db_version" > /dev/null; then
        cd -
        return 0
    fi
    git tag -a -m "release $db_version" $(date +"%Y-%m-%d-%H-%M-%S")
    git push
    git push --tags
    cd -
}
