API
====

The API is written in `Python 3 <https://python.org>`__ with the `Pyramid web framework <http://www.pylonsproject.org/>`__.

.. contents::


Setup
-----

Requirements
~~~~~~~~~~~~

- The following libraries are needed to correctly create the python venv:

   - geos
   - geos-devel
   - postgresql-devel
   - libxml2-devel
   - libxslt-devel
   - python3-devel
   - gcc

   On debian based system, use this list:

   - libgeos-c1
   - libgeos-dev
   - libxml2-dev
   - libxslt-dev
   - python3-dev
   - gcc

- `GDAL <http://www.gdal.org>`__ 2.0 or above with Python3 bindings
- `Python <https://www.python.org/>`__ 3.4 or above with virtualenv capabilities (probably in the ``python3-venv`` package or included in your Python 3 installation)
- If you don't want to use a venv as suggested below to install the Python dependencies, you will find the list of packages to install on your system with their minimal version in the `requirements.txt <https://github.com/ioda-net/geo-api3/blob/devel/requirements.txt>`__.

Configuration
~~~~~~~~~~~~~

The configuration is written in the `TOML format <https://github.com/toml-lang/toml>`__. It is loaded like this:

#. ``config/config.dist.toml``
#. ``config/config.<branchname>.toml`` *optional*

You can customize the configuration for the branch you are on in ``config/config.<branchname>.toml``. The keys used in it, will override any values loaded from ``config/config.dist.toml``. Without this configuration file, configuration will only come from ``config/config.dist.toml``.

Create the venv
~~~~~~~~~~~~~~~

- Create the proper venv with ``./manuel venv``
- Update the ini files used by Pyramid: ``./manuel ini-files``. You can check that the values in ``production.ini`` (contains database related configuration) and ``development.ini`` (imports the ``production.ini`` configuration file and contains development specific values) are correct.


Serve
-----

To launch ``pserve`` with the development configuration: ``manuel serve``. To launch ``pserve`` on a specific branch, use ``manuel serve BRANCH``.

.. warning::

    If the command fails due to ``ImportError: No module named 'osgeo'``, check that the osgeo module from system install is available in the ``PYTHONPATH`` specificied in ``config/config.dist.sh``. If not, create a ``config/config.sh`` with the correct value for ``PYTHONPATH``. Eg for Debian, put this value:

      .. code:: shell

        export PYTHONPATH=".venv/lib/python${PYTHON_VERSION}/site-packages:/usr/lib/python3/dist-packages:$(pwd)"


Deploy
------

Use manuel, **on the production server**: ``manuel deploy``.


.. _ref_dev_api_search-keywords:

Search keywords
---------------

In order to add a keyword, you must edit ``geo-api3/chsdi/customers/utils/search.py``. If you edit the file on devel, then the keywords will be used for all customer (on next merge). If you edit it in a customer specific branch, then it will only be available for this customer.

To add a keyword, you must add a ``SearchKeywords`` namedtuple to the ``SEARCH_KEYWORDS`` tuple, like this:

.. code:: python

    SEARCH_KEYWORDS = (
        SearchKeywords(
            keywords=('addresse', 'adresse', 'indirizzo', 'address'),
            filter_keys=['places']
        ),
    )

.. note::

    The ``SearchKeywords`` namedtuple has two members:

    - ``keywords``: the list of keywords that the user can use.
    - ``filter_keys``: the list of index names associated with these keywords.


Tests
-----

- To launch all the tests, use: ``manuel test``
- To launch only some tests, pass the proper arguments to ``manuel test``. You can pass it as many files and   options recognized by `nose <https://nose.readthedocs.org/en/latest/>`__ as you want. For instance:

.. code:: bash

    manuel test chsdi/tests/integration/test_file_storage.py


Update from mf-chsdi3
---------------------

Update our mf-chsdi fork
~~~~~~~~~~~~~~~~~~~~~~~~

#. Go where you cloned `our fork of mf-chsdi <https://github.com/ioda-net/mf-chsdi3>`__
#. Fetch the modifications made by Swisstopo. Typically this is done by:

   .. note::

       The you must add an upstream remote pointing to https://github.com/geoadmin/mf-chsdi3. You can add it with ``git remote add upstream https://github.com/geoadmin/mf-chsdi3.git``.

   #. ``git checkout master``
   #. ``git fetch upstream master``
   #. ``git rebase upstream/master``
   #. ``git push``


Update geo-api3
~~~~~~~~~~~~~~~

#. Go where you clone `geo-front3 <https://github.com/ioda-net/geo-front3>`__.
#. Go the the `master` branch and update it with the code of swisstopo. Typically this is done by:

   .. note::

       The you must add an upstream remote pointing to https://github.com/ioda-net/mf-chsdi3. You can add it with ``git remote add upstream https://github.com/ioda-net/mf-chsdi3.git``.

   #. ``git checkout master``
   #. ``git fetch upstream master``
   #. ``git rebase upstream/master``

#. Identify the commits you want to cherry pick by their hash.
    Use github history, mail 
#. Go to the branch ``devel``: ``git checkout devel``
#. Cherry pick the commits with ``git cherry-pick HASH``
#. Solve the merge conflicts if any.
#. Run the tests: ``manuel test``
#. Push the result. **If the push fails because you have unpulled changes, do not try a rebase**: a rebase will cancel your merge commit (and will loose your merge work, unless you do a ``git rebase --abort``) and you will have to handle conflict for each commit from swisstopo you are merging into the current branch. So if that happens, do:

   #. ``git fetch origin devel`` to get the changes.
   #. ``git merge origin/devel`` to merge them with a merge commit into your local branch.
   #. ``git push`` to push the result.


Lint
----

Use ``manuel lint``.


Recommended hooks
-----------------

git hooks allow you to launch a script before or after a git command. They are very handy to automatically perform checks. If the script exits with a non 0 status, the git command will be aborted. You must write them in the `.git/hooks/` folder in a file following the convention: ``<pre|post>-<git-action>``. You must not forget to make them executable, eg: ``chmod +x .git/hooks/pre-commit``.

In the case you don't want to launch the hooks, append the ``--no-verify`` option to the git command you want to use.

pre-commit
~~~~~~~~~~

.. code:: bash

    manuel lint || exit 1

pre-push
~~~~~~~~

.. code:: bash

    manuel check || exit 1


Launch with uWSGI and Unix sockets
----------------------------------

.. note::

    this is still a work in progress. Use the standard WSGI and proxy pass on production.

Apache Configuration
~~~~~~~~~~~~~~~~~~~~

Replace:

.. code:: apache

    ProxyPass /api http://localhost:9090 connectiontimeout=5 timeout=180
    ProxyPassReverse /api http://localhost:9090

By

.. code:: apache

    <Location /api>
        Options FollowSymLinks Indexes
        SetHandler uwsgi-handler
        uWSGISocket /run/uwsgi/geo-api3.sock
    </Location>

uWSGI Configuration
~~~~~~~~~~~~~~~~~~~

In your ``/etc/uwsgi.ini``:

.. code:: ini

    [uwsgi]
    pidfile = /run/uwsgi/uwsgi.pid
    emperor = /etc/uwsgi.d
    stats = /run/uwsgi/stats.sock
    emperor-tyrant = true
    plugins = python3

Adapt your ``config.<branchname>.toml`` to get something like this in ``uwsgi.ini`` (generated with `manuel ini-files`):

.. code:: ini

    [uwsgi]
    chmod-socket = 666
    chown-socket = uwsgi:uwsgi
    chdir = /home/jenselme/Work/geo-api3
    home = /home/jenselme/Work/geo-api3/.venv
    gid = uwsgi
    uid = uwsgi
    ini-paste = /home/jenselme/Work/geo-api3/production.ini
    master = 1
    plugins = python3
    processes = 4
    pythonpath = .venv/lib/python3.5/site-packages
    pythonpath = /usr/lib64/python3.5/site-packages
    pythonpath = /home/jenselme/Work/geo-api3
    socket = /run/uwsgi/geo-api3.sock

.. note::

    Your ``production.ini`` and ``uwsgi.ini`` must be owned by the user ``uwsgi`` and by the group ``uwsgi``.
