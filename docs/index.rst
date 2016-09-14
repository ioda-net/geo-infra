.. Documentation for geo-front3, geo-api3 and geo-infra documentation master file, created by
   sphinx-quickstart on Wed Dec  2 14:40:15 2015.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Documentation for geo-front3, geo-api3 and geo-infra
====================================================

This is the documentation for the following projects:

- `geo-api3 <https://github.com/ioda-net/geo-api3>`__
- `geo-front3 <https://github.com/ioda-net/geo-front3>`__
- `geo-infra <https://github.com/ioda-net/geo-infra>`__

It can be seen `here <https://docs.geoportal.xyz/>`__. The sources are available `here <https://github.com/ioda-net/geo-infra>`__.

This documentation is also available in `French </fr>`__.


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


Future evolutions
=================

You can view the list of future evolutions and how we plan them to work on the dedicated page :ref:`here <rfc-index>`.


Notes on code from upstream
===========================

To learn more about how the code of `mf-geodamin3 <https://github.com/geoadmin/mf-geoadmin3>`__ and `mf-chsdi3 <https://github.com/geoadmin/mf-chsdi3>`__ from Swisstopo works, have a look at these sections:

.. toctree::
    :maxdepth: 2

    swisstopo/swisstopo.rst


About this documentation
========================

Most of the files use either the markdown syntax, plain html or the `Restructured Text <http://docutils.sourceforge.net/docs/index.html>`__ syntax. Currently, the documentation is written partially in English and French.

For new files, please use RST and English unless you have a good reason not to.

This documentation is built with `sphinx-doc <http://www.sphinx-doc.org/en/stable/>`__. In addition to sphinx, you will need the pulgins below to build the documentation:

- The theme `sphinx_py3doc_enhanced_theme <https://pypi.python.org/pypi/sphinx_py3doc_enhanced_theme>`__.
- `sphinx-intl <https://pypi.python.org/pypi/sphinx-intl>`__ to build in multiple languages and update the po files.
- `recommonmark <https://pypi.python.org/pypi/recommonmark>`__ to build the files written in `Markdown <http://daringfireball.net/projects/markdown/>`__.

To build this documentation in HTML under ``_build/html`` for all supported languages, use:

.. code-block:: bash

   manuel build-doc

To update the po files for the translations, use this:

.. code-block:: bash

    manuel update-doc-translations

You can then edit the po to translate the documentation. Contributions are welcomed.


Credits
=======

`manuel <https://github.com/ShaneKilkelly/manuel>`__ is a task runner for Bash and was created by Shane Kilkelly. It is released under the MIT License.

`geo-front3 <https://github.com/ioda-net/geo-front3>`__ and `geo-api3 <https://github.com/ioda-net/geo-api3>`__ are based on `mf-geoadmin3 <https://github.com/geoadmin/mf-geoadmin3>`__ and `mf-chsdi3 <https://github.com/geoadmin/mf-chsdi3>`__.
Those two softwares were created by `swisstopo <https://www.swisstopo.admin.ch/>`__ the Federal Office of Topography of Switzerland for their geoportal `map.geo.admin.ch <https://map.geo.admin.ch>`__.
They are released under the BSD licence.

`geo-front3 <https://github.com/ioda-net/geo-front3>`__ and `geo-api3 <https://github.com/ioda-net/geo-api3>`__ were forked and adapted to modernize the geoportals proposed by `sigeom sa <https://www.sigeom.ch/>`__ a Swiss civil engineer, GIS specialist and land surveying company.
The adaptation was performed by `Ioda-Net Sàrl <https://ioda-net.ch/>`__ a Swiss company specialized in Open Source software.

The following companies give financial support, help to keep this software up to date with swisstopo code, and open source:

- `sigeom sa <https://www.sigeom.ch>`__ 2740 Moutier, Switzerland
- `Ioda-Net Sàrl <https://ioda-net.ch/>`__ CH-2947 Charmoille, Switzerland

Want to help too? `contact (at) geoportal (dot) xyz <mailto:contact(at)geoportal.xyz>`__



Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
