Functional tests
================

.. contents::


Translations
------------

- Change the language of the geoportal.
- **Results:** The interface is translated in the corresponding language.


Background selector
-------------------

On mobile
~~~~~~~~~

- Switch to the mobile interface.
- **Results:** The background selector must be there in the bottom left corner.
- Click on the background selector.
- **Results:** All the background layers must be visible each one above the
  others.

On desktop
~~~~~~~~~~

- **Results:** The background selector must be present in the bottom right
  corner.
- Click on the background selector.
- **Results:** All background layers must be visible, side by side on a
  horizontal line.


Layer selection
---------------

- Open the ``Maps Displayed`` panel.
- You should be able to select/unselect layers by click on their name or the
  checkbox left of their name.
- **Results:** the layer appears/disappears on the map.
- You should be able to remove a layer by clicking on the cross at the left of
  the layer name.
- **Results:** the layer disappears from the map, from the layer selector and
  the permalink.
- Click on the gear icon right of a layer name.
- **Results:** the layer configuration panel appears.
- Change the transparency of a layer.
- **Results:** the transparency of the modified layer must be updated on the
  map.
- Use the arrow to change the order of the layers.
- **Results:** the order of the layer on the map and in the permalink must be
  updated.
- Do a long click (~1 second) on a layer.
- **Results:** The name of the layer is displayed in light grey and the layer is
  draggable.
- Drag the layer.
- **Results:** The order of the layer in the layer manager, the permalink and
  the map is updated.
- Click on *Looking for more maps?*
- **Results:** The search bar must be highlighted while the rest of the portal
  is shadowed.


Topic Switch
------------

- Open the current topic.
- Click on a selected layer.
- **Results:** the layer disappears from the map. It is still present in the
  layer selector but it is not selected.
- Click on the same layer again.
- **Results:** The layer is selected in the catalog and layer selector. Its
  position in the layer selector didn't change.
- Click on an unselected layer.
- **Results:** the layer appears on the map and in the layer selector.
- Click on change topic.
- **Results:** a panel listing all the topics must appear.
- Click on a topic.
- **Results:** the topic is correctly updated and all layers from the previous
  topic are removed from the layer selector.


Time selector
-------------

**If you have time enabled layers on your portal.**

- Add this map, for instance *Journey through time - Maps*
- **Results:** there should be a year at the right of the name of the name and a button named *Enable and disable representation of data time stamps* must appear below the other map button on the right of the screen.
- Click on the year.
- **Results:** a selector must appear with all the available years for this map.
- Change the year.
- **Results:** the map must be updated.
- Click on the *Enable and disable representation of data time stamps* button.
- **Results:** the time selector must appear.
- Use the time selector to change the date.
- **Results:** the map must be updated.
- Click on the play button
- **Results:** the time must change automatically and the map must be updated accordingly.


import
------

WMS Import
~~~~~~~~~~

from the list
+++++++++++++

- Open the *Advanced tools* panel.
- Click on *import*.
- **Results:** the import popup must appear.
- In the URL list, select a WMS, for instance: *https://wms.geo.admin.ch/* or *http://www.geoservice.apps.be.ch/geoservice2/services/a42geo/a42geo_basiswms_d_fk/MapServer/WMSServer?*.
- **Results:** The GetCapalities response is correctly parsed and you see the list of the available layers.
- Pass your mouse over *2km2 sub catchment areas* or *UP5*.
- **Results:** layer is previewed on the map.
- Select *2km2 sub catchment areas* or *UP5*.
- Click on *Add to map*.
- **Results:** the selected layer is added to the map, the layer selector and the permalink.
- Close the popup.
- **Results:** the popup is successfully closed.

Other WMS
+++++++++

- Open the *Advanced tools* panel.
- Click on *WMS import*.
- **Results:** the WMS import popup must appear.
- In the input, enter *https://map.geoportal.xyz/ows/geoportalxyz*
- Click on *Connect*
- **Results:** The GetCapalities response is correctly parsed and you see the list of the available layers.
- Pass your mouse over *Transports*.
- **Results:** layer is previewed on the map.
- Click on the plus sign on the left of *Transports*
- **Results:** you should see a list of WMS layers including Aeroways and Roads
- Select Roads
- **Results:** the selected layer is added to the map, the layer selector and the permalink.
- Close the popup.
- **Results:** the popup is successfully closed.

KML
~~~

- Open the *Advanced tools* panel.
- Click on *import*.
- **Results:** The import popup appears.
- Load a KML for your disk
- **Results:** the KML is correctly added to the map.
- Load a KML from a URL, eg for Switzerland `this one </data/functionnal-tests/switzerland.kml>`__.
- **Results:** the KML is correctly added to the map and the view is centered on the KML.
- Load a KML that is outside the portal extent (for instance `the New York KML </data/functionnal-tests/new-york.kml>`__)
- **Results:** Nothing must happen.
- Close the popup.
- **Results:** the popup is successfully closed.


WMTS import
-----------

- Open the *Advanced tools* panel.
- Click on *WMTS import*.
- **Results:** the WMTS import popup must appear.
- In the URL list, select
  *https://wmts.geo.admin.ch/1.0.0/WMTSCapabilities.xml*.
- **Results:** the WMTS capabilities.xml must be correctly parsed and the list
  of all available layers must appear.
- Pass your mouse over *Anomalies de Bouguer 500*.
- **Results:** layer is previewed on the map.
- Select *Anomalies de Bouguer 500*.
- Click on *Add to map*.
- **Results:** the selected layer is added to the map, the layer selector and
  the permalink.
- Close the popup.
- **Results:** the popup is successfully closed.

WMTS import with time series
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Import a WMTS layer that support time series, for instance *Journey through time - Maps*.
- Do the test case for `Time selector`_


Features highlight
------------------

On click
~~~~~~~~

- Check that you have an imported WMS layer and a KML.
- Click on the map.
- **Results:**

  - The features that are returned must be highlighted in yellow.
  - The table of all features appears: each layer has its own tab, in each tab there is the table of features for this layer.
  - There is a tab for each external WMS and KML layer.

- Put the mouse over a line in the features table.
- **Results:** The feature of this line must be highlighted in orange.
- Click on the CSV export button.
- **Results:** You can download a CSV file containing the features for the
  selected tab.
- Switch the language.
- **Results:** The columns of the table and some of its content are translated.
- Click on the close button.
- **Results:** The features popup must be closed correctly.

Rectangle selection
~~~~~~~~~~~~~~~~~~~

- Draw a rectangle with CTR + left click.
- **Results:** Same behaviour as `On click`_.


Share
-----

- Open the *share* panel.
- **Results:** You should see a short link looking like ``https?://HOST/api/shorten/[a-z0-9]*``.
- Copy paste that link in a new tab.
- **Results:** The geoportal is opened with exactly the same parameters as before.


Contextual popup
----------------

- Right click on the map.
- **Results:** the contextual popup must appear with your position, altitude and QR code. On some portals, other information may appear (commune, …).


Search
------

Layers
~~~~~~

- In the search bar, type *Couverture du sol*.
- **Results:** You must see many layers whose name contains *Couverture du sol* under *Add to map*.
- Select *Couverture du sol en couleur*.
- **Results:** the selected layer is added to the map, the layer selector and the permalink. The search results disappear.


Locations
~~~~~~~~~

- In the search bar, type *Moutier*.
- **Results:** You must see under *Go to*, *Moutier* and a list of addresses in Moutier.
- Pass your mouse over *Moutier*.
- **Results:** You must see a marker at the location of *Moutier*.
- Click on *Moutier*.
- **Results:** The map must now be centered on the city of Moutier.

With keywords
~~~~~~~~~~~~~

If available on your portal:

- In the search bar, type *parcelle 3*.
- **Results:** You should only see results of type parcels.

With tokens
~~~~~~~~~~~

- In the search bar, type *limit: 2 moutier*
- **Results:** You should only see two search results concerning Moutier.


Draw
----

- Open the draw panel.
- **Results:** you should now be in drawing mode.
- Click on the map.
- **Results:** Nothing must happen.
- Use the measure tools. Check:

  - lines
  - polygons
  - measure
  - profile
  - text
  - icons
  - delete selected features (in *More*)
  - delete all features (in *More*)

- Click on *Export*.
- **Results:** You must be asked to download your drawing as a KML

Share Drawing
~~~~~~~~~~~~~

- Click on the share button.
- Copy the link named *Link to share your drawing*.
- Open it in a new tab.
- **Results:** You see you drawing as you left it.

Edit Drawing
~~~~~~~~~~~~

- Click on the share button.
- Copy the link named *Link to edit your drawing later*.
- Open it in a new tab.
- **Results:** You see you drawing as you left it.
- Edit the drawing.
- Refresh the page on the original page.
- **Results:** You see your edit.

End
~~~

- Click on *Back / Finish drawing*.
- **Results:** You must be back in standard mode.


Print
-----

- Make sure you have:

  - an imported WMS layer
  - an imported WMTS layer
  - an external WMS layer
  - an external WMTS layer
  - a drawing
  - local layers

- Open the print panel.
- Wait for the configuration to load.
- Enter a title
- Click on *Create PDF for print*
- Wait for the PDF
- **Results:** You should be able to download the PDF, view the selected layers
  and drawing and your title.

Do the same tests with a portal protected by authentication. You must have the same results as before. If your templates allow this, the username used to connect to the portal must be printed.

In case you encounter errors, please check the :ref:`print section the debug page <ref_debug_print>`.


Feedback
--------

- Click on the *Report problem link*.
- Enter the required information.
- Press the *Send* button.
- **Results:** the configured feedback email address must receive an email with the supplied information.


Help
----

Integrated
~~~~~~~~~~

- Click on various help icons in the geoportal.
- **Results:** the corresponding help popup must appear.

Help site
~~~~~~~~~

- Click on the *Help* link.
- **Results:** a new tab to the help site must open.
- Navigate in the help site.
- **Results:** everything must be fine.
