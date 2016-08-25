How to deal with code specific to a customer
============================================

.. contents::

In the API
----------

In the API, all codes specific to a customer are grouped into ``chsdi/customers``. This folder is organized like this:

- ``__init__.py`` to create the module.
- ``models/`` to put models specific to a customer. They should only be used in ``chsdi/customers/views/``.
- ``utils/`` for utilities. By default, it contains a ``search.py`` file in which all search keywords are stored. See :ref:`the section about keywords in the API page <ref_dev_api_search-keywords>` to learn more how search keywords are handled.
- ``views/`` for customer specific views. Create a file per view. When you add a view, update the ``register_customer_view`` function from ``__init__.py`` in order for the view to be registered by Pyramid. This should look like:

    .. code:: python

        def register_customer_view(config):
            config.add_route('<route_name>', '/{portal}/<route_name>')


In the frontend
---------------

Plugin System
~~~~~~~~~~~~~

Plugins are a way to have code specific to a customer without changing the rest of the code.

To create a plugin, create a javascript file in ``geo-front3/plugins/``. The file must be named like this: ``<plugin_name>.js``. In this file, put the code you need in your plugin (probably a function). For instance:

.. code:: javascript

    function test() {
        console.log('I am a plugin');
    }

While writing the code of your plugin, keep in mind that it will be included in an object in the template below.

.. literalinclude:: ../../../geo-front3/src/Gf3Plugins.nunjucks.js
    :language: jinja

See the :ref:`section about plugins <ref_user_cfg-protal_plugins>` in the user manual to know how to active them.

They can the be used with the ``gf3Plugins`` service. For instance, to use a plugin named test plugin, use ``gf3Plugins.test()``. The arguments and behavior of the plugin depends on its definition.

To test if a plugin is enabled, test ``gf3Plugins.plugin_name !== undefined``.


.. _ref_dev_customer_features:

Features
~~~~~~~~

In ``geo-front3/src/components/features/FeaturesTemplatesService.js``, we defined how each features will be rendered. Templates available for all customers must be in the ``defaultTemplates`` object from the ``devel`` branch. You can set customer specific templates in the ``customerTemplates`` object on their branch. Each of these object must follow this rule:

- The key will be how the name of the column must end
- The content must be the HTML used to render the cell within a string (so it is valid javascript).

For instance to render a cell whose name ends in ``_url`` as a clickable link, we need this HTML:

.. code:: HTML

  <div>
      <a target="_blank" href="{{cellValue}}" ng-if="cellValue">
          {{ cellValue | translate  }}
      </a>
  </div>

We will use this code:

.. code:: javascript

    defaultTemplates['url'] = '<div>' +
            '<a target="_blank" href="{{cellValue}}" ng-if="cellValue">' +
            '{{cellValue | translate  }}</a></div>';

The template will then be used in ``geo-front3/src/components/features/FeaturesService.js`` as the template to render the cell in `Ultimate Data Table <http://ultimate-datatable.readthedocs.org/>`__.

See the :ref:`relevant section <ref_user_cfg-portal_identify-features_special-columns-features>` of the user documentation to see what is handled by default.
