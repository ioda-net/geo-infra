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

'''Contains classes to parse WMS GetCapabilities and generate JSON config files for the frontend.
'''

import json
import requests
import time

from glob import glob
from operator import xor
from os.path import basename, splitext
from owslib.wms import WebMapService
from requests.exceptions import ConnectionError

from generate_utils import Generate, start_cgi_server, cgi_server
from generate_translations import Translator, CatalogTranslator


class GenerateJsonConfig(Generate):
    '''Generate the layers configuration and the catalog from a GetCapabilities request.

    In order to always use the lastest map file, we start a python CGI server in a thread. This
    server will be used for the GetCapabilities request.
    '''
    MAX_CONNECTION_ATTEMPTS = 30
    CONNECTION_ATTEMPTS_DELAY = 2

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self._start_cgi_server()
        translator = Translator(self.src['translation_files'], self.verbose)
        self.catalog_translator = CatalogTranslator(self.src['translate_catalog'])
        # This will both get and save the translations if output_folder is not None
        translator.get_translations(
            ignore_file_name=self.src['translate_ignore'],
            output_folder=self.dest['translate'],
            pretty=self.pretty)
        ows_parser = OwsParser(**kwargs)
        self.layers_config = ows_parser.get_layers_config()

    def _start_cgi_server(self):
        start_cgi_server()
        self._connection_attempts = 0
        self._test_connection_to_cgi_server()

    def _test_connection_to_cgi_server(self):
        connection_url = self.config['mapserver']['OWS_STAGING_URL'].replace('?MAP=', '')
        error = None
        while self._connection_attempts < self.MAX_CONNECTION_ATTEMPTS:
            try:
                requests.get(connection_url)
            except ConnectionError as e:
                self._connection_attempts += 1
                time.sleep(self.CONNECTION_ATTEMPTS_DELAY)
            else:
                break

        if error:
            raise error

    def generate(self):
        '''Generate the layers configuration and the catalog.
        '''
        self.create_services_json()
        self.create_catalog_json()

    def create_services_json(self):
        '''Create the list of topics.
        '''
        services = {'topics': []}
        for file_name in sorted(glob(self.src['topics'])):
            with open(file_name, 'r') as json_file:
                current_topic_config = json.load(json_file)
            background_layers = current_topic_config['backgroundLayers']
            self.check_layers_in_layers_config(background_layers, current_topic_config['name'])
            selected_layers = current_topic_config['selectedLayers']
            activated_layers = current_topic_config.get('activatedLayers', [])
            self.check_layers_in_layers_config(selected_layers, current_topic_config['name'])
            topic = {
                'langs': ','.join(current_topic_config['langs']),
                'backgroundLayers': background_layers,
                'id': self.get_topic_id(file_name),
                'activatedLayers': activated_layers,
                'selectedLayers': selected_layers,
                'showCatalog': True,
            }
            services['topics'].append(topic)
        services_file = self.path(self.dest['services'], 'services.json')
        self.save_json(services_file, services)

    def check_layers_in_layers_config(self, layers, topic_name):
        '''Verify for each layer of a topic that is exists in the layers configuration.

        Print the list of layers that don't have a configuration on stderr.
        '''
        report = []
        for layer in layers:
            report.append(self.check_layer_in_layers_config(layer))
        report = [line for line in report if line]
        self.report_errors(report, header='In topic {}'.format(topic_name))

    def check_layer_in_layers_config(self, layer):
        if layer not in self.layers_config and layer != 'voidLayer':
            return '*** WARNING: {} not in layersConfig'.format(layer)

    def get_topic_id(self, abs_path):
        file_name = basename(abs_path)
        id, extension = splitext(file_name)
        return id

    def create_catalog_json(self):
        '''Create the configuration of the catalog for each topic.
        '''
        for topic_file_name in glob(self.src['topics']):
            self.process_topic(topic_file_name)

    def process_topic(self, topic_file_name):
        with open(topic_file_name, 'r') as topic_file:
            topic = json.load(topic_file)
        for lang in topic['langs']:
            catalog = {
                'results': {
                    'root': {
                        'category': 'root',
                        'children': []
                    }
                }
            }
            self.process_topic_catalog(catalog, topic, lang)
            self.save_topic_catalog(catalog, lang, topic_file_name)

    def process_topic_catalog(self, catalog, topic, lang):
        for category in topic['catalog']:
            t = self.catalog_translator[lang]
            if isinstance(category, str):
                new_category = self.process_layer(category, t)
            else:
                new_category = self.process_category(category, t)
            catalog['results']['root']['children'].append(new_category)

    def save_topic_catalog(self, catalog, lang, topic_file_name):
        topic_id = self.get_topic_id(topic_file_name)
        save_path = self.dest['template_translate_catalog'].format(topic=topic_id, lang=lang)
        self.save_json(save_path, catalog)

    def process_category(self, category, t):
        '''Generate the configuration for a category of the catalog.
        '''
        current_category = {
            'category': category['category'],
            'label': t(category['category']),
            'selectedOpen': category.get('selectedOpen', False),
            'children': []
        }
        for child in category['children']:
            if isinstance(child, str):
                catalog_element = self.process_layer(child, t)
            else:
                catalog_element = self.process_category(child, t)
            current_category['children'].append(catalog_element)

        return current_category

    def process_layer(self, layer_id, t):
        '''Return the proper configuration for a layer in the catalog.'''
        self.check_layer_in_layers_config(layer_id)
        return {
            'category': 'layer',
            'label': t(self.layers_config
                        .get(layer_id, {})
                        .get('label', layer_id)),
            'layerBodId': layer_id
        }


class OwsParser(Generate):
    '''Parse a WMS GetCapabilities and saves the configuration of the layers in a JSON files.
    '''

    #: What information should we translate from the WMS server?
    LAYERS_CONFIG_KEY_TO_TRANSLATE = ('label', 'attribution', 'attributionUrl', 'legendUrl')

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.catalog_translator = CatalogTranslator(self.src['translate_catalog'])
        self.langs = self.catalog_translator.langs

    def get_layers_config(self):
        self.get_ows_information()
        return self.layers_config

    def get_ows_information(self):
        '''Make the GetCapabilities request and process it.
        '''
        self.layers_config, self.layers_names = {}, []
        self.ows_url = self.config['mapserver']['PORTAL_BASE_OWS']
        mapfile = self.path(self.config['dest']['map'], 'portals', self.portal, ext='.map')
        self.ows_staging_url = self.config['mapserver']['OWS_STAGING_URL'] + mapfile
        ows_version = self.config['mapserver']['PORTAL_WMS_VERSION']
        ows_version = ows_version if ows_version == '1.1.1' else '1.1.1'
        ows_username = self.config['mapserver'].get('PORTAL_USERNAME', None)
        ows_password = self.config['mapserver'].get('PORTAL_PASSWORD', None)
        # Could be get from Getmap format?
        self.ows_format = 'png'
        self.ows_type = 'wms'
        # Could we use the ows_contactorganization to put copyright on layers?
        self.default_layer_attribution = {
            'title': self.config['layers']['default_layer_attribution'],
            'url': self.config['layers']['default_layer_attribution_url'],
        }
        self.background_layers_ids = self.config['layers'].get('background_layers_ids', [])
        self.default_background_opacity = self.config['layers'].get('default_background_opacity', 0)
        self.single_tiles_by_default = self.config['layers'].get('single_tiles_by_default', True)
        self.default_tiling_exceptions = self.config['layers'].get('default_tiling_exceptions', [])
        self.default_ratio = 1 if self.single_tiles_by_default else 0
        try:
            self.wms = WebMapService(
                self.ows_staging_url,
                version=ows_version,
                username=ows_username,
                password=ows_password)
        except ConnectionError as e:
            self.report_errors(
                'Check that the WMS server is running and that '
                'PORTAL_USERNAME and PORTAL_PASSWORD are correct')
            self.report_errors('Python errors: ' + str(e))
        except AttributeError:
            self.report_errors(
                'Cannot parse WMS content. Check that {} provides a proper '
                'GetCapabilities file.'.format(self.ows_staging_url))
        else:
            self.process_wms_layers()
            self.process_external_layers()
            self.save_information()

    def process_wms_layers(self):
        '''Process each WMS layer from from the GetCapabilities and store the revelant information
        for the configuration.
        '''
        for layer_name, layer in self.wms.contents.items():
            label = getattr(layer, 'title', layer.name)
            legend = layer.styles.get('default', {}).get('legend', '')
            queryable = bool(getattr(layer, 'queryable', False))
            attribution = getattr(layer, 'attribution', self.default_layer_attribution)
            opacity = getattr(layer, 'opaque', 0) if layer_name not in self.background_layers_ids \
                else self.default_background_opacity
            single_tile = xor(
              self.single_tiles_by_default,
              layer_name in self.default_tiling_exceptions)
            self.layers_config[layer_name] = {
                'layerBodId': layer_name,
                'label': label,
                'attribution': attribution.get('title', self.default_layer_attribution['title']),
                'attributionUrl': attribution.get('url', self.default_layer_attribution['url']),
                'hasLegend': bool(legend),
                'legendUrl': legend,
                'format': self.ows_format,
                'type': self.ows_type,
                'opacity': opacity,
                'queryable': queryable,
                'selectbyrectangle': queryable,
                'serverLayerName': layer_name,
                'wmsLayers': layer_name,
                'wmsUrl': self.ows_url,
                'background': layer_name in self.background_layers_ids,
                'singleTile': single_tile,
                'ratio': 1 if single_tile else 0,
            }
            self.layers_names.append((layer_name, label))

    def process_external_layers(self):
        '''Process each JSON file configuring an external layer.
        '''
        for external_layer in glob(self.src['external_layers']):
            self.process_external_layer_file(external_layer)

    def process_external_layer_file(self, external_layer):
        '''Read the configuration of a layer from a JSON file.
        '''
        with open(external_layer, 'r') as layer_data:
            layer = json.load(layer_data)
            layer_name = layer['name']
            label = layer.get('label', layer_name)
            layer_type = layer['type']
            layer_config = {
                'layerBodId': layer_name,
                'label': label,
                'attribution': layer.get('attribution', ''),
                'attributionUrl': layer.get('attributionUrl', ''),
                'hasLegend': layer.get('hasLegend', False),
                'legendUrl': layer.get('legend', ''),
                'format': layer.get('format', 'png'),
                'type': layer['type'],
                'opacity': layer.get('opacity', 1),
                'queryable': layer.get('queryable', False),
                'selectbyrectangle': layer.get('queryable', False),
                'serverLayerName': layer.get('serverLayerName', layer_name),
                'background': layer.get('background', False),
                'singleTile': layer.get('singleTile', self.single_tiles_by_default),
                'ratio': layer.get('ratio', self.default_ratio),
                'epsg': layer.get('epsg', None),
            }
            if layer_type == 'wms':
                self._process_external_wms_layer(layer_config, layer)
            elif layer_type == 'wmts':
                self._process_external_wmts_layer(layer_config, layer)

            self.layers_config[layer_name] = layer_config
            self.layers_names.append((layer_name, label))

    def _process_external_wms_layer(self, layer_config, layer):
        layer_config['wmsLayers'] = layer.get('wmsLayers', layer['name'])
        layer_config['wmsUrl'] = layer['wmsUrl']

    def _process_external_wmts_layer(self, layer_config, layer):
        layer_config['timeEnabled'] = layer.get('timeEnabled', False)
        layer_config['resolutions'] = layer.get('resolutions', [])
        layer_config['timestamps'] = layer.get('timestamps', [])
        layer_config['timeBehaviour'] = layer.get('timeBehaviour', 'last')
        layer_config['matrixSet'] = layer['matrixSet']

    def save_information(self):
        '''Save the layers configuration and the search files.
        '''
        self.save_layers_config()

        self.save_layers_search()

    def save_layers_config(self):
        '''Save the configuration for layers in a JSON file per language.
        '''
        file_name = self.path(self.dest['json'], 'layersConfig_{lang}.json')
        for lang in self.langs:
            self.save_json(file_name.format(lang=lang), self.translate(lang))

    def translate(self, lang):
        '''Translate the value of the keys from :attr:`OwsParser.LAYERS_CONFIG_KEY_TO_TRANSLATE`.
        '''
        t = self.catalog_translator[lang]
        translated_layers_config = {}
        for layer_id in self.layers_config:
            translated_layers_config[layer_id] =\
                {key: t(value) if key in self.LAYERS_CONFIG_KEY_TO_TRANSLATE else value
                 for key, value in self.layers_config[layer_id].items()}
        return translated_layers_config

    def save_layers_search(self):
        '''Save information required by sphinx to search for a layer in a tsv file.

        The label of each layer is translated with :class:`generate_translations.CatalogTranslator`
        so each user can search in his/her language.
        '''
        for lang in self.langs:
            label_filter = set()
            t = self.catalog_translator[lang]
            file_name = self.path(
                self.dest['search_portal'],
                'layers_{lang}.tsv'.format(lang=lang))
            with open(file_name, 'w') as tsv_file:
                for id, name in enumerate(sorted(self.layers_names)):
                    id += 1  # sphinx-search doesn't support 0 as id
                    layer, label = name
                    if label not in label_filter:
                        label_filter.add(label)
                        tsv_file.write('{id}\t{layer}\t{label}\n'
                                       .format(id=id, layer=layer, label=t(label)))
