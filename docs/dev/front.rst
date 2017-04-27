Front
=====

The front is written is JavaScript with the `AngularJS <https://angularjs.org/>`__ framework and rely on the `Google Closure Compiler <https://developers.google.com/closure/compiler/>`__ to work.

The build process relies on `geo-infra <https://github.com/ioda-net/geo-infra>`__. Before building the project, you must run ``npm install`` in the directory in which you cloned ``geo-front3`` in order to download all the dependencies. This is required to have some commands in ``node_modules/.bin`` that are needed to build the project.

.. contents::


Update from map.geo.admin.ch
----------------------------

#. Go the the `master` branch and update it with the code of swisstopo. Typically this is done by:

   #. ``git checkout master``
   #. ``git fetch upstream master``
   #. ``git rebase upstream/master``

#. Go to the branch ``devel``: ``git checkout devel``
#. Merge ``master`` into ``devel``: ``git merge master``
#. Solve the merge conflicts. See `Some tips to resolve merge conflicts`_ for help.
#. Update the dependencies: launch from ``geo-infra``: ``manuel update``.
#. Update OpenLayers: ``./scripts/update-open-layers.sh``
#. Commit the result.
#. Push the result. **If the push fails because you have unpulled changes, do not try a rebase**: a rebase will cancel your merge commit (and will loose your merge work, unless you do a ``git rebase --abort``) and you will have to handle conflict for each commit from swisstopo you are merging into the current branch. So if that happens, do:

   #. ``git fetch origin devel`` to get the changes.
   #. ``git merge origin/devel`` to merge them with a merge commit into your local branch.
   #. ``git push`` to push the result.

.. warning::

    Don't forget to do a ``git pull`` and run ``manuel update`` on all the server that'll build the frontend.


Some tips to resolve merge conflicts
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Components removed
++++++++++++++++++

You can safely remove any files related to these components:

- tooltip
- query

Components rewritten
++++++++++++++++++++

You can safely checkout any files that belong to these components:

- print
- wmsimport (rewritten into owsimport)

New components
++++++++++++++

Normally, they should be in the merge conflicts:

- features
- importows
- webdav


How to update Open Layer
------------------------

We need to build our own version of ``ol.js`` since we need some exports that Swisstopo doesn't. In order to do this, we have a scrip called ``update-open-layers.sh``. Before committing the merge result, please launch it (you must be in the root folder of geo-front3):

.. code:: bash

    ./scripts/update-open-layers.sh

The script will do everything for you. If the ``Makefile`` was updated by Swisstopo, check whether it impacts how OpenLayers is updated. If so, update the script accordingly before launching it.
