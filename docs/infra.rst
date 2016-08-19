How does the infrastructure work?
---------------------------------

In this document, when we refer to ``customer-infra`` directory, we mean any directory contains the infrastructure for a specific customer. It can be named anything but must be placed in the path defined by the ``$INFRA_DIR`` variable. The proper path will be determined by the scripts from the portal name and the content of this variable. See the `Configuration`_ section of this document for more details.

.. contents::

Setup geo-infra
~~~~~~~~~~~~~~~

- You must add a symlink to the ``mapserv`` executable in cgi-bin. This allows the scripts to parse the generated Map files to create the most up to date configuration for the frontend.
- Install the python dependencies listed in ``requires.txt``. You can install them globally with ``sudo pip install -r requires.txt`` or in a venv. If you use a version of Python below 3.5, you'll also need glob2. You can install it this way: ``sudo pip install glob2``.


Setup a customer infrastructure
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Include all files in ``customer-infra/dev/vhosts.d`` in your apache configuration. This can be done be editing ``/etc/httpd/conf/httpd.conf`` or ``/etc/apache2/apache2.conf`` depending on your system and appending this line at the end of the file: ``IncludeOptional /path/to/infra/dir/customer-infra/dev/vhosts.d/*.conf``.
- Review the TOML and shell configurations and override any value necessary for your need.


Templates
~~~~~~~~~

They can be located in the following subfolders (in ``geo-infra`` or ``customer-infra``):

- portals
- search

They are written in the `jinja2 template language <http://jinja.pocoo.org/>`__. In order to ease the writing of templates, you can use special strings that will be replaced by the corresponding values:

- ``type``: dev or prod
- ``portal``: the name of the portal
- ``infra_dir``: the absolute path to the current customer infra dir
- ``infra_name``: the base name of infra dir, eg customer-infra
- ``mapserver_ows_host``: the host of mapserver (used to generate the print configuration). Only is portal is not None.
- ``prod_git_repos_location``: location of the productions git repositories on the server.

They can be used like this to be replaced by the correct values:

::

  {{ infra_dir }}/{{ dev }}

To use any other value, you must refer to the section and the key, like this:

::

  {{ search.sphinx_sql_host }}

MapServer Templates
+++++++++++++++++++

You can split your MapServer files into various files to ease the creation of complex Map files. To do this, you can use the ``INCLUDE`` directive of MapServer. It is used like this:

.. code::

  # Path for include is relative to the current file.
  INCLUDE "../layers/buildings.map"

During the rendering phase, the ``customer-infra/portals/<portal>.in.map`` will be parsed for these includes. These included files will be rendered by jinja2, copied to ``customer-infra/dev/<portal>/map`` directory with the same structure as in the ``customer-infra`` directory. You can also include files with the ``INCLUDE`` directive in included files.

You can test the generated Map files with ``./manuel test-map-files dev PORTAL_NAME``

.. attention::

  - Only visible layers will be completely tested, but the syntax of the files will be checked not matter what.
  - Syntax checking is done automatically in the ``prod``, ``deploy`` and ``dev-full`` tasks.

Search templates
++++++++++++++++

Templates for search are splitted in three categories:

- global templates located in ``geo-infra``:

  - ``search/sphinx.in.conf`` the entry point for sphinx
  - ``search/global-base.in.conf`` the configuration of the daemon for sphinx.

- templates common to all infrastructures located in ``geo-infra``:

  - ``search/common/db.in.conf`` included once for each portal, it configures the connection to the proper database for each portal.
  - ``search/common/search-layers.in.conf`` included once for each portal, it configures the search for the layers.

- customer specific templates in the relevant customer infrastructure directory in ``customer-infra/search/portal-locations.in.conf``.

A typical ``search`` section in ``customer-infra/config/_common.dist.toml`` looks like:

.. code:: ini

  [search]
  sphinx_sql_host = "localhost"
  sphinx_sql_user = "geo_searchd"
  sphinx_sql_pass = "azerty"
  sphinx_sql_port = 5432
  sphinxhost = "localhost"
  sphinxport = 9313

A generic ``portal-locations.in.conf`` looks like:

.. literalinclude:: /_static/search/portal-locations.in.conf


Configuration
~~~~~~~~~~~~~

Configuration for the portals and templates
+++++++++++++++++++++++++++++++++++++++++++

The configuration files are written in `TOML <https://github.com/toml-lang/toml>`__. A toml file looks like:

.. code:: ini

  [section]
  key_str_value = 'value'
  key_bool_value = true
  # This is a comment
  key_nb_value = 78.0
  [section.subsection]
  key_array = [1, 2, 3]
  key_obj = { k1 = 'Hello', k2 = 'World' }

In order to ease the writing of some values, you can use special strings that will be replaced by their values:

- ``{type}``: the type of deployment.
- ``{portal}``: the name of the portal.
- ``{domain}`` (from vhost.domain).

They can be used like this:

.. code:: ini

  key = '{type}.{portal}.{domain}'

For instance, with ``type = 'dev'``, ``portal = 'demo'`` and ``domain = 'geoportal.local'``, the value of key will be: ``'dev.demo.geoportal.local'``.

If you want to insert curly braces in your string, you need to escape them like this:

.. code:: ini

  key_with_curly_brace = '{{toto}}'

The configuration system is design to allow easy deployment on production while being able to override any value for development or tests purposes. In order to easy maintenance, everything that can be in a ``config/_common.<type>.toml`` file must be in it. Any value in the ``config/_common.<type>.toml`` files can be overridden in a portal specific file.

The configuration is loaded like this (**all these files are mandatory, if they don't exist, the task will fail**):

1. ``geo-infra/config/global.toml`` file is loaded. This is the only TOML configuration file from ``geo-infra``. It contains general configuration values and paths. Normally, you shouldn't change keys present in it.
2. ``customer-infra/config/dist/_common.dist.toml``
3. ``customer-infra/config/dist/<portal>.dist.toml`` (unless you are doing a non portal specific task like building the global sphinx configuration).
4. ``customer-infra/config/_template.dist.toml``: this is not a configuration file per see but the values that are allowed in portal specific configuration files. If a key or section is present in a portal file but not in the template, it will be reported as warning.

If you are building the portal for production, the files below are loaded if they exists after the files listed above:

1. ``customer-infra/config/prod/_common.prod.toml``
2. ``customer-infra/config/prod/<portal>.prod.toml``

If you are building the portal for development, the files below are loaded if they exists after the files listed above:

1. ``customer-infra/config/dev/_common.dev.toml``
2. ``customer-infra/config/dev/<portal>.dev.toml``

.. attention::

  You should be aware that:

    - All files ends by ``.<type>.toml`` to ease recognition when many of them are opened in a text editor.
    - Only the files in ``customer-infra/config/dist`` should be tracked by git to allow developers to override values for testing purposes. This means that the values contained in these files, should match those of production to easy deployment: no need to update the production configuration, a ``git pull`` is enough.

To debug the configuration, see the :ref:`debug-configuration` section of the :ref:`debug` page.

Configuration for the shell scripts
+++++++++++++++++++++++++++++++++++

The general configuration is in ``geo-infra/config/config.dist.sh``. It contains mostly paths to commands and various locations of importance. It is loaded before any other shell configuration.

You can override any value in ``geo-infra/config/config.sh``. All values must be set with the ``set-var VARIABLE_NAME VALUE`` function. This way, values will be overridden from the config file but you cat still force the value for a specific variable by setting it in your environment like this: ``export VARIABLE="VALUE"``. This file is optional and shouldn't contain many values. A typical ``geo-infra/config/config.sh`` would be:

.. code:: bash

  # Misc
  # Hide the outputs of some commands
  set-var QUIET "true"

  # Infra
  # Set up where the resolutions for customer infrastructures should take place.
  set-var INFRA_DIR "../geoportal-infras"

For some tasks, the shell configuration for the customer infrastructure will be loaded. This is done with either:

- ``_load-prod-config``: used in ``prod``, ``deploy``, ``init-prod-repo``, ``deploy-global-search-conf`` and database related tasks. In these cases, ``$INFRA_DIR`` must point to a specific infrastructure directory (eg ``/path/to/customer-infra``). If not, it will fail with an error message. This way, when you deploy a portal, the production values in the script are always correct.
- ``_load-dev-config``: used in ``dev`` and ``dev-full`` will load the customer shell configuration from the infrastructure of each portal.

Both of these function will reload the full configuration to be sure proper values are set in the variable. This means, they load:

1. ``geo-infra/config/config.dist.sh`` **Required**
2. ``geo-infra/config/config.sh`` *if present*.
3. ``customer-infra/config/config.dist.sh`` **Required**
4. ``customer-infra/config/config.sh`` *if present*.

That mean ``customer-infra/config/config.dist.sh`` should contain deployment for production values. So, a ``customer-infra/config/config.sh`` shouldn't contain many keys. Typically, it should look like that:

.. code:: bash

  ## Where to copy generated MapFish Print applications (directory containing config.yaml, the
  ## templates and the images).
  set-var MFP_APP_FOLDER "/usr/share/tomcat/webapps/print-customer-infra/print-apps/"


Layouts
~~~~~~~

Layout for scripts
++++++++++++++++++

All scripts are located in ``geo-infra``:

- ``./scripts/``: directory containing build scripts (python and SQL)
- ``./tasks/``: directory containing shell files sourced by manuel.
- ``./cgi-bin/``: must contain a symlink named ``mapserv`` to the MapServer executable. It is required for the generation of JSON configuration files   from ``GetCapabilities`` requests. Since we cannot know where it is on your specific configuration, **you must add this symlink yourself**.


Layout for configuration files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To learn more how this works, see the `Configuration`_ section of this document.

In ``geo-infra``:

- ``config/global.toml``: the global configuration file.
- ``config/config.dist.sh``: contains the configuration for shell scripts.
- ``config/config.sh``: *Optional*, not tracked by git.

In ``customer-infra``:

- ``config/dist/``: all dist files tracked by git. They should be directly usable on the production server.
- ``config/prod``: all files used for prod builds, not tracked by git.
- ``config/dev``: all files used for dev builds, not tracked by git.
- ``config/config.dist.sh``: production variables for shell scripts **Required**.
- ``config/config.sh``: *Optional*, not tracked by git.

Layout for data
+++++++++++++++

In ``customer-infra``, you will probably have a ``./data`` directory for global data & elements. It will most likely not be tracked by git. A possible organization is this:

- ``data/symbols.txt``
- ``data/fonts/``: directory for fonts (name/file.ttf|odf) all lowercase
- ``data/rasters/``: directory for rasters
- ``data/shapes/``: directory for shapes
- ``data/templates/``: html template for mapserver

Layout for includes
+++++++++++++++++++

In ``geo-infra``:

- ``help``: contains the help website (JS, HTML and CSS) and the texts and images for the help. It also contains the text and images from Swisstopo.

In ``customer-infra``:

- ``help`` *Optional*:

  - ``help/<portal>/{img,texts}``: contain respectively the images and the help texts for the help website. You can only add images and texts you want changed from Swisstopo. See the `help section <user/help.html>`__ of the documentation for more information no this.

- ``img/``: contains the images for all portals

  - ``img/<portal>``: Any image in this folder with the same name as an image from the global folder will replace the image from the global folder.

- ``json/``: contains a subfolder for each portal. If this subfolder, there is an ``external`` subfolder which contains the JSON configuration files for the external layers and a ``topics`` subfolder which contains the JSON configuration files for the topics.

- ``portals/``: contain .map defining a geo-portal. You can organize you includes like this:

  - ``customer-infra/layers/``: contains .map defining layers (included in geo-portals). Files will be named like:

    - ``db.LAYERNAME.layer.map.in`` for database based
    - ``shp.LAYERNAME.layer.map.in`` for shapes based
    - ``rasters.LAYERNAME.layer.map.in`` for rasters based
    - ``wms.LAYERNAME.layer.map.in`` for imported external WMS layers

  - ``customer-infra/mapserver``: contains .map related to pure MapServer instructions.
  - ``customer-infra/styles``: contains .map defining a layer class included in layers. Files will be named like ``TYPEOFSTYLE.style.map.in``

- ``print/``: contains the template and configuration for MFP.
- ``search/``: contains the template for searches specific to this portal.
- ``translations/``: contains the translation files.

Recommendations
```````````````

- Use of MapServer include instruction whenever you can, it will ease maintenance.
- Use convention, eg: *The file has to be started with: ``mapserver.FUNCTION.map.in``*.

Layout for output
+++++++++++++++++

The output is located in the ``customer-infra`` directory. You don't want these folders to be tracked by git.

- ``dev/``

  - ``dev/<portal>/``: contains the generated files for one portal. The content of each subfolder should be obvious given the name of the subfolder. This is the document root for the vhost of the current portal.
  - ``dev/vhosts.d``: contains the generated vhosts.
  - ``dev/search`` contains the generated global search configuration for this infrastructure.

- ``prod/``: same as ``dev``. It also contains the generated content for production. Each subfolder should be an autonomous git repository to ease deployment to production and rollback if necessary.
