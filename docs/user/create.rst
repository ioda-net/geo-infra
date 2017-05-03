Create
======

.. contents::


Create a new portal
-------------------

#. Create at least a dist config file for the portal named ``config/dist/<portal>.dist.toml``. You can view an example `here <https://github.com/ioda-net/customer-infra/blob/master/config/dist/demo.dist.toml>`__.
#. Create the map files: you must at least create a map file named ``customer-infra/portals/<portal>.in.map``. This will be the main map file for the portal. You can use includes in this file and the `jinja2 template language <http://jinja.pocoo.org/>`__. To know more about that, referer to the :ref:`template section of the infrastructure page <ref_infra_templates>`.
#. Create the translations CSV files below. All these files must have this header: ``key,fr,de,en,commentaires``. The content of the ``commentaires`` column will be ignored. You can off course add/remove language columns. To learn more how translations work, see the section about translations from the :ref:`portal configuration page <ref_user_cfg-portal_translations>`.

   - ``customer-infra/translations/catalog.csv``: the content of the catalog, common to all portals. This includes the layer names present in the catalog and the title of the section of the catalog.
   - ``customer-infra/translations/<portal-name>.csv``: everything else (*note:* the translation for the topic titles and the topic tooltip – *topic_<topic_name>_tooltip* – go here).
   - ``customer-infra/translations/common.csv`` (optional): if you find redundancies between the translations for different portals, you can put them in this file. It will be loaded before the file for the portal, which means, you can override a translation from this file in a portal file.

   .. warning::

    **At least one of the files above must contain a translation line.** Otherwise, no layers config will be created. Which means your portal won't work.

#. Add the external layers (WMS or WMTS) by creating the relevant JSON files in ``customer-infra/json/<portal>/external`` (*optional*). To learn more about how to write these files, refer to the :ref:`proper section of the page about portal configuration <ref_user_cfg-portal_layers-external-sources>`. You can view examples `here <https://github.com/ioda-net/customer-infra/tree/master/json/demo/external>`__.
#. Create the JSON topic files in ``customer-infra/json/<portal>/topics``. They define for each topic its name, languages, background layers, selected layers and catalog. You can view examples `here <https://github.com/ioda-net/customer-infra/blob/master/json/demo/topics>`__. To learn more how topics work, see the section about topics from the :ref:`portal configuration page <ref_cfg-portal_topics>`.
#. Add the logo used in your print templates in ``customer-infra/print/<portal>/``. See the :ref:`print section <ref_user_cfg-portal-print>` of the portal configuration page to learn more about printing. This folder must contain:

   - `NorthArrow.svg <https://github.com/ioda-net/customer-infra/blob/master/print/demo/NorthArrow.svg>`__ if your templates have the north arrow.
   - Any logo used in your print templates.

#. Add the images for a portal in ``customer-infra/img/<portal-name>/``. It must contain:

    - The favicon in ``favicon.ico``.
    - A JPEG file per topic. These files are named like this: ``<my_topic>.jpg``.
    - A logo per language. They are named like this: ``logo.ch.<lang>.png``.

#. Prepare the help site (*optional*). General steps are detailed below. To learn more about help, look at :ref:`the section about help <ref_cfg-portal_help>` in the portal configuration page.

   - Put any texts and images that are common to all portal in the ``customer-infra/help/common`` folder. Everything that is in this folder will be loaded before any portal data, which means you can override any value in the portal folder.
   - Put any texts and images specific to a portal in ``customer-infra/help/<portal>/``.

#. Enable searches in ``search.locations``. This key must contain the list of the names of the locations indexes that must be enabled for this portal. For instance:

   .. code:: ini

    [search]
    locations = ['places']


Create a new infrastructure
---------------------------

You should use `this git repository <http://github.com/ioda-net/customer-infra>`__ as a template.

#. Create the ``config/config.dist.sh`` file with the values for deployment. You can view an example `here <https://github.com/ioda-net/customer-infra/blob/master/config/config.dist.sh>`__.
#. Create the ``config/dist/_common.dist.toml`` which will hold all values shared between portals. You can view an example `here <https://github.com/ioda-net/customer-infra/blob/master/config/dist/_common.dist.toml>`__.
#. Prepare the ``config/_template.dist.toml`` file that will be used to validate the configuration files for each portals. It must contain the key that are allowed in each portal config file. You can view an example `here <https://github.com/ioda-net/customer-infra/blob/master/config/_template.dist.toml>`__.
#. Create the search templates for portal: ``customer-infra/search/portal-locations.in.conf``. Here is an example:

   .. literalinclude:: /_static/search/portal-locations.in.conf

#. Configure your ``.gitignore`` to ignore user specific configuration files and generated output. You can view an example `here <https://github.com/ioda-net/customer-infra/blob/master/.gitignore>`__.
#. Prepare you print templates. You can view examples of them `here <https://github.com/ioda-net/customer-infra/tree/master/print>`__. You can create your print templates with `Jasper Studio <http://community.jaspersoft.com/project/jaspersoft-studio>`__ or directly by editing the jrxml files with a text editor.
#. Prepare the ``translations`` folder by creating the ``ignore.csv`` file. This file will just contain the translation ids (one per line) you don't want included in JSON translation files. You probably want to exclude everything that deals with Swisstopo. You can view an example `here <https://github.com/ioda-net/customer-infra/blob/master/translations/ignore.csv>`__.
#. You can create a ``docs`` subdirectory and setup sphinx in it (see how it is done in the ``docs`` folder of ``geo-infra``). You can then build this doc with ``manuel build-doc-customer``.
#. `Create a new portal`_.
