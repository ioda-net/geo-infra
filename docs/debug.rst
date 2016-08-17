Debug
=====

Some information on how to debug some scripts.

generate_json.py
----------------

Launching the python dev server to view the GetCapabilities
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Start a Python 3 shell in ``geo-infra`` and type:

.. code:: python

    from scripts.generate_utils import cgi_server

    cgi_server()

Then to the corresponding request, eg ``wget http://localhost:8888/cgi-bin/mapserv?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities``
