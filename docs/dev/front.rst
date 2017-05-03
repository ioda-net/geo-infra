Front
=====

The front is written is JavaScript with the `AngularJS <https://angularjs.org/>`__ framework and rely on the `Google Closure Compiler <https://developers.google.com/closure/compiler/>`__ to work.

The build process relies on `geo-infra <https://github.com/ioda-net/geo-infra>`__. Before building the project, you must run ``manuel update`` in ``geo-infra`` in order to download all the dependencies (npm modules, `ngeo <https://github.com/camptocamp/ngeo>`__).

.. contents::


Update from map.geo.admin.ch
----------------------------

Update our mf-geoadmin3 fork
++++++++++++++++++++++++++++

#. Go where you cloned `our fork of mf-geoadmin3 <https://github.com/ioda-net/mf-geoadmin3>`__
#. Fetch the modifications made by Swisstopo. Typically this is done by:

    .. note::

       The you must add an upstream remote pointing to https://github.com/geoadmin/mf-geoadmin3. You can add it with ``git remote add upstream https://github.com/geoadmin/mf-geoadmin3.git``.

   #. ``git checkout master``
   #. ``git fetch upstream master``
   #. ``git rebase upstream/master``
   #. ``git push``


Update geo-front3
++++++++++++++++++

#. Go where you clone `geo-front3 <https://github.com/ioda-net/geo-front3>`__.
#. Go the the `master` branch and update it with the code of swisstopo. Typically this is done by:

    .. note::

       The you must add an upstream remote pointing to https://github.com/ioda-net/mf-geoadmin3. You can add it with ``git remote add upstream https://github.com/ioda-net/mf-geoadmin3.git``.

   #. ``git checkout master``
   #. ``git fetch upstream master``
   #. ``git rebase upstream/master``

#. Go to the branch ``devel``: ``git checkout devel``
#. Merge ``master`` into ``devel``: ``git merge master``
#. Solve the merge conflicts. See `Some tips to resolve merge conflicts`_ for help.
#. Check that the patches applied to ngeo are still relevant and remove them if necessary. To do that, check the changelog for the version of ngeo you use. The patches are located in ``geo-front3/scripts/ngeo-patches`` if there are patches to apply.
#. Update the dependencies: launch from ``geo-infra``: ``manuel update``.
#. Check that the patches applied to OpenLayers are still relevant and remove them if necessary. To do that, check the changelog for the version of OpenLayers you use. The patches are located in ``scripts/ol3-patches``.
#. Update OpenLayers: ``./scripts/update-open-layers.sh``
#. Update the translations: launch from ``geo-infra`` ``manuel update-translations-swisstopo``
#. Run the tests: launch from ``geo-infra``: ``manuel launch-tests``
#. If ``src/index.mako.html`` changed, port the modifications to ``src/index.nunjucks.html``
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

New components
++++++++++++++

Normally, they should not be in the merge conflicts:

- features
- webdav


How to update Open Layer
------------------------

We need to build our own version of ``ol.js`` since we need some exports that Swisstopo doesn't. In order to do this, we have a scrip called ``update-open-layers.sh``. Before committing the merge result, please launch it (you must be in the root folder of geo-front3):

.. code:: bash

    ./scripts/update-open-layers.sh

The script will do everything for you. If the ``Makefile`` was updated by Swisstopo, check whether it impacts how OpenLayers is updated. If so, update the script accordingly before launching it.
