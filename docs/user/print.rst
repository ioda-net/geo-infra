.. _ref_user_print:

Print
=====

.. contents::

This page explains how to configure MapFish Print for the impression feature of the portal.

You can find a WAR `here </data/getting-started/print.war>`__ or you can build `from the source <https://github.com/mapfish/mapfish-print/>`__.

You can view examples of print templates `here <https://github.com/ioda-net/customer-infra/tree/master/print>`__. You can create your print templates with `Jasper Studio <http://community.jaspersoft.com/project/jaspersoft-studio>`__ or directly by editing the jrxml files with a text editor.

The offical documentaton is `here <https://mapfish.github.io/mapfish-print-doc/>`__.


Scalebar
--------

You will find below the list of available options for the scalebar subreport. This list of available options is taken from `ScalebarAttributer.java <https://github.com/mapfish/mapfish-print/blob/master/core/src/main/java/org/mapfish/print/attribute/ScalebarAttribute.java>`__.

To enable the scalebar, you must add the scalebar section in the ``config.yaml`` file and add the scalebar subreport in your JRXML template.

- ``type``: The scalebar type. Can be any of:

  - ``bar`` (*default*): A thick bar with alternating black and white zones marking the intervals. The colors can be customized by changing the properties ``color`` and ``barBgColor``.
  - ``line``: A simple line with graduations.
  - ``bar_sub``: Like "bar", but with little ticks for the labels.

- ``unit``: The unit to use. Can be any of:

  - m (mm, cm, m or km)
  - ft (in, ft, yd, mi)
  - degrees (min, sec, °)

  If the value is too big or too small, the module will switch to one of the unit in parenthesis (the same unit is used for every interval). If this behaviour is not desired, the ``lockUnits`` parameter will force the declared unit (or map unit if no unit is declared) to be used for the scalebar.

- ``geodetic``: Use geodetic measurement calculations for the scalebar (*default*: false). Can be either ``true`` or ``false``.
- ``lockUnits``: Force that the given unit is used (*default*: false). For example if the unit is set to meters and `lockUnits` is enabled, then meters is always used, even when kilometers would create nicer values. Can be either ``true`` or ``false``.
- ``intervals``: The number of intervals. This must be an integer greater than 2 (*default*: 3). **There must be at least two intervals.**
- ``subIntervals``:  Should sub-intervals be shown? (*default*: false) The main intervals are divided into additional sub-intervals to provide visual guidance. The number of sub-intervals depends on the length of an interval. Can be either ``true`` or ``false``.
- ``barSize``: The thickness of the bar or the height of the tick marks on the line (in pixel). This must be an integer.
- ``lineWidth``: The thickness of the lines or the bar border (in pixel). This must be an integer.
- ``labelDistance``: The distance between scalebar and labels (in pixel). This must be an integer.
- ``padding``: The padding around the scalebar (in pixel). This must be an integer.
- ``font``: The font used for the labels (*default*: Helvetica).
- ``fontSize``: The font size (in pt) of the labels (*default*: 12).
- ``fontColor``: The font color of the labels (*default*: black). This can be a color name (eg ``"black"``, ``"white"``), an hexadecimal value (eg ``#000000``) or an RGBA value (eg ``rgba(0, 0, 0, 0)``)
- ``color``: The color used to draw the bar and lines (*default*: black). This can be a color name (eg ``"black"``, ``"white"``), an hexadecimal value (eg ``#000000``) or an RGBA value (eg ``rgba(0, 0, 0, 0)``)
- ``barBgColor``: The color used to draw the alternating blocks for style "bar" and "bar_sub" (*default*: white). This can be a color name (eg ``"black"``, ``"white"``), an hexadecimal value (eg ``#000000``) or an RGBA value (eg ``rgba(0, 0, 0, 0)``)
- ``backgroundColor``: The background color for the scalebar graphic (*default*: rgba(255, 255, 255, 0)). This can be a color name (eg ``"black"``, ``"white"``), an hexadecimal value (eg ``#000000``) or an RGBA value (eg ``rgba(0, 0, 0, 0)``)
- ``orientation``: The scalebar orientation. Available options:

  - ``"horizontalLabelsBelow"`` (*default*): Horizontal scalebar and the labels are shown below the bar.
  - ``"horizontalLabelsAbove"``: Horizontal scalebar and the labels are shown above the bar.
  - ``"verticalLabelsLeft"``: Vertical scalebar and the labels are shown left of the bar.
  - ``"verticalLabelsRight"``: Vertical scalebar and the labels are shown right of the bar.

- ``align``: The horizontal alignment of the scalebar inside the scalebar graphic. Can be any of:

  - ``left`` (*default*).
  - ``right``

- ``verticalAlign``: The vertical alignment of the scalebar inside the scalebar graphic. Can be any of:

  - ``bottom`` (*default*)
  - ``top``

- ``renderAsSvg``: Indicates if the scalebar graphic is rendered as SVG (*default*: false). Can be either ``true`` or ``false``.
- ``size``: The size of the scalebar graphic in the Jasper report (in pixels). This must be an integer.

Example:

.. code:: yaml

    scalebar: !scalebar
        width: 130
        height: 20
        default:
          type: line
          unit: m
          intervals: 3
          fontSize: 8
          align: "right"
          backgroundColor: "white"

