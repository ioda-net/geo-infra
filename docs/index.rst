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

To get help about any task, use ``manuel help TASK``. For instance, ``manuel
help help``.

To build this documentation in HTML under ``_build/html``, use:

.. code-block:: bash

   manuel build-doc


Contents
========

.. toctree::
   :maxdepth: 1

   infra/geo-infra.md
   manuel.md
   functionnal-tests.rst
   api/geo-api3.md
   front/geo-front3.md
   infra/index.rst
   api/index.rst
   front/index.rst
   swisstopo/swisstopo.rst
   misc.rst


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
