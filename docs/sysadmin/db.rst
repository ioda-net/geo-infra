Database
========

.. contents::

Schemas and functions
---------------------

Users and permissions
---------------------

#. A role for admin tasks: ``geo_dba``:

   .. code:: sql

    CREATE ROLE geo_dba LOGIN
      PASSWORD 'GeoDba'
      SUPERUSER INHERIT CREATEDB NOCREATEROLE NOREPLICATION;
    COMMENT ON ROLE geo_dba IS 'superuser for geoportal';

#. A role for MapServer: ``geo_mapserver``

   .. code:: sql

    CREATE ROLE geo_mapserver LOGIN
      PASSWORD 'GeoMap'
      NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    COMMENT ON ROLE geo_mapserver IS 'geoportal role for mapserver';

#. A role for sphinx search: ``geo_searchd``

   .. code:: sql

    CREATE ROLE geo_searchd LOGIN
      PASSWORD 'GeoSearchd'
      NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    COMMENT ON ROLE geo_searchd IS 'geoportal user for sphinx searchd daemon';

#. A role for the API: ``geo_api``

   .. code:: sql

    CREATE ROLE geo_api LOGIN
      PASSWORD 'GeoApi'
      NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    COMMENT ON ROLE geo_api IS 'geoportal wsgi user';

Each username and password can be changed, it just has to be coherent with the documentation. You can override:

#. ``geo_searchd`` in ``search.sphinx_sql_user`` and ``search.sphinx_sql_pass`` from ``customer-infra/config/_commmon.dist.toml``
#. ``geo_mapserver`` in ``mapserver.PORTAL_DB_USER`` and ``mapserver.PORTAL_DB_PASSWORD`` from ``customer-infra/config/_commmon.dist.toml`` (or directly in your Map files)
#. ``geo_api`` in ``db.host`` from ``geo-api3/config/config.<branchname>.toml``

You set the permissions for each users with ``manuel db-grant-update``. Be sure that the values of ``DEFAULT_DB_OWNER``, ``DEFAULT_DB_MAPSERVER_ROLE``, ``DEFAULT_DB_SEARCH_ROLE``, ``DEFAULT_DB_API_ROLE``, ``DEFAULT_DB_HOST`` and ``DEFAULT_DB_NAME`` in ``customer-infra/config/config.dist.sh`` are correct. You can also run the script below on the proper database (replace ``DEFAULT_DB_OWNER``, ``DEFAULT_DB_MAPSERVER_ROLE``, ``DEFAULT_DB_SEARCH_ROLE``, ``DEFAULT_DB_API_ROLE`` by their correct values):

.. literalinclude:: ../../scripts/sql/db-grant-update.sql
    :language: sql


Features
--------

Search
------
