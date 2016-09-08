Edit vectorial layers
=====================

.. contents::

How does it work in other products
----------------------------------

GeoMapFish
~~~~~~~~~~

In the frontend
+++++++++++++++

You can find a demo `here <https://geomapfish-demo.camptocamp.net/1.6/edit>`__ (user: demo, password: demo). The analysis below is based on this demo and the network requests done while testing it.

The layers are write protected and the user must login with a username and a password. After the authentication is done, cookies are created and send to the server for each requests.

.. note::

    According to `the documentation <https://camptocamp.github.io/c2cgeoportal/2.0/administrator/editing.html#enabling-copy-to-functionality>`__ it is possible to copy an object from a layer to another if both layers have the same geometry.

Object Creation
```````````````

To create a new object, the user must choose the type (polygon, line or point) and than draw on the map. When the drawing is done, the user can save it by clicking on the save button. The object is then saved on the server like this:

#. POST request to a URL like ``/layers/<id-layers>``. The cookies are transmitted. The request contains the drawing in the GeoJSON format. The server answers with the same GeoJSON with one key difference: the new object contains an id so the user can edit it.
#. The layer is asked again to MapServer.
#. This display of the layer is updated.

.. figure:: /_static/rfc/layer-edition/geomapfish_create.png
    :align: center

    The dialog to create an object with GeoMapFish

Object Edition
``````````````

To edit an object, the user need to click on it. Once this is done, the object switch to "edition mode". The user can then modify it and the modifications are displayed over the original object with a lighter color (see screenshot below). Once the editing is done, the user must click on the save button. The object is then stored like this:

#. POST request to a URL like ``/layers/<id-layers>/<id-object>``. The cookies are transmitted. The request contains the drawing in the GeoJSON format. The server answers with the same GeoJSON.
#. The layer is asked again to MapServer.
#. This display of the layer is updated.

.. figure:: /_static/rfc/layer-edition/geomapfish_edit.png
    :align: center

    The dialog to edit an object with GeoMapFish

The edition tools contains some advanced features like the possibility to subtract polygons.

Object Deletion
```````````````

To delete an object, the user must click on the object and then select *Actions > Delete*. The deletion occurs like this:

#. DELETE request to a URL like ``/layers/<id-layers>/<id-object>``. The cookies are transmitted.
#. The layer is asked again to MapServer.
#. This display of the layer is updated.

In the backend
++++++++++++++

According to `the documentation <https://camptocamp.github.io/c2cgeoportal/2.0/administrator/tinyows.html>`__, GeoMapFish will act as a proxy between the user and `TinyOWS <http://mapserver.org/tinyows/>`__ in order to check that the user is authenticated and has the right to edit this layer.

The edition feature is more detailed on `this page <https://camptocamp.github.io/c2cgeoportal/2.0/administrator/editing.html>`__. To be editable, a layer must:

- Be accessible in WMS.
- Be associated with a PostGIS table. This table must have a primary key that is incremented automatically when a data is inserted into it (``SERIAL`` or another type with a sequence).
- Be protected: only the users that can edit it must be able to edit it.

There must also be a mapping between the layer and the table (something like what we do with features requests).

QGis Server
~~~~~~~~~~~

`3liz <http://www.3liz.com>`__ has a `demo of layer edition <http://demo.3liz.com/wfst/wfs-transaction-polygon.html>`__. It relies on QGis Server and OpenLayers 2 through `lizmap <http://www.3liz.com/lizmap.html>`__. QGis Server is configured as a WFS-T server and OpenLayers do the proper WFS requests when the user save his/her editions.
