.. _ref_debug:

Debug
=====

Some information on how to debug some scripts or tools.

.. contents::


.. _ref_debug_configuration:

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


.. _ref_debug_print:

Print
-----

- *Image read failed*: Check that the API is working correctly and that you can have a QR code for the printed permalink.
- *Target host is null*: Check that all the necessary images are present in MFP's ``print-apps`` folder.
- Spring/authentication related: check that `this patch <https://github.com/ioda-net/geo-infra/blob/master/patches/mfp-remove-basic-auth-security.patch>`__ was correctly applied to your ``print-customer-infra/WEB-INF/web.xml``.
- Max size related check that `this patch <https://github.com/ioda-net/geo-infra/blob/master/patches/mfp-correct-max-request-size.patch>`__ was correctly applied to your ``print-customer-infra/WEB-INF/web.xml``. If necessary, increase the max content length value.

OWS Requests
------------

If all your OWS requests respond with a 404 error, check that you have a trailing slash in your value of ``vhost.ows_path`` like that:

.. code:: ini

   [vhost]
   ows_path = '/var/lib/geoportal/cgi-bin/'


Installing GDAL in a venv
-------------------------

If you don't want to install GDAL globally or just want to put everything in the virtual env, you can use the steps bellow to install GDAL in a virtual env:

#. Install ``gdal-devel`` to be able to build the module
#. Enable the virtual venv
#. Download GDAL ``pip download GDAL`` If you don't want to install the latest version you can specify it like this ``pip download GDAL==2.0.1``
#. Uncompress the archive: ``tar -xzf GDAL-2.1.0.tar.gz`` (adapt the version if needed).
#. Go to the decompressed folder ``cd GDAL-2.1.0``
#. Build it: ``python setup.py build_ext --include-dirs=/usr/include/gdal`` (adapt the include path if necessary)
#. Install it: ``python setup.py install -O1 --skip-build``
