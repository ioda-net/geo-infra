#!/usr/bin/env python3

import csv
import ogr
import osr
import sys
import unicodedata


def usage():
    print('shape-to-csv.py PATH_TO_INPUT_SHAPE PATH_TO_OUTPUT_CSV')


def main():
    # Inspired by http://gis.stackexchange.com/a/19178
    # This is design to work with the places.shp from Swisstzerland.
    shpfile = sys.argv[1]
    csvfile = sys.argv[2]

    # Open files
    csvfile = open(csvfile,'w')
    ds = ogr.Open(shpfile)
    lyr = ds.GetLayer()

    # Get field names
    fields = ['num', 'weight', 'search_string', 'label', 'origin', 'geom_quadindex', 'geom_st_box2d', 'rank', 'x', 'y', 'lat', 'lon']
    csvwriter = csv.DictWriter(csvfile, fields)

    # Write attributes and kml out to csv
    source = osr.SpatialReference()
    source.ImportFromEPSG(4326)

    target = osr.SpatialReference()
    target.ImportFromEPSG(2056)

    transform = osr.CoordinateTransformation(source, target)

    for i, feat in enumerate(lyr):
        attributes = feat.items()
        if attributes['name'] is None:
            continue
        geom = feat.GetGeometryRef()
        geom_2056 = geom.Clone()
        geom_2056.Transform(transform)
        attributes['num'] = attributes.pop('osm_id')
        attributes['weight'] = i + 1
        # Remove accents in search string. See http://stackoverflow.com/a/15261831
        attributes['search_string'] = ''.join((c for c in unicodedata.normalize('NFD', attributes['name']) if unicodedata.category(c) != 'Mn'))
        attributes['label'] = attributes.pop('name')
        attributes['origin'] = 'places'
        attributes['geom_quadindex'] = 0
        # No space after comma not to break extent parsing in frontend.
        attributes['geom_st_box2d'] = 'BOX({y} {x},{y} {x})'.format(x=geom_2056.GetY(), y=geom_2056.GetX())
        attributes['rank'] = 10
        attributes['x'] = geom_2056.GetY()
        attributes['y'] = geom_2056.GetX()
        attributes['lat'] = geom.GetY()
        attributes['lon'] = geom.GetX()
        del attributes['population']
        del attributes['type']
        csvwriter.writerow(attributes)

    #clean up
    csvfile.close()


if __name__ == '__main__':
    if len(sys.argv) != 3:
        usage()
        sys.exit(1)

    main()
