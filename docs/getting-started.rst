Getting Started
===============

Estimated time to complete: 3/4 hours.

.. contents::


Requirements
------------

.. Keep in sync with sysadmin/requirements.rst

- `Apache 2 <https://httpd.apache.org/>`__ with:

  - ``mod_rewrite``. To enable ``mod_rewrite`` on Debian based systems, use ``a2enmod rewrite``
  - ``mod_expires``. To enable ``mod_expires`` on Debian based systems, use ``a2enmod expires``
  - ``mod_headers``. To enable ``mod_headers`` on Debian based systems, use ``a2enmod headers``
  - ``mod_filter``. To enable ``mod_filter`` on Debian based systems, use ``a2enmode filter``
  - ``mod_deflate``. To enable ``mod_deflate`` on Debian based systems, use ``a2enmod deflate``
  - ``mod_fcgid``. To enable ``mod_fcgid`` on Debian based systems install the ``libapache2-mod-fcgid`` package (``aptitude install libapache2-mod-fcgid``) and on openSuse, install ``apache2-mod_fcgid``.
  - ``mod_proxy``, ``mod_proxy_ajp`` and ``mod_proxy_http``. To enable ``mod_proxy``, ``mod_proxy_ajp`` and ``mod_proxy_http`` on Debian based systems, use ``a2enmod proxy``, ``a2enmod proxy_ajp`` and ``a2enmod proxy_http``.

- `Python <https://www.python.org/>`__ 3.4 or above with virtualenv capabilities (probably in the ``python3-venv`` package or included with your Python 3 install)
- `nodejs <http://nodejs.org/>`__ 4.0 or above
- `MapServer <http://mapserver.org/>`__ 6.4.3+ (it will not work with 6.4.1) or 7.0.1+ (package commonly named ``mapserver`` on most distributions, on Debian based system, use ``cgi-mapserver`` and ``mapserver-bin``)
- `GDAL <http://www.gdal.org>`__ 2.0 or above with Python3 bindings
- `Sphinx search <http://sphinxsearch.com/>`__ 2.2 or above for the search features (package commonly named ``sphinx`` on most distributions, on Debian system, use ``sphinxsearch`` in Jessie backports)
- `tomcat <http://tomcat.apache.org/>`__ 8.0 or above to deploy the print component
- `Bash <http://www.gnu.org/software/bash>`__ 4 or above to launch the tasks
- `git <https://git-scm.com/>`__ 2.0 or above to get the code
- `proj <https://github.com/OSGeo/proj.4>`__ the cartographic projection software
- sudo to launch some commands with your normal user. Your ``/etc/sudoers`` file must contains the following lines (edit it with ``visudo``):

  ::

    USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart httpd.service  # Or /bin/systemctl restart apache2.service on Debian based system
    USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart searchd@customer-infra.service # Or /bin/systemctl restart searchd@customer-infra.service on Debian based system
    USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart tomcat.service # Or /bin/systemctl restart tomcat.service on Debian based system
    USER ALL=(ALL) NOPASSWD: /bin/systemctl restart tomcat8.service  # Debian based system only, in addition to the previous line.
    USER ALL=(ALL) NOPASSWD: /usr/bin/indexer --verbose --rotate --config /etc/sphinx/customer-infra.conf --all --quiet
    USER ALL=(ALL) NOPASSWD: /usr/bin/indexer --verbose --rotate --config /etc/sphinx/customer-infra.conf --all
    USER ALL=(ALL) NOPASSWD: /usr/sbin/apachectl -t

- The following libraries to correctly create the Python venv:

  - geos
  - geos-devel
  - postgresql-devel
  - libxml2-devel
  - libxslt-devel
  - python3-devel
  - gcc

  On debian based system, use this list:

  - libgeos-c1
  - libgeos-dev
  - libxml2-dev
  - libxslt-dev
  - python3-dev
  - gcc


Before we start
---------------

All tasks are launched here with `manuel <https://github.com/ShaneKilkelly/manuel>`__, a task runner written in Bash. To enable autocompletion in a Bash shell, source the ``geo-infra/manuel.autocomplete.bash`` file. `Completion is also available for zsh <https://github.com/ShaneKilkelly/manuel/blob/master/manuel.autocomplete.zsh>`__.

To launch ``manuel`` without always appending ``./`` copy ``geo-infra/manuel`` to your ``~/bin`` folder.

To get help about any task (description of what it does and its arguments), use ``manuel help TASK``. For instance, ``manuel help help``.


Setup the portal
----------------

- Clone all the repositories listed below in the same folder [#clone_all_same_folder]_:

  - The main infrastructure directory: ``git clone https://github.com/ioda-net/geo-infra.git``
  - The API: ``git clone https://github.com/ioda-net/geo-api3.git``
  - The frontend: ``git clone https://github.com/ioda-net/geo-front3.git``
  - The sample customer infra: ``git clone https://github.com/ioda-net/customer-infra.git``

- Switch to ``customer-infra``:

  - Download the ShapeFiles for Swisstzerland from `geofabrik <http://download.geofabrik.de/europe/switzerland-latest.shp.zip>`__ and uncompress it in ``customer-infra/data``:

    - ``wget http://download.geofabrik.de/europe/switzerland-latest.shp.zip``
    - ``unzip -d data/osm-switzerland switzerland-latest.shp.zip``
    - You should now have a ``customer-infra/data/osm-swisstzeland`` folder containing various ShapeFiles.

  - Add the symlink to the fonts:

    .. code:: bash

      ln -s /usr/share/fonts/liberation/LiberationSans-Regular.ttf data/LiberationSans-Regular.ttf

    or on Debian system:

    .. code:: bash

      ln -s /usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf data/LiberationSans-Regular.ttf

  - Update the configuration: in order to correctly test ``customer-infra`` for development, you only need to create ``customer-infra/config/dev/_common.dev.toml`` with the content below.

  .. code:: ini

    [vhost]
    ows_path = '/path/to/folder/containing/symlinks/to/mapserver/executable/'

  In this folder, create a symlink to your mapserver executable named after the portal. For instance, using the values of ``config/dist/_common.dist.toml``, we have ``ln -s /usr/bin/mapserv ~/geoportal-infras/cgi-bin/demo``.

- Switch to ``geo-front3``:

  - Launch ``npm install`` to install the node modules.

- Switch to ``geo-infra``:

  - Install the python dependencies listed in ``requires.txt``. You can install them globally with ``sudo pip install -r requires.txt`` or in a venv. If you use a version of Python below 3.5, you'll also need glob2. You can install it this way: ``sudo pip install glob2``. To install the dependencies in a venv, follow the steps below:

    - Create it: ``python3 -m venv .venv``
    - Activate it: ``source .venv/bin/activate`` **This must be done once before launching any command with manuel.**
    - Install the deps: ``pip install -r requires.txt``
    - Install ``glob2`` if needed: ``pip install glob2``

  - Include all files in ``customer-infra/dev/vhosts.d`` in your apache configuration. This can be done be editing ``/etc/httpd/conf/httpd.conf`` or ``/etc/apache2/apache2.conf`` depending on your system and appending this line at the end of the file: ``IncludeOptional /path/to/infra/dir/customer-infra/dev/vhosts.d/*.conf``.
  - Create the vhost: ``./manuel vhost demo``.
  - Create a symlink named ``mapserv`` to your MapServer executable in ``cgi-bin``. Eg: ``ln -s /usr/bin/mapserv cgi-bin/mapserv``.
  - Generate the utility files: ``./manuel dev demo``.
  - Generate the frontend: ``./manuel front dev demo``.
  - Add ``demo.geoportal.local`` to you ``/etc/hosts``.
  - Open http://demo.geoportal.local.
  - You should see a portal. It should be similar to the image below. Please note that only map navigation is functionnal at this stage. The features that rely on the API (searches, QR code, shortener, get features) and print, will be enabled in the sections below.

  .. figure:: /_static/img/getting-started/demo-portal-home.png
    :alt: Demo portal home page

    Demo portal home page

.. [#clone_all_same_folder] They can be arranged differently later if you override the proper values in ``geo-infra/config/config.sh``


API
---

Switch to ``geo-api3``:

- Update the configuration. To do that, create a file named ``config/config.devel.toml`` and adapt the content below to your use case:

  .. code:: ini

    default_epsg = 2056

    [db]
    type = 'sqlite'
    file_path = 'customer_infra.sqlite'
    staging = ''

    [raster]
    # Optionnal. If you have bt for altitude, put their path here. If you don't, height and profile related features won't work.
    # It must contain a bt folder with the bt.
    # dtm_base_path = '/var/lib/geoportal/data/'

    [search]
    port = 9314
    [search.origins_to_ranks]
    places = 10

    [shortener]
    allowed_domains = ['geoportal.local']
    allowed_hosts = ['localhost']

    [storage]
    kml = '/tmp'

    [waitress]
    # This must be coherent with vhost.api_proxy from customer-infra. 9080 is the default value from _common.dist.toml
    port = 9080

  - Download the `sample sqlite database file </data/getting-started/customer_infra.sqlite>`__ into the ``geo-api3`` folder:

    - ``wget https://docs.geoportal.xyz/data/getting-started/customer_infra.sqlite``

  - Create the proper venv with ``./manuel venv``
  - Update the ini files used by Pyramid: ``./manuel ini-files``.
  - Launch the API: ``./manuel serve``.

  .. attention::

    If the command fails due to ``ImportError: No module named 'osgeo'``, check that the osgeo module from system install is available in the ``PYTHONPATH`` specificied in ``config/config.dist.sh``. If not, create a ``config/config.sh`` with the correct value for ``PYTHONPATH``. Eg for Debian, put this value:

      .. code:: shell

        export PYTHONPATH=".venv/lib/python${PYTHON_VERSION}/site-packages:/usr/lib/python3/dist-packages:$(pwd)"

  - If you go to the portal, the QR codes, short link and features identification should work as expected. Search will be enable in the next section.

  .. figure:: /_static/img/getting-started/api-is-working.png
    :alt: Portal page with QR code and short link

    Portal page with QR code and short link

.. attention::

  If you test the get features capability, you will only get a very basic presentation: it is what MapServer returns to the GetFeatures request. You improve this if you with access to the database. See :ref:`the relevant section of the documentation <ref_sysadmin_db_features>`.


Search
------

Switch to ``geo-infra``:

- Create global search configuration:

  .. code:: bash

    ./manuel generate-global-search-conf customer-infra

  At this point, this command should return with this error: ``Job for searchd@customer-infra.service failed because the control process exited with error code.`` This is expected.
- Add a symlink to the newly created sphinx configuration (*this must be done as root*):

  .. code:: bash

     ln -s <infra-dir>/customer-infra/dev/search/sphinx.conf /etc/sphinx/customer-infra.conf

  .. attention::

    On Debian based systems, before creating the symlink, you must (*as root*):

      - Create the ``/etc/sphinx/`` directory: ``mkdir /etc/sphinx/``
      - Change its owner to ``sphinxsearch``: ``chown -R sphinxsearch:sphinxsearch /etc/sphinx``

- Create sphinx infrastructure specific directories (*this must be done as root*):

  - Create: ``mkdir -p /var/lib/sphinx/customer-infra/{binlog,index}``
  - Set proper owner: ``chown -R sphinx:sphinx /var/lib/sphinx/customer-infra``
  - Create log dir: ``mkdir -p /var/log/sphinx``
  - Set proper owner: ``chown -R sphinx:sphinx /var/log/sphinx``
  - Create run dir for PID: ``mkdir -p /var/run/sphinx``
  - Set proper owner: ``chown -R sphinx:sphinx /var/run/sphinx``

    .. attention::

      On Debian based system:

        - The correct user is ``sphinxsearch``
        - Don't attempt to create the directories above in ``/var/lib/sphinxsearch`` the process will be configured to look in ``/var/lib/sphinx``

- Deploy the unit files for this infrastructure (*this must be done as root*):

  - Copy the service files: ``cp /path/to/geo-infra/searchd@.service /etc/systemd/system/``

    .. attention::

      On Debian based systems, you must correct the user to ``sphinxsearch`` in the unit file.

  - Reload systemd daemons: ``systemctl daemon-reload``

- Download the `data needed by sphinx to build its indexes </data/getting-started/places.csv>`__ and put in it ``customer-infra/data``:

  - ``cd /path/to/customer-infra/data``
  - ``wget https://docs.geoportal.xyz/data/getting-started/places.csv``

- Start sphinx: ``./manuel restart-service search customer-infra``
- Trigger an reindex: ``./manuel reindex customer-infra``
- Search should work as expected.

Search with a database
~~~~~~~~~~~~~~~~~~~~~~

In real case senario, you probably want the locations to come from your database and not some CSV file. To do that, you can use the template below as ``customer-infra/search/portal-locations.in.conf``:

.. literalinclude:: /_static/search/portal-locations.in.conf

In that case, you must configure the search in your ``config/_common.dist.toml`` to have access to the database and to convert origins to ranks:

.. code:: ini

  [search]
  sphinx_sql_host = "localhost"
  sphinx_sql_user = "geo_searchd"
  sphinx_sql_pass = "azerty"
  sphinx_sql_port = 5432
  sphinxhost = "localhost"
  sphinxport = 9313

  [search.origins_to_ranks]
  places = 6
  buildings = 9
  admin = 13

View the :ref:`relevant page of the documentation for more information on this<ref_user_cfg-portal_search>`.


Print
-----

Switch to ``geo-infra``:

- Download the `print WAR </data/getting-started/print.war>`__:

  - ``wget https://docs.geoportal.xyz/data/getting-started/print.war``

- Do the following actions as root:

  - Copy the WAR in your tomcat webapps folder (eg ``/usr/share/tomcat/webapps``, ``/srv/tomcat/webapps/`` or ``/var/lib/tomcat8/webapps``) under the name ``print-customer-infra.war``.
  - Start tomcat: ``systemctl start tomcat``

    .. attention::

      On Debian based systems, the target is named ``tomcat8``

  - Go to the tomcat webapps folder.
  - Check that ``print-customer-infra.war`` is correctly deployed.
  - Create the ``print-customer-infra/print-apps`` directory and make it owned by tomcat:

    - ``mkdir print-customer-infra/print-apps``
    - ``chown tomcat:tomcat print-customer-infra/print-apps``

    .. attention::

      On Debian based systems, the correct user is ``tomcat8``.

  - Check and correct permissions on ``<tomcat-webapps>/print-customer-infra/print-apps``:

    - Check that with the user you are using to run ``./manuel`` in ``geo-infra`` you can access this directory. If ``ls <tomcat-webapps>/print-customer-infra/print-apps`` returns successfuly, you are good to go. If not, correct the permissions to give it read and execute access on all folders on the path.
    - Setup ACL to give the user write permissions to the directory (**don't use standard unix permissions, it breaks tomcat's expectations**): ``setfacl -m u:<user>:rwx print-customer-infra/print-apps``.

  - Check that tomcat has an AJP connector defined on port 8009 in ``/etc/server.xml``. If not, add the line below in the ``<Service name="Catalina">`` section:

    .. code:: xml

      <Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />

  - Restart tomcat ``systemctl resart tomcat``

- Go to ``geo-infra``
- Export your value of MPF_APP_FOLDER to allow manuel to copy it to the correct location. For instance: ``export MFP_APP_FOLDER="/usr/share/tomcat/webapps/print-customer-infra/print-apps/"``
- Copy print configuration: ``./manuel tomcat-copy-conf "dev" demo``
- Check that you have a ``demo`` folder in ``<tomcat-webapps>/print-customer-infra/print-apps``.
- If so, try to print in the portal. It should work as expected.
- Unset the MFP_APP_FOLDER variable: ``unset MFP_APP_FOLDER``

Switch to ``customer-infra``:

- In ``config/config.sh`` add a line like this: ``set-var MFP_APP_FOLDER "/usr/share/tomcat/webapps/print-customer-infra/print-apps/"`` that corresponds to the correct path to MapFish Print. It will now be used automatically by the scripts.


Conclusion
----------

Everything should work correctly now. You can now rebuild the configuration of the portal with ``./manuel dev demo`` or rebuild everything with ``./manuel dev-full demo``.
