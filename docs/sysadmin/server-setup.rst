Server setup
============

This document describe how the server must be setup for production use.

.. note::

  Replace ``customer-infra`` by the true name of your infrastructure.

.. contents::

.. Keep in sync with getting started.

Common Requirements
-------------------

- `Apache 2 <https://httpd.apache.org/>`__ with:

  - ``mod_proxy``. To enable ``mod_proxy`` on Debian based systems, use ``a2enmod proxy``
  - ``mod_rewrite``. To enable ``mod_rewrite`` on Debian based systems, use ``a2enmod rewrite``
  - ``mod_expires``. To enable ``mod_expires`` on Debian based systems, use ``a2enmod expires``
  - ``mod_headers``. To enable ``mod_headers`` on Debian based systems, use ``a2enmod headers``
  - ``mod_fcgid``. To enable ``mod_fcgid`` on Debian based systems install the ``libapache2-mod-fcgid`` package (``aptitude install libapache2-mod-fcgid``)
  - ``mod_filter``. To enable ``mod_filter`` on Debian based systems, use ``a2enmod filter``
  - ``mod_deflate``. To enable ``mod_deflate`` on Debian based systems, use ``a2enmod deflate``
  - ``mod_proxy``, ``mod_proxy_ajp`` and ``mod_proxy_http``. To enable ``mod_proxy``, ``mod_proxy_ajp`` and ``mod_proxy_http`` on Debian based systems, use ``a2enmod proxy``, ``a2enmod proxy_ajp`` and ``a2enmod proxy_http``.
  - ``mod_wsgi``. This is most likely in a separate package named like ``python3-mod_wsgi``. To enable ``mod_wsgi`` on Debian based systems, use ``a2enmod wsgi``.

- `Python <https://www.python.org/>`__ 3.4 or above with virtualenv capabilities (probably in the ``python3-venv`` package or included with your Python 3 install)
- `nodejs <http://nodejs.org/>`__ 4.0 or above
- `GDAL <http://www.gdal.org>`__ 2.0 or above with Python3 bindings
- `Sphinx search <http://sphinxsearch.com/>`__ or above for the search features (package commonly named ``sphinx`` on most distributions, on Debian system, use ``sphinxsearch`` in Jessie backports)
- A WMS/WMTS server. For instance `MapServer <http://mapserver.org/>`__. The version depends on your needs and the Map files you will write but we recommend the last version.
- `tomcat <http://tomcat.apache.org/>`__ 8.0 or above to deploy the print component
- `Bash <http://www.gnu.org/software/bash>`__ 4 or above to launch the tasks
- `git <https://git-scm.com/>`__ 2.1 or above to get the code
- A database system. Currently, we only support `PostgreSQL <https://www.postgresql.org/>`__ on production setup.


Requirements for a usage with a virtualenv
------------------------------------------

The following libraries to correctly create the python venv of the API: geos, geos-devel, postgresql-devel, libxml2-devel, libxslt-devel.

On debian based system, use this list: libgeos-c1, libgeos-dev, python3-pip (needed to create the virtualenv for the API), libxml2-dev, libxslt-dev.


Requirements without a virtualenv
---------------------------------

To view the full list of Python 3 packages necessary for the API, take a look at `this file <https://github.com/ioda-net/geo-api3/blob/devel/requirements.txt>`__.


.. _ref_sysadmin_server-setup_production-cfg:

Production configurations
-------------------------

Review the production configurations. The script containing the production values for deployment is located in ``customer-infra/config/config.dist.sh``. Here is a sample file with the variables that are used and how they are used. You can view an example `here <https://github.com/ioda-net/customer-infra/blob/master/config/config.dist.sh>`__.

You should also check that the configuration for the vhost are correct (domain, HTTPS certificates). This will be located in ``customer-infra/config/dist/_config.dist.toml``. Beware that these values can be overridden in portal specific files. The section looks like this:

.. code:: ini

  [vhost]
  api_proxy = 'http://localhost:9080'
  # If this is empty, the configuration will not use HTTPS
  certificate_file = ''
  certificate_chain_file = ''
  domain = 'geoportal.local'
  certificate_key_file = ''
  # Keep trailing slash!
  ows_path = '~/geoportal-infras/cgi-bin/'
  print_proxy = 'ajp://localhost:8009'
  # On dev, infra_dir is used instead. No trailing slash!
  prod_data_dir = '/var/lib/geoportal/data'
  server_name = '{portal}.{domain}'


sudo
----

You will need sudo to launch some commands with the user used to deploy the portals. Your ``/etc/sudoers`` file must contains the lines below. Replace USER by the user defined by ``$PROD_USER``. See the section about `Production configurations`_ of this document to learn more about ``$PROD_USER``.

  ::

    USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart httpd.service  # Or /bin/systemctl restart apache2.service on Debian based system
    USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload httpd.service  # Or /bin/systemctl reload apache2.service on Debian based system
    USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart searchd@customer-infra.service # Or /bin/systemctl restart searchd@customer-infra.service on Debian based system
    USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart tomcat.service # Or /bin/systemctl restart tomcat.service on Debian based system
    USER ALL=(ALL) NOPASSWD: /bin/systemctl restart tomcat8.service  # Debian based system only, in addition to the previous line.
    USER ALL=(ALL) NOPASSWD: /usr/bin/indexer --verbose --rotate --config /etc/sphinx/customer-infra.conf --all --quiet
    USER ALL=(ALL) NOPASSWD: /usr/bin/indexer --verbose --rotate --config /etc/sphinx/customer-infra.conf --all
    USER ALL=(ALL) NOPASSWD: /usr/sbin/apachectl -t


Production scripts
------------------

In order to be sure that tomcat, apache, search can restart and that a reindex can be triggered, we invite you to create scripts available in the PATH of the user that will do the deployment. These scripts are:

- ``sudo_tomcat_restart``. It may contain:

  .. code:: bash

    sudo /usr/bin/systemctl restart tomcat.service

- ``sudo_apache_restart``. It may contain:

  .. code:: bash

    sudo /usr/bin/systemctl restart httpd.service

- ``sudo_apache_reload``. It may contain:

  .. code:: bash

    sudo /usr/bin/systemctl reload httpd.service

- ``sudo_search_restart``. It may contain:

  .. code:: bash

    sudo /usr/bin/systemctl restart searchd@customer-infra.service

- ``sudo_search_reindex``. It may contain:

  .. code:: bash

    sudo /usr/bin/indexer --verbose --rotate --config /etc/sphinx/customer-infra.conf --all

- ``sudo_tomcat_copyconf``. It may contain:

  .. code:: bash

    set -u
    set -e

    MFP_PRINT_APPS='/srv/tomcat/webapps/print-ioda-infra/print-apps'
    SOURCE_APP="/home/geop/ioda-infra/prod/$1/print"

    mkdir -p "${MFP_PRINT_APPS}/$1"
    /usr/bin/cp -av ${SOURCE_APP}/* "${MFP_PRINT_APPS}/$1/"

vhosts
------

Include all files in ``$PROD_GIT_REPOS_LOCATION/vhosts.d`` in your apache configuration. This can be done be editing ``/etc/httpd/conf/httpd.conf`` or ``/etc/apache2/apache2.conf`` depending on your system and appending this line at the end of the file: ``IncludeOptional $PROD_GIT_REPOS_LOCATION/vhosts.d/*.conf``. See the section about `Production configurations`_ of this document to learn more about ``$PROD_GIT_REPOS_LOCATION``.

Print
-----

.. Keep in sync with the getting started

Printing a map relies on `MapFish Print <https://github.com/mapfish/mapfish-print>`__ a Java servlet developed by `Camptocamp SA <http://www.camptocamp.com/en/>`__.

You can either build it from scratch from `the source <https://github.com/mapfish/mapfish-print>`__ or use our `last build </data/getting-started/print.war>`__. Once you have the WAR, do the following actions as root:

  - Copy the WAR in your tomcat webapps folder (eg ``/usr/share/tomcat/webapps``, ``/srv/tomcat/webapps/`` or ``/var/lib/tomcat8/webapps``) under the name ``print-customer-infra.war``.
  - Start tomcat: ``systemctl start tomcat``

    .. attention::

      On Debian based systems, the target is named ``tomcat8``

  - Go to the tomcat webapps folder.
  - Check that ``print-customer-infra.war`` is correctly deployed.
  - Create the ``print-customer-infra/print-apps`` directory and make it owned by tomcat: ``mkdir print-customer-infra/print-apps && chown tomcat:tomcat print-customer-infra/print-apps``.

    .. attention::

      On Debian based systems, the correct user is ``tomcat8``.

  - Check and correct permissions on ``<tomcat-webapps>/print-customer-infra/print-apps``:

    - Check that with the user defined by ``$PROD_USER`` you can access this directory. If ``ls <tomcat-webapps>/print-customer-infra/print-apps`` returns successfuly, you are good to go. If not, correct the permissions to give it read and execute access on all folders on the path.
    - Setup ACL to give the user write permissions to the directory (**don't use standard unix permissions, it breaks tomcat's expectations**): ``setfacl -m u:<user>:rwx print-customer-infra/print-apps``.

  - Check that tomcat has an AJP connector defined on port 8009 in ``/etc/server.xml``. If not, add the line below in the ``<Service name="Catalina">`` section:

    .. code:: xml

      <Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />

  - Restart tomcat ``systemctl resart tomcat``
  - Enable tomcat ``systemctl enable tomcat``


Search
------

.. Keep in sync with the getting started

On `sphinx search <http://sphinxsearch.com/>`__ is correctly installed on your system, do the following actons as root to configure it:

- Add a symlink to the global sphinx configuration. Depending when you set it up, this file may not exist yet. It will be in ``$PROD_GIT_REPOS_LOCATION/search/sphinx.conf``. See the section about `Production configurations`_ of this document to learn more about ``$PROD_GIT_REPOS_LOCATION``.

  .. code:: bash

     ln -s <PROD_GIT_REPOS_LOCATION>/search/sphinx.conf /etc/sphinx/customer-infra.conf

  .. attention::

    On Debian based systems, before creating the symlink, you must (*as root*):

      - Create the ``/etc/sphinx/`` directory: ``mkdir /etc/sphinx/``
      - Change its owner to ``sphinxsearch``: ``chown -R sphinxsearch:sphinxsearch /etc/sphinx``

- Create sphinx infrastructure specific directories:

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

- Deploy the unit files for this infrastructure:

  - Copy the ``searchd@.service`` service file from ``geo-infra`` to ``/etc/systemd/system/``

    .. attention::

      On Debian based systems, you must correct the user to ``sphinxsearch``

  - Reload systemd daemons: ``systemctl daemon-reload``

- Enable the sphinx daemon: ``systemctl enable searchd@customer-infra.service``


.. _ref_sysadmin_server-setup_api:

API
---

#. On the production server, either:

   - Clone the api for the first deploy: ``git clone https://github.com/ioda-net/geo-api3.git``
   - Update the API: ``git pull``

   .. note::

    Depending on who you are, you may:

       - get the code of the API from another location
       - need to switch to a custom branch.

#. Update the configuration of the API for this deployment. To do this, create a file named ``geo-api3/config/config.<branchname>.toml`` and override any values necessary from the ``geo-api3/config/config.dist.toml`` config file.
#. Override any commands necessary in ``geo-api3/config/config.dist.sh`` by creating a ``geo-api3/config/config.sh`` file.
#. Deploy the API: on the production server, in the ``geo-api3`` folder, launch: ``./manuel deploy``
#. Add a new vhost for the API. It should look like the vhost below. Adapt the user names and file paths to match those defined in the ``geo-api3/config/config.<branchname>.toml``.

   .. literalinclude:: /_static/config/api-vhost.conf
    :language: apache
