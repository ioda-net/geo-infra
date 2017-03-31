Configure a WFS-T server for layer edition
==========================================

We don't detail here how to configure a specific WFS-T server. We only give details on how to configure a WFS-T server so it will integrate correctly with ``geo-front3``. If you want a WFS-T server, you can use:

- `GeoServer <http://geoserver.org/>`__ a complete Java based OWS server that supports WFS-T (1.0.0, 1.1.0 and 2.0.0).
- `QGis Server <http://qgis.org/en/site/>`__ a C++ based OWS server that supports WFS-T (1.0.0).
- `TinyOWS <http://mapserver.org/tinyows/index.html>`__ a C based WFS server from the MapServer suite that supports WFS-T (1.0.0).

We currently assume that anyone with read access to the portal has read access to the editable WFS layers. User may authenticate themselves with HTTP Basic Authentication for POST requests if you want to. See :ref:`ref_user_cfg-portal_layers-external-sources` to learn how to configure the layers so the users are asked for id before editing it.

.. contents::


Enable authentication on the server
-----------------------------------

To allow only GET and OPTIONS requests for anonymous users, you need to add in your Apache configuration something like:

.. code:: Apache

    AuthType basic
    AuthName "Restricted area"
    AuthUserFile /var/www/passwd
    Require valid-user
    # Only GET and OPTIONS request are allowed without authentication.
    <Limit GET OPTIONS>
        Require all granted
    </Limit>

If you want to force a WFS-T server to be in read only mode, you can reject the POST requests like this:

.. code:: Apache

    Rewrite %{REQUEST_METHOD} POST
    RewriteRule .* - [R=403,F,NC,L]

You should also be able to configure the WFS-T server to prevent the edition of a layer.


CORS
----

If your WFS-T server is on another domain than your geoportal, you need to enable CORS requests with authentication support. You can do it like this:

.. code:: Apache

   SetEnvIf Origin "http(s)?://(.+)$" CORS=$0
   Header always set Access-Control-Allow-Origin %{CORS}e env=CORS
   Header always set Access-Control-Allow-Methods "POST, GET, OPTIONS"
   Header always set Access-Control-Allow-Credentials "true"
   Header always set Access-Control-Allow-Headers "Authorization,DNT,User-Agent,Keep-Alive,Content-Type,accept,origin,X-Requested-With"
