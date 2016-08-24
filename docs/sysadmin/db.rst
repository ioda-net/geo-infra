Database
========

.. contents::

Schemas and functions
---------------------

In order for the API to work properly, some functions and schemas detailed below are required.

Functions
~~~~~~~~~

In order for the API to work correctly, two functions are needed:

- ``remove_accents`` to remove all accents from strings when indexing the search string.
- ``quadindex`` to calculate the quadindex for a geometry. This is used to filter search results.

You can find the code below and in the `functions.sql script <https://github.com/ioda-net/geo-infra/blob/master/scripts/sql/functions.sql>`__:

.. literalinclude:: ../../scripts/sql/functions.sql
  :language: postgresql
  :start-after: -- remove_accents function
  :end-before: -- end remove_accents function

.. literalinclude:: ../../scripts/sql/functions.sql
  :language: postgresql
  :start-after: -- quadindex function
  :end-before: -- end quadindex function


Schemas
~~~~~~~

In order for the API to work correctly, you will need the following schemas:

- ``api3``: used by the API to store the shorten links and the id, type and access time of drawings. It must contains two tables:

  #. ``url_shortener``

     .. literalinclude:: ../../scripts/sql/api3_schema.sql
      :language: postgresql
      :start-after: -- start api3_url_shortener table
      :end-before: -- end api3_url_shortener table

  #. ``files``

     .. literalinclude:: ../../scripts/sql/api3_schema.sql
      :language: postgresql
      :start-after: -- start api3_files table
      :end-before: -- end api3_files table

- ``features``: used by the API to make features request. It must at least contain the ``map_layers_features`` table described below. See the `features`_ section of this document to learn more.

  .. literalinclude:: ../../scripts/sql/features_schema.sql
    :language: postgresql
    :start-after: -- start features_map_layers_features table
    :end-before: -- end features_map_layers_features table

We also advise you to create the schemas below:

- ``search`` to contain all tables/views used by sphinx to create its indexes. Instead of using custom SQL in your ``portal-locations.in.conf``, you can create views with the corrected columns:

   - ``id``
   - ``search_label``: this will be displayed to the user in the frontend. It can be the union of multiple columns from the table.
   - ``search_string``: this will be parsed by sphinx. It can be the union of multiple columns from the table.
   - ``geom_st_box2d``: this will be used by the frontend to center the user on the returned geometry. **This must be in the main EPSG of the portal.**. It can be defined as ``box2d(the_geom) AS geom_st_box2d``.
   - ``y``: this will be used by the frontend to put a marker on the searched location. **This must be in the main EPSG of the portal.** It can be defined as ``st_x(the_geom) AS y``.
   - ``x``: this will be used by the frontend to put a marker on the searched location.  **This must be in the main EPSG of the portal.** It can be defined as ``st_y(the_geom) AS x``.
   - ``lat``: the latitude of the searched location. It can be defined as ``st_y(st_transform(the_geom, 4326)) AS lat``.
   - ``lon``: the longitude of the searched location. It can be defined as ``st_x(st_transform(the_geom, 4326)) AS lon``.
   - ``geom_quadindex``: it can be used to filter the results. It can be defined as ``quadindex(the_geom) AS geom_quadindex``
   - ``weight``: how to sort the results. Results with lower weights will come first. It can be defined as ``row_number() OVER (ORDER BY id) AS weight``.

Users and permissions
---------------------

In order to give only the permissions on the database needed by the different components, we suggest that you create the users below:

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

You set the permissions for each users with ``manuel db-grant-update``. Be sure that the values of ``DEFAULT_DB_OWNER``, ``DEFAULT_DB_MAPSERVER_ROLE``, ``DEFAULT_DB_SEARCH_ROLE``, ``DEFAULT_DB_API_ROLE``, ``DEFAULT_DB_HOST`` and ``DEFAULT_DB_NAME`` in ``customer-infra/config/config.dist.sh`` are correct. To override some values only temporarily, use ``manuel help db-grant-update`` to the what arguments are available for this task. You can also run the script below on the proper database (replace ``DEFAULT_DB_OWNER``, ``DEFAULT_DB_MAPSERVER_ROLE``, ``DEFAULT_DB_SEARCH_ROLE``, ``DEFAULT_DB_API_ROLE`` by their correct values):

.. literalinclude:: ../../scripts/sql/db-grant-update.sql
    :language: sql


Features
--------

The point of the ``features.map_layers_features`` table is to map the name of each feature view to the portal for which it is active and the layers for which it should be interrogated. Thanks to this mapping, the API can then auto-load all the feature views and create the appropriate Python classes for interrogation automatically. This allows us not to explicitly declare them in a Python file. This means, you can modify these views as you like (adding and removing columns) without needing to bother about the code of API.

.. attention::

  After you add or remove columns, you must ask the API to reload the views by doing in ``geo-infra``:

  .. code:: bash

    manuel reload-features

These views will then be used in identify requests. These requests contain:

- The name of the portal and the name of a layer. This allows us to select the appropriate views for a request.
- A geometry that will be intersected with the one of the feature to find only the relevant features for this request.

We then return a JSON representation of the row.

In order to work as expected, all the views must contain:

- a column named ``the_geom`` containing the geometry of the feature.
- a column named ``gid`` that can be used as a primary key.
- columns you want to return in the identify request. For instance: ``name``, ``type``. We rely on some convention to automatically render some columns. See `the page about features <GetFeatures.html#special-columns-for-features>`__ from the user manual to learn more about this.
