Setup the server for the deploy of a portal
===========================================

.. contents::


First deploy on a server
------------------------

#. Create the directories in which needed for the deploy. Reefer to `the section about production configurations in server setup <./server-setup.html#production-configurations>`__ to learn how to configure it.

    - ``$PROD_GIT_REPOS_LOCATION``
    - ``$PROD_BARE_GIT_REPOS_LOCATION``: this may be on a different server and rely on HTTPS instead of SSH. git repositories accessible in this location must be clonable by the user.

#. Create the global git repositories for search and vhosts in ``$PROD_BARE_GIT_REPOS_LOCATION`` with the name ``search.git`` and ``vhosts.d.git``. This can be done in ``$PROD_BARE_GIT_REPOS_LOCATION`` with:

   - ``git init --bare search.git``
   - ``git init --bare vhosts.d.git``

#. Ask the user to init these repositories for production with (in ``geo-infra`` and ``$INFRA_DIR`` pointing to the proper infrastructure directory):

    - ``manuel init-prod-repo search``
    - ``manuel init-prod-repo vhosts.d``


Deploy of a new portal
----------------------

#. Create the bare repository for the portal in ``$PROD_BARE_GIT_REPOS_LOCATION`` named like this ``<portal>.git``. This can be done with: ``git init --bare <portal>.git``
#. Ask the user to init these repositories for production with (in ``geo-infra`` and ``$INFRA_DIR`` pointing to the proper infrastructure directory): ``manuel init-prod-repo <portal>``
