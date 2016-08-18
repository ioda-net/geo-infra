.. Documentation for geo-front3, geo-api3 and geo-infra documentation master file, created by
   sphinx-quickstart on Wed Dec  2 14:40:15 2015.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Documentation for geo-front3, geo-api3 and geo-infra
====================================================

Location: https://github.com/ioda-net/geo-infra

This is the documentation for the following projects:

- `geo-api3 <https://github.com/ioda-net/geo-api3>`__
- `geo-front3 <https://github.com/ioda-net/geo-front3>`__
- `geo-infra <https://github.com/ioda-net/geo-infra>`__


General
=======

.. toctree::

    getting-started.rst

.. toctree::
    :maxdepth: 1

    infra.rst
    manuel.md
    debug.rst
    misc.rst


Content
=======

Who are you?

- *Users*, in this documentation, are those who manage a specific customer infrastructure: creation of portal (configuration, help website, searches, definition of get features), deployment of the portals. They can be helped by the developers or the system administrators to perform some tasks.
- *Developers* write code in `geo-api3 <https://github.com/ioda-net/geo-api3>`__, `geo-front3 <https://github.com/ioda-net/geo-front3>`__ and `geo-infra <https://github.com/ioda-net/geo-infra>`__. They may occasionally help the user or the system administrators to perform their tasks.
- *System administrators* are in charge of the administration of the servers and databases. They are mostly present to help set up the infrastructure for the first time on their servers (installation of dependencies, configuration of system daemons, creation of the git repositories to deploy a portal to production). Once the setup is done, the users should be able to manage most of the things by themselves. They may still take action from times to time to update packages or redeploy the API.

.. toctree::
    :maxdepth: 1

    user/index.rst
    dev/index.rst
    sysadmin/index.rst


Notes on code from upstream
===========================

To learn more about how the code of `mf-geodamin3 <https://github.com/geoadmin/mf-geoadmin3>`__ and `mf-chsdi3 <https://github.com/geoadmin/mf-chsdi3>`__ from Swisstopo works, have a look at these sections:

.. toctree::
    :maxdepth: 2

    swisstopo/swisstopo.rst


About this documentation
========================

Most of the files use either the markdown syntax, plain html or the Restructured
Text syntax. Currently, the documentation is written partially in English and
French.

For new files, please use RST and English unless you have a good reason not to.

To build this documentation in HTML under ``_build/html``, use:

.. code-block:: bash

   manuel build-doc


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
