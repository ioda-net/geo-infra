.. _debug:

Debug
=====

Some information on how to debug some scripts.


.. _debug-configuration:

Configuration
-------------

You can view the configuration for any portal with which config files are loaded in which order with ``manuel config <PORTAL>``. To view only the configuration, use:

.. code:: bash

    manuel config demo 2> /dev/null

To view only which files are loaded and in which order, use:

.. code:: bash

    manuel config demo > /dev/null

You can extract any value from the configuration with the `jq command line tool <http://stedolan.github.io/jq/>`__ like this:

.. code:: bash

    manuel config demo 2> /dev/null | jq '.vhost'

You will get a result like:

.. code:: json

    {
        "api_proxy": "http://localhost:9080",
        "certificate_chain_file": "",
        "certificate_file": "",
        "certificate_key_file": "",
        "domain": "geoportal.local",
        "ows_path": "/home/jenselme/Work/geoportal-infras/cgi-bin/",
        "print_proxy": "ajp://localhost:8009",
        "prod_data_dir": "/var/lib/geoportal/data",
        "server_name": "demo.geoportal.local"
    }


generate_json.py
----------------

Launching the python dev server to view the GetCapabilities
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Start a Python 3 shell in ``geo-infra`` and type:

.. code:: python

    from scripts.generate_utils import cgi_server

    cgi_server()

Then to the corresponding request, eg ``wget http://localhost:8888/cgi-bin/mapserv?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities``
