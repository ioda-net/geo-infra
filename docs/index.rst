.. Documentation for geo-front3, geo-api3 and geo-infra documentation master file, created by
   sphinx-quickstart on Wed Dec  2 14:40:15 2015.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Documentation for geo-front3, geo-api3 and geo-infra
====================================================

Location: https://github.com/ioda-net/geo-infra

This is the documentation for the following projects:

- geo-api3
- geo-front3
- geo-infra

Most of the files use either the markdown syntax, plain html or the Restructured
Text syntax. Currently, the documentation is writtent partially in English and
French.

For new files, please use RST and English to write the doc.

All tasks are launched here with `manuel
<https://github.com/ShaneKilkelly/manuel>`__, a task runner written in Bash. To
enable autocompletion in a Bash shell, source the ``manuel.autocomplete.bash``
file. Completion is also `available for zsh
<https://github.com/ShaneKilkelly/manuel/blob/master/manuel.autocomplete.zsh>`__.
To launch ``manuel`` without always appending ``./`` copy it to your ``~/bin``
folder.

To get help about any task, use ``manuel help TASK``. For instance, ``manuel
help help``.

To build this documentation in HTML under ``_build/html``, use:

.. code-block:: bash

   manuel build-doc


Contents
========

.. toctree::
   :maxdepth: 1

   getting-started.rst
   create-portal.rst
   debug.rst
   manuel.md
   functionnal-tests.rst
   infra/index.rst
   api/index.rst
   front/index.rst
   misc.rst


Swisstopo
=========

To learn more about how the code of `mf-geodamin3 <https://github.com/geoadmin/mf-geoadmin3>`__ and `mf-chsdi3 <https://github.com/geoadmin/mf-chsdi3>`__ from Swisstopo works, have a look at these sections:

.. toctree::
    :maxdepth: 2

    swisstopo/swisstopo.rst


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
