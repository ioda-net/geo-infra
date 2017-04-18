###############################################################################
# geo-infra Scripts and templates to create and manage geoportals
# Copyright (c) 2015-2016, sigeom sa
# Copyright (c) 2015-2016, Ioda-Net Sàrl
#
# Contact : contact (at)  geoportal (dot) xyz
# Repository : https://github.com/ioda-net/geo-infra
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
###############################################################################

'''Helper functions to generate the configurations for timeseries.
'''

import logging
import mappyfile
import warnings

from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.orm import sessionmaker
from generate_utils import path


# SQLAlchemy may fail to detect the type of geometry columns. We ignore this warning.
warnings.filterwarnings('ignore', message="Did not recognize type 'geometry' of column 'the_geom'")


def get_timestamps(portal, config, layer_name):
    '''Return the list of timestamps for the given layer.

    To do that, we:

    - Parse the mapfile of the portal to find the layer definition.
    - Extract the name of the table, primary key and "time column" from it.
    - Query the database to get the list of timestamps.

    Raises:
        ``ValueError`` if no timestamps are found.
    '''
    mapfile = path(config['dest']['map'], 'portals', portal, ext='.map')
    mapfile_content = mappyfile.load(mapfile)
    layers = mapfile_content['layers']
    # layer_name can be a group or a layer. We take both case into account.
    layers_to_query = [mappyfile.find(layers, 'NAME', layer_name)]
    layers_to_query.extend(mappyfile.findall(layers, 'GROUP', layer_name))
    # If a layer is not found by group or name, it will be None. We remove them
    # from the list of layers to query.
    layers_to_query = [layer for layer in layers_to_query if layer is not None]

    timestamps = find_time_values(config, layers_to_query)
    if len(timestamps) == 0:
        raise ValueError('{} is neither a layer nor a group in {}'.format(layer_name, mapfile))

    return timestamps


def find_time_values(config, layers_to_query):
    '''Return the list of timestamps based on the configuration of the portal and a list of
    layer definitions.'''
    user = config['mapserver']['PORTAL_DB_USER']
    password = config['mapserver']['PORTAL_DB_PASSWORD']
    host = config['mapserver']['PORTAL_DB_HOST']
    port = config['mapserver']['PORTAL_DB_PORT']
    db = config['mapserver']['PORTAL_DB_NAME']

    timestamps = set()
    for layer in layers_to_query:
        timestamps.update(fetch_timestamps_from_db(
            user=user,
            host=host,
            password=password,
            port=port,
            db=db,
            table=get_table_from_layer_definition(layer),
            time_column=get_time_column_from_layer_definition(layer),
            pkey_column=get_pkey_column_from_layer_definition(layer)
        ))

    # Convert the set to a list to include the result in a JSON file.
    return list(timestamps)


def get_pkey_column_from_layer_definition(layer):
    '''Extract the primary key of the table from the layer definition.'''
    data = layer['data']
    # The data string is formated like:
    # "the_geom from (SELECT the_geom, gid, couleur, periode_time FROM sigma_1927) as foo using unique gid"
    # and we need to extract gid.
    _, gid = data.split('unique ')
    # gid is likely to end with a quote. We remove it.
    return gid.replace('"', '')


def get_table_from_layer_definition(layer):
    '''Extract the name of the table from the layer definition.'''
    data = layer['data']
    # The data string is formated like:
    # "the_geom from (SELECT the_geom, gid, couleur, periode_time FROM sigma_1927) as foo using unique gid"
    # and we need to extract sigma_1927.
    _, after_from = data.split('FROM ')
    table_name, _ = after_from.split(')')
    return table_name


def get_time_column_from_layer_definition(layer):
    '''Extract the name of the "time column" from the layer definition.'''
    metadata = layer['metadata']
    possible_keys = ('ows_timeitem', '"ows_timeitem"', 'wms_timeitem', '"wms_timeitem"')
    for key in possible_keys:
        time_column = metadata.get(key, None)
        if time_column is not None:
            # The parsed name of the column may contain additionnal quotes. We remove them.
            return time_column.replace('"', '')


def fetch_timestamps_from_db(
    user='',
    host='localhost',
    password='',
    port=5432,
    db='',
    type='postgresql',
    table='',
    time_column=None,
    pkey_column='id'
):
    '''Query the database with the proper parameters to find a list of timestamps.

    It will find the table information dynamically based on the supplied parameters.
    '''
    # Create query from table metadata
    conn_str = '{type}://{user}:{passwd}@{host}:{port}/{db}'.format(
        type=type,
        user=user,
        passwd=password,
        host=host,
        port=port,
        db=db
    )
    engine = create_engine(conn_str)
    metadata = MetaData()
    metadata.reflect(engine, only=[table])
    t = Table(
        table,
        metadata,
        autoload=True,
        autoload_with=engine,
        extend_existing=True
    )

    # Do the query
    Session = sessionmaker(bind=engine)
    session = Session()
    results = session.query(t).all()
    # Use a set to prevent duplicates.
    timestamps = set()
    for r in results:
        start = getattr(r, time_column)
        if start is not None:
            timestamps.add(start.strftime('%Y-%m-%d'))
        else:
            logging.warning('Time for row {} of table {} is NULL'
                            .format(getattr(r, pkey_column), table))

    return timestamps
