.. _ref_sysadmin_deploy-setup:

Setup the server for the deploy of a portal
===========================================

Before reading this document, you should read and follow the steps detailed in :ref:`server setup <ref_sysadmin_server-setup>`.

.. contents::


First deploy on a server
------------------------

#. Create the directories needed for the deploy. Reefer to :ref:`the section about production configurations in server setup <ref_sysadmin_server-setup_production-cfg>` to learn how to configure it.

    - ``$PROD_GIT_REPOS_LOCATION``
    - ``$PROD_BARE_GIT_REPOS_LOCATION``: this may be on a different server and rely on HTTPS instead of SSH. git repositories accessible in this location must be clonable by the user.

#. Create the global git repositories for search and vhosts in ``$PROD_BARE_GIT_REPOS_LOCATION`` with the name ``search.git`` and ``vhosts.d.git``. This can be done in ``$PROD_BARE_GIT_REPOS_LOCATION`` with:

   - ``git init --bare search.git``
   - ``git init --bare vhosts.d.git``

#. Ask the user to init these repositories for production with (in ``geo-infra`` and ``$INFRA_DIR`` pointing to the proper infrastructure directory):

    - ``manuel init-prod-repo search``
    - ``manuel init-prod-repo vhosts.d``


.. _ref_sysadmin_deploy-setup_deploy-new-portal:

Deployment of a new portal
--------------------------

#. Create the bare repository for the portal in ``$PROD_BARE_GIT_REPOS_LOCATION`` named like this ``<portal>.git``. This can be done with: ``git init --bare <portal>.git``
#. Ask the user to init these repositories for production with (in ``geo-infra`` and ``$INFRA_DIR`` pointing to the proper infrastructure directory): ``manuel init-prod-repo <portal>``
#. Create the symlink to your MapServe executable named like ``<portal>`` in the directory defined by ``vhost.ows_path`` from ``customer-infra/config/_common.dist.toml``
