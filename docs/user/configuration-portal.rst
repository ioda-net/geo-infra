Configuration of a portal
=========================

.. contents::


.. _ref_user_cfg-portal_layers-external-sources:

Layers from external sources
----------------------------

In ``customer-infra/json/<portal_name>/external``, you can add JSON files describing layers from external WMS or WMTS servers. These files must have the following attributes:

- name
- resolutions (WMTS only)
- timeEnabled (WMTS only)
- timestamps (WMTS only)
- type
- wmsUrl (WMS only)
- matrixSet (WMTS only)

They can have the following optional attributes:

- label (default: name)
- attribution (default: empty)
- attributionUrl (default: empty)
- hasLegend (default: false)
- legend (default: empty)
- format (default: png)
- opacity (default: 1)
- queryable (default: false)
- serverLayerName (default: name)
- wmsLayers (default: name, WMS only)
- crossOrigin: (default: null, possible: ``"undefined"`` WMS only). If the value is set to ``"undefined"``, this will force OpenLayers to discard cross origin information. This can be useful when you import an external WMS layer and encounter cross origin problems.
- background (default: false)
- timeBehaviour (default: last, WMTS only)

Example JSON file for external WMS layer
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: json

   {
       "name": "UP5",
       "label": "UP5",
       "attribution": "Berne",
       "attributionUrl": "http://www.geoservice.apps.be.ch",
       "background": true,
       "hasLegend": false,
       "legendUrl": "",
       "format": "png",
       "type": "wms",
       "opacity": 0,
       "queryable": false,
       "serverLayerName": "UP5",
       "wmsLayers": "GEODB.UP5_SITU5_MOSAIC",
       "wmsUrl": "//www.geoservice.apps.be.ch/geoservice/services/a4p/a4p_basiswms_d_fk_s/MapServer/WMSServer?"
   }

Example JSON file for external WMTS layer
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: json

   {
       "name": "ch.swisstopo.swissimage",
       "label": "Orthophotos",
       "attribution": "CNES, Spot Image, swisstopo, NPOC",
       "attributionUrl": "http://www.swisstopo.admin.ch/internet/swisstopo/en/home.html",
       "background": true,
       "hasLegend": false,
       "format": "jpeg",
       "type": "wmts",
       "opacity": 0,
       "queryable": false,
       "timeEnabled": false,
       "serverLayerName": "ch.swisstopo.swissimage",
       "matrixSet": "21781_26",
       "resolutions": [
                4000,
                3750
       ],
       "timestamps": [
                "20151231",
                "20140620"
       ],
       "timeBehaviour": "last"
    }


.. _ref_user_cfg-portal_translations:

Translations
------------

Translations for a portal are located in the four files listed below. All these files must have this header: ``key,fr,de,en,commentaires``. The content of the ``commentaires`` column will be ignored. You can off course add/remove language columns.

#. `The translation document managed by Swisstopo <https://docs.google.com/spreadsheets/d/1F3R46w4PODfsbJq7jd79sapy3B7TXhQcYM7SEaccOA0/edit?pli=1#gid=0>`__.
#. ``customer-infra/translations/catalog.csv``: the content of the catalog, common to all portals. This includes the layer names present in the catalog and the title of the section of the catalog.
#. ``customer-infra/translations/<portal-name>.csv``: everything else (*note:* the translation for the topic titles and the topic tooltip – *topic_<topic_name>_tooltip* – go here).
#. ``customer-infra/translations/common.csv`` (optional): if you find redundancies between the translations for different portals, you can put them in this file. It will be loaded before the file for the portal, which means, you can override a translation from this file in a portal file.

.. attention::

  **At least one of the files above must contain a translation line.** Otherwise, no layers config will be created. Which means your portal won't work.

Translation from Swisstopo are overridden by translations in ``common.csv`` and translation from both Swisstopo and ``common.csv`` are overridden by translations from ``<portal>.csv``. To ignore a translation from Swisstopo, put its id in the ``customer-infra/translations/ignore.csv`` file. This file must just contain the translation ids (one per line). You can view an example `here <https://github.com/ioda-net/customer-infra/blob/master/translations/ignore.csv>`__.

.. attention::

  ids present in ``ignore.csv`` will never get into a translation file.


.. _ref_cfg-portal_topics:

Topics
------

Topics are defined in JSON files located in ``customer-infra/json/<portal>/topics/<topic_name>.json``. They must contains the keys below:

- ``backgroundLayers``: the list of background layer ids for this topic in the order they will appear in the background selector. For instance:

  .. code:: json

    "backgroundLayers": ["voidLayer", "landuse"]

- ``langs``: the list of languages for which this topic is available. For instance:

  .. code:: json

    "langs": ["en", "fr"]

- ``name``: the name of the topic. For instance:

  .. code:: json

    "name": "Topic 1"

  This is what must be used in translation files to translate the topic name.

- ``catalog``: defines the layers available for this topic and how they will be displayed. You can simply use a list of layer ids to have a catalog without depth. For instance:

  .. code:: json

    "catalog": [
        "places",
        "buildings"
    ]

  But you can also use a list of objects to group layers into categories. These objects must have the following keys:

  - ``category`` (string): can be anything but ``root`` and ``layer``.
  - ``selectedOpen`` (boolean): if it is true, then the group will be opened by default when the user expands the catalog for this topic.
  - ``children``: it can be either:

    - a list of layer ids. In this case, the layers will be presented to the user at this level.
    - a list of objects with the same properties as the ones in the catalog. This allows you to create subcategories.

  For instance:

  .. code:: json

    "catalog": [
        {
            "category": "land",
            "selectedOpen": false,
            "children": [
                "transport_osm_roads",
                "transport_osm_railways"
            ]
        },
        {
            "category": "air",
            "selectedOpen": false,
            "children": [
                "transport_osm_aeroways"
            ]
        }
    ]

You can also use the optional keys below:

- ``activatedLayers`` (default: empty list): the layers whose id is listed here will be in the *Map Displayed* selector by won't be selected. This allows you to put layers in the selector while hiding them by default. For instance:

  .. code:: json

    "activatedLayers": ["waterareas"]

- ``selectedLayers`` (default: empty list): the layers whose id is listed here will be in the *Map Displayed* selector and will be selected. This allows you to preselect some layers for a topic. For instance:

  .. code:: json

    "selectedLayers": ["places", "buildings"]

.. _ref_user_cfg-portal_search:

Search
------

Searches are performed by the API and `Sphinx search <http://sphinxsearch.com/>`__ a full text search engine.

The configuration for sphinx is divided in two parts:

- global configuration for an infrastructure: it configures the configuration of the sphinx daemon. It can be updated with ``manuel generate-search-conf``. The templates used to generate this configuration are located in ``geo-infra/search``.
- portal configuration: it configures the layer and locations searches:

  - locations searches: the configuration is created by a template located in ``customer-infra/search/portal-locations.in.conf``. To help you write this template, you can also create dedicated views in the database. See the :ref:`schema section in the database page <ref_sysadmin_db_schemas-functions_schemas_optional-schemas_schema-search>` of the system administrator manuel for more information on this. This template can look like:

  .. literalinclude:: /_static/search/portal-locations.in.conf

  - layers searches: the configuration is created by a template located in ``geo-infra/search/common/search-layers.in.conf``. The information used to build the indexes are stored in one TSV files per language in ``customer-infra/<type>/<portal>/search``. These TSV files are generated automatically when you build a portal.

Configure search keywords
~~~~~~~~~~~~~~~~~~~~~~~~~

By default, when the user does a search, the ``portal_locations`` index will be used. So the results will come from all your location indexes. However, if the user put in front of his/her search text a keyword, like this ``keywork search string``, then the results will be filtered. This allows your users to get more precise results.

For instance, if a portal have these indexes:

- ``<portal>_cities``: plain index built from a query in the database.
- ``<portal>_buildings``: plain index built from a query in the database.
- ``<portal>_parcels``: plain index built from a query in the database.
- ``<portal>_locations``: distributed index regrouping the three indexes above.

When you use the keyword ``address`` in the search bar, you want to search only in the ``portal_cities`` and ``portal_sorted_buildings`` indexes and not the whole ``<portal>_locations`` index since it also contains the parcels. Likewise, when you use the keyword ``parcel`` you want to search only in the ``portal_parcels`` index. This is what keywords are for: you specify a rank for each index and when a keyword is used, the API will filter the results to include only those with the appropriate ranks.

In order to enable a keyword, you must:

#. Defined a rank for each location index.
#. Map the index with their rank in ``customer-infra/config/_common.dist.toml`` and ``geo-api3/config/config.<branchname>.toml`` like this:

  .. code:: ini

    [search.origins_to_ranks]
    cities = 6  # index name: <portal>_cities
    sorted_buildings = 9  # index name: <portal>_sorted_buildings

#. Use this code when you build the search query:

  .. code::

    {{ search.origins_to_ranks[location] }} as rank

#. Add the keyword in the API in ``geo-api3/chsdi/customers/utils/search.py`` (ask a developer to do this). You can point them to :ref:`the relevant section of the developer guide <ref_dev_api_search-keywords>` if needed.


.. _ref_user_cfg-portal_identify-features:

Identify features
-----------------

In order to enable a feature view, for a portal, you need to enable it in the ``features.map_layers_features`` table. To do this, add or update a row like this:

- In the column ``feature`` put the name of the feature view.
- In the column ``portal_names`` put the table of portals for which the feature view must be available. For instance: ``{demo}``.
- In the column ``layer_names`` put the name of the layers for which the feature view must be requested. For instance: ``{roads}``.

Referer to the :ref:`feature section of the database page <ref_sysadmin_db_features>` to learn more how this works in the database and how to create feature views.

.. _ref_user_cfg-portal_identify-features_special-columns-features:

Special columns for features
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To be able to render feature columns with another representation than the "raw" content coming from the database, it is possible to create custom templates for columns verifying a special pattern. A number of special cases are handled automatically by default:

- ``hidden``: if a column name ends with ``_hidden`` it will not be displayed by default. The user can choose to see it if necessary.
- ``url``: if a column name ends with ``_url`` it will be rendered as an url (useful if the content has to be a valid clickable url). ``_url`` can be combined with ``_hidden`` to hide a URL type column by default like that ``_url_hidden``.
- ``pdf``: if a column name ends with ``_pdf``, the content will be rendered as a link with a acrobat pdf icon as content. The link generally points to ``/files/FILE.pdf``.

To use these templates, name your columns like this: ``name<pattern>``, eg ``website_url`` or ``boring_hidden``.

To add a new pattern, the code of the frontend needs to be updated. Ask a developer to do this. You can point to the :ref:`relevant section of the documentation <ref_dev_customer_features>`.


.. _ref_cfg-portal_help:

Help
----

This section explains how the help website and the help available from ``geo-front3`` is generated.

The help website is a small static website written using `AngularJS <http://angularjs.org/>`__. It is design to show help to the user of a portal and can be accessed for each one on by appending ``/help`` to the address of a portal. For instance for https://map.geoportal.xyz, https://map.geoportal.xyz/help.


Update the help (images and texts) from Swisstopo
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This rely on the ``scripts/generate_help.py`` python script (not usable directly). This will download the texts for each language supported by Swisstopo from google fusion table in the JSON format. The script will then convert this JSON file to a csv file and save the result in ``in/help/swisstopo/texts``.

While fetching the texts, the content is scanned by beautiful soup in order to find all images (these images are used with the ``a`` tag with a ``href`` attribute like ``(?:https?:)?//help.geo.admin.ch/([^ ])``). The links are corrected in order to use images from ``/help/img/``.  These images are converted to PNG and saved in ``in/help/swisstopo/img``.

To do this, use in ``geo-infra``:

.. code:: bash

   manuel help-update

.. note::

  There is no particular way to know if the help was updated by Swisstopo. Launch the update task and git will tell you if anything changed.


Generate the help for a portal
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The script will output the help in two formats:

- One for the help website. The files used are in ``<type>/<portal>/help/texts/<lang>.json``.
- One for the use within ``geo-front3`` in ``<type>/<portal>/help/texts/<id>-<lang>.json``

All the images are saved in ``<type>/<portal>/help/img``.

In order to generate the texts, the script will:

#. Parse the texts from ``geo-infra/help/texts/<lang>.csv``.
#. Parse the texts from ``customer-infra/help/<portal>/texts/<lang>.csv``. So in order to change a text from Swisstopo, you simply must add a row with the same id in the corresponding language specific file. For instance, in order to change the home page for French for ``geoportalxyz``, you must edit ``ioda-infra/help/geportalxyz/texts/fr.csv``. You must then add a line with the id 1. The number from the sort column (second column) must correspond to the one used by Swisstopo. For instance:

.. code::

   1,1,PAGE D'ACCUEIL,"<b>AIDE CARTE: FONCTIONS ET APPLICATIONS PRATIQUES</b>"

You can ignore a page by putting its id in ``in/help/<portal_name>/ignore.csv``.

For instance:

.. code::

  id
  42

To create a new language file for a portal, create a ``<lang>.csv`` file in ``customer-infra/help/<portal>/texts`` and put the following header:

.. code::

   id,sort,title,content,legend,image

In order to generate the images, the script will:

#. Copy the images from ``geo-infra/help/img``.
#. Copy the images from ``customer-infra/help/<portal>/img``. So to replace an image from Swisstopo, you must add an image with the same name (this include the extension) in ``customer-infra/help/<portal>/img``.

To build the help website (static site and files needed for the help within ``geo-front3``), use in ``geo-infra``:

.. code::

   manuel help-site [TYPE] PORTAL

Help generation in short
++++++++++++++++++++++++

The content of the site is generated as follows:

#. The images from Swisstopo are copied in the destination directory.
#. The images for the current portal are copied in the destination directory. This means that if an image has the same name as an image from Swisstopo, it will replace it.
#. The texts from Swisstopo are parsed from their respective csv files.
#. The texts for a current portal are parsed from its csv files. If a text has the same id as a text from Swisstopo it will replace it. This means that you only have to put the line you want to change into the portal CSV.


Writing help texts
~~~~~~~~~~~~~~~~~~

We advise you to use `LibreOffice <https://www.libreoffice.org/>`__ or equivalent to edit the CSV files. This way you can be sure that the CSV file you save is valid. It will also make editing of big texts easier.

Create links in the help website
++++++++++++++++++++++++++++++++

In order to insert link to another page of the website, you must use a ``button`` tag with an attribute ``ng-click="hc.goto(<id>)"``. For instance, to insert a link to the page with id 38:

.. code-block:: html

   <button ng-click="hc.goto(38)">More information</button>


.. _ref_user_cfg-protal_plugins:

Plugins
-------

For features may be available through plugins. To enable a plugin on a portal, add it to the ``plugins`` list of the ``front.default_values`` section. For instance, to enable the plugin named ``test``, your portal config file should contain:

.. code:: ini

    [front.default_values]
    plugins = ['test']


.. _ref_user_cfg-portal-print:

Print
-----

Printing a map relies on `MapFish Print <https://github.com/mapfish/mapfish-print>`__ a Java servlet developed by `Camptocamp SA <http://www.camptocamp.com/en/>`__.

You can either build it from scratch from `the source <https://github.com/mapfish/mapfish-print>`__ or use our `last build </data/getting-started/print.war>`__.

You can view examples of print templates `here <https://github.com/ioda-net/customer-infra/tree/master/print>`__. You can create your print templates with `Jasper Studio <http://community.jaspersoft.com/project/jaspersoft-studio>`__ or directly by editing the jrxml files with a text editor.

To learn more about the available options, see :ref:`the proper page of the documentation <ref_user_print>`.
