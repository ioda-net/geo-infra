Misc
====

Conversion of old CARTOWEB tags
-------------------------------

.. code-block:: bash

   find . -iname "*.map.in" -type f -exec sed -i 's/\(@\)\([A-Z_]*\)\(@\)/{{\2}}/g' {} \;

Replacement of DB variables
---------------------------

.. code-block:: bash

   find . -iname "*.map.in" -type f -exec sed -i 's/{{DB_USER}}/{{PORTAL_DB_USER}}/g' {} \;
   find . -iname "*.map.in" -type f -exec sed -i 's/{{DB_PASSWD}}/{{PORTAL_DB_PASSWORD}}/g' {} \;
   find . -iname "*.map.in" -type f -exec sed -i 's/{{DB_HOST}}/{{PORTAL_DB_HOST}}/g' {} \;
   find . -iname "*.map.in" -type f -exec sed -i 's/{{DB_LOCATE_NAME}}/{{PORTAL_DB_NAME}}/g' {} \;
