Authentication
==============

.. contents::


How does it work in other products
----------------------------------

GeoMapFish
~~~~~~~~~~

This feature is detailed `here <https://camptocamp.github.io/c2cgeoportal/2.0/developer/webservices.html#authentication>`__ . The developer guide is `here <https://camptocamp.github.io/c2cgeoportal/2.0/developer/index.html>`__ and the page about server development is `here <https://camptocamp.github.io/c2cgeoportal/2.0/developer/server_side.html>`__. We can find this schema of the database model:

.. figure:: /_static/rfc/authentication/geomapfish_database.png
    :scale: 50%
    :align: center

    The database model of GeoMapFish

    *It is not visible on this schema but the ``User`` of a child schema has a link (``parent_role``) to the ``Role`` of the parent schema.*

The features protected by authentication are:

- search (*c2cgeoportal.views.fulltextsearch.py*): searches are handled in the database. The results are filtered like this:

  #. If the user is anonymous, add a filter ``public.is_(True)``
  #. If the user is authenticated, add a filter ``public.is_(True) or role_id == user.role.id``

- tinyowsproxy (*c2cgeoportal.views.tinyowsproxy.py*): if the user is not authenticated, it raises a 403 error. Otherwise, the list of layers the user can edit are fetched and the program checks that the layer the user is trying to edit is among them.
- mapserverproxy (*c2cgeoportal.views.mapserverproxy.py*): to change some requests before forwarding them.
- Features requests (*c2cgeoportal.views.layers.py*): they are protected in reading, creation, deletion and update.

  - Reading: if the layer is public, the results are send to the user. Otherwise, the following filters are applied:

    - Do the roles of user allow him/her to see the layer?
    - Is the layer in the protected area the user is seeing (geometric filter)?

  - Creation: the following filters are applied:

    - Do the roles of user allow him/her to see the layer?
    - Is the layer in the protected area the user is seeing (geometric filter)?
    - Is the layer read/write?

  - Update: same as creation.
  - Deletion: same as creation.

GeoMapFish can also filter ``GetCapabilities`` requests for each user (see *c2cgeoportal.lib.filter_capabilities.py*).

Details
+++++++

URLs
````

#. ``/login`` to connect. You must do a POST request with these parameters: login, password, came_from (URL to which the user must be redirected once logged in).
#. ``/logout`` to disconnect. A mere GET request is enough.
#. ``/loginuser`` to get information about the current user (authenticated or anonymous). A GET request on this URL sends back information about the username, the role and the specific features available.
#. ``/loginchange`` to change the password. A POST request on this URL with the relevant content (password, new_password, confirm_new_password) allows the user to change password.
#. ``/loginresetpassword`` to reset the password.

More details can be found `here <https://camptocamp.github.io/c2cgeoportal/2.0/developer/webservices.html#authentication>`__.

Code
````

In the Python/Pyramid backend, authentication rely on ``AuthTktAuthenticationPolicy`` (requires cookies) or ``BasicAuthAuthenticationPolicy``. These two methods come from Pyramid. It is possible to use both methods thanks to `pyramid_multiauth <https://pypi.python.org/pypi/pyramid_multiauth>`__. The user is then authenticated thanks to the ``User`` table and added to the ``request`` object to make it available to further processing.

`This page <https://camptocamp.github.io/c2cgeoportal/2.0/integrator/authentication.html>`__ gives information and examples to configure another authentication policy (for instance a SSO like CAS) and to validate users from another data source (eg LDAP).

Each user has exactly one role. A role is made of an id, a name, a description, an extent and a relation with features. Each layer and role is mapped with at least one spatial restriction.

The protection of a layer works like this: each layer is mapped to at least one ``RestrictionArea`` with the ``layer_ra`` relation. Each ``RestrictionArea`` is mapped to a role with the ``role_ra`` relation. Each role is mapped to at least one user.

.. note::

    *c2cgeoportal* is not designed to be used directly. It's a template that must be used to create Pyramid applications.


How we can make it work
-----------------------

Main Tables
~~~~~~~~~~~

Ideally these tables should be in a different schema than ``files`` and ``url_shortener`` in order to ease the restoration of those two tables when updating the production database.

.. code:: python

    class Users(Base):
        __tablename__ = 'users'
        __table_args__ = ({'schema': 'api3', 'autoload': False})
        id = Column(BigInteger, primary_key=True)
        username = Column(Text, nullable=False)
        password = Column(String(256))
        email = Column(String(128))

.. code:: python

    class Roles(Base):
        __tablename__ = 'roles'
        __table_args__ = (
            {'schema': 'api3', 'autoload': False},
            UniqueConstraint('name', 'portal', name='role_name'),
        )
        id = Column(BigInteger, primary_key=True)
        name = Column(String(128), nullable=False)
        portal = Column(String(128), nullable=False)
        description = Column(String(255))
        extent = Column(
            Geometry("POLYGON", srid=DEFAULT_SRID),
            doc="Extent on which the view must be set when a user with this roles connect.")

.. code:: python

    class UsersRoles(Base):
        __tablename__ = 'users_roles'
        __table_args__ = ({'schema': 'api3', 'autoload': False})
        uid = Column(BigInteger, primary_key=True)
        rid = Column(BigInteger, primary_key=True)

How to configure the layers?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The configuration of the topics, layers and catalog are loaded in the JSON format from the database with these URLs: ``/<portal>/services``, ``/<portal>/layersConfig?lang=<lang>``, ``/<portal>/catalog?lang=<lang>``. It can work in several ways:

- Build the files for each requests, even for anonymous users. This can be slow.
- Build the files for each requests, even for anonymous users but cache the answer for anonymous users. This way we can avoid reading the database for each request. Swisstopo is doing something similar and it is quite easy.
- Store the files for anonymous users in a dedicated cache table (eg ``public_services``, ``public_layers_config``, ``public_catalog``). Each of these tables has a portal, language and content (in JSON) field. The cache can then be updated with PostgreSQL triggers or in Python.

The administrator has an admin page in ``/admin/layers``. On this interface, it is possible to add, update and delete layers.

The API has the URLs below accessible with POST requests. Each URL allows bulk updates. THe update and deletion can also be done with a specific id.

- ``/admin/layers/create``
- ``/admin/layers/update``
- ``/admin/layers/delete``
- ``/admin/layers/create_or_update``

Since all layers can also be created/updated with the cli, in order to avoid conflicts, each layer must have a special boolean attribute (eg ``auto_filled``). If this field is truethy, then the layer cannot be edited *by default* with the interface. If the user chooses to edit the layer anyway, the field becomes falsey. Then, if the command line tool tries to update a layer with this field being falsey, a warning message is displayed and the layer is not changed.

Database
~~~~~~~~

Layer configuration
+++++++++++++++++++

There are several ways to store the configuration in the database:

- All WMS and WMTS layers in the same table like Swisstopo. See https://github.com/geoadmin/mf-chsdi3/blob/master/chsdi/models/bod.py#L53. Question: how to handle efficiently several languages (without the need to add/remove columns in the table)?
- In the JSON format as described below. Question: how to handle efficiently several languages (without the need to add/remove columns in the table)?

  .. code:: python

     class LayersConfig(Base):
        __tablename__ = 'layers_config'
        __table_args__ = ({'schema': 'api3', 'autoload': False})
        layerBodId = Column('layer_id', Text, primary_key=True)
        configEn = Column(JSON)
        configFr = Column(JSON)
        configDe = Column(JSON)

- By separating WMS and WMTS (and later WFS) layers. To do that, we put each type of layer in its own table. The columns of this table can map exactly to the field required for a layer (c2c is doing this). Since the primary key ``layerBodId`` must be unique across all those tables, we can use a solution detailed `here <http://stackoverflow.com/questions/10068033/postgresql-foreign-key-referencing-primary-keys-of-two-different-tables/10077883#10077883>`__ and use `with_polymorphic <with_polymorphic>`__ in our SQLAlchemy requests (like c2c). In this system, each relevant field is stored in a defined language and translated during JSON export thanks to a data source (in JSON or po files). The validation (are all required fields there?) is also easier: we rely on the database.

Link the role to layers
+++++++++++++++++++++++

We can:

- In the ``Role`` table associate a list of layers in a dedicated column like this: ``authorized_layers = Column(JSON, default='{}')``. The column will then contain for each ``layerBodId`` a subset of ``CRUD`` depending on the permissions of the role on the layer. Question: how to know easily if a layer is protected or not?
- Use (like c2c) intermediary tables: we map each layer to at least one restriction. We map each restriction to at least one role. If a layer is protected, then it is associated with at least a restriction. With joins, we can also easily find which layers are associated to which roles. This should look like (*code samples taken and adapted from c2cgeoportal*):

  .. code:: python

     # association table role <> restriciton area
     role_layer_retrictions = Table(
        'roles_layer_restrictions',
        Base.metadata,
        Column('role_id', BigInteger, ForeignKey('api3' + '.role.id'), primary_key=True),
        Column('restrictionarea_id', BigInteger, ForeignKey('api3' + '.restrictionarea.id'), primary_key=True),
        schema='api3'
     )

  .. code:: python

      # association table layer <> restriciton area
      layers_layer_restrictions = Table(
          'layers_layer_restrictions',
          Base.metadata,
          Column('layer_id', BigInteger, ForeignKey('api3' + '.layer.id'), primary_key=True),
          Column('restrictionarea_id', BigInteger, ForeignKey('api3' + '.restrictionarea.id'), primary_key=True),
          schema='api3'
      )

  .. code:: python

    class LayerRestrictions(Base):
        __tablename__ = 'layer_restrictions'
        __table_args__ = {'schema': 'api3'}

        id = Column(BigInteger, primary_key=True)
        area = Column(Geometry('POLYGON', srid=DEFAULT_SRID))
        name = Column(String(128), nullable=False)
        description = Column(Text)
        read = Column(Boolean, default=True)
        modify = Column(Boolean, default=False, doc='This only makes sense on WFS-T layers')
        attribute_permissions = Column(String(4), doc='Use CRUD to give related permissions on attributes')

        # relationship with Role and Layer
        roles = relationship(
            'Roles',
            secondary=role_layer_retrictions,
            backref='layer_restrictions',
            cascade='save-update,merge,refresh-expire'
        )
        layers = relationship(
            'Layers',
            secondary=layers_layer_restrictions,
            backref='restrictions',
            cascade='save-update,merge,refresh-expire'
        )

Design of the interface
+++++++++++++++++++++++

TODO

Protection of WMS requests
~~~~~~~~~~~~~~~~~~~~~~~~~~

In the layers configuration we send to the user, if a layer is protected, the attribute ``serverLayerName`` is replaced by ``<api-host>/mapproxy``. All the requests coming to that end point are protected. The API checks that the user can do the selected operation on the layer. If so, the API forwards the request to the true server by getting the true ``serverLayerName``. If not, the API responds with 403.

If ``GetCapabilities`` requests must be allowed, we need to build the result from the list of layers the user can interact with.

Features requests
+++++++++++++++++

If we use something like c2c with the small modifications listed above, we just have to filter in mapproxy.

Searches
~~~~~~~~

Layer searches
++++++++++++++

When the TSV files is generated, we add two fields: *public* (boolean) and *allowed_roles*. If the user is not authenticated, we send back everything that is public. If the user is authenticated, we send back everything that is public and that match his/her role.

.. note::

    This implies for the script that create the TSV file to access the database or the API to get this information.

.. note::

    We could also make the script fill the database. That would make indexing easier and more reliable.

Locations
+++++++++

We add two fields: *public* (boolean) and *allowed_roles* in the search view. If the user is not authenticated, we send back everything that is public. If the user is authenticated, we send back everything that is public and that match his/her role.


Opened Questions
----------------

- Should we display the of layers available once authenticated?

  **Proposal:** no.

- How to handle the permalink? Is it a problem if the list of all layers added to the portal (including the ones that requires authentication) is visible (we can always use obfuscated identifiers for protected layers)? How to detect if a layer is protected to propose to the user to log in and see it?

  **Proposal:** the protected layers are handled like any other layers by the permalink. If the user is not authenticated or cannot see the layer, it will be automatically removed by the frontend. If the user is connected and can see the layer, it will be displayed. We let the user not give a permalink with protected layers to anyone. Anyway, the receiver won't be able to do anything with just the name of the layer.

- Print: how can MFP validate a user is authenticated and can access to the layers passed in the print request? Is there a simple way to use the user name already given? Should we use a validation proxy? Should we create a MFP plugin for this?

- Interface: where should we put the connection popup?

  **Proposal:** below the links to change language.

- Should we have an history for the connections? **Yes for security reasons.** Of the layers they accessed?

  **Proposal:** add a table ``ConnectionLog``. Each time a user logs in, a row is added to this table. This row will contain the id, the name and the date of last connection. This table should contain a fixed number of elements or a max conservation time (avoid to hide a wrong connection just by logging many times). Old elements could be collected when a user logs in. We should to the same with ``AccessLog`` if we want to store the access to each layers.

- How to handle translations for protected elements?
