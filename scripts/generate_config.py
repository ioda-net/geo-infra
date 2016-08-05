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

import os
try:
    import pytoml as toml
except ImportError:
    import toml
import logging
import sys

from collections import namedtuple
from os.path import basename, exists, realpath
from urllib.parse import urlparse

from generate_utils import path


ConfigFileErrors = namedtuple('ConfigFileErrors', 'base file errors')
'''Store errors of a config file.

Args:
    base (str): The name of the file against which the config is checked.
    file (str): The config file that is checked for errors.
    errors (List[Union[ConfigSectionErrors, ConfigErrors]]): The list of found errors.
'''
ConfigSectionErrors = namedtuple('ConfigSectionErrors', 'section errors')
'''Store errors found in a section of a config file.

Args:
    section (str): the section name in which the errors are found.
    errors (List[str]): the list of found errors.
'''
ConfigErrors = namedtuple('ConfigErrors', 'header errors')
'''Store the configuration errors.

Args:
    header (str): a message to print before the errors.
    errors (List[str]): the list of found errors.
'''


class GenerateConfig:
    '''Read the config files and provide access to the generated config with a dict like interface.

    Args:
        type (str): the type for which to generate the configuration. Default: None.
        portal (str): portal for which to generate the configuration. Default: None.
    '''

    #: Optional keys in the configuration. If one of these keys is missing, no warning is reported.
    optional_values = {
        'front.default_values': set(['wms_list', 'wmts_list']),
    }

    def __init__(self, type=None, portal=None, infra_dir=None, prod_git_repos_location=None):
        self.type = type
        self.portal = portal
        self.domain = None
        # This variable is used in path where None is not allowed.
        self.infra_dir = infra_dir or ''
        self.prod_git_repos_location = prod_git_repos_location or ''
        self._config = {}
        self.errors = []
        self._load_config()

    def create_output_dirs(self):
        '''Create all the directories for mapinfra's output.

        These directories correspond to the dest section of the config. Keys that start with
        '_template' and the geo_front3 subsection are ignored.
        '''
        for key, folder in self._config['dest'].items():
            # We don't have to create the dirs for keys associated with geo_front3 (in config.dest)
            if not isinstance(folder, dict) and \
                    not key.startswith('template_') and \
                    not key == 'vhost' and \
                    not exists(folder):
                os.makedirs(folder, exist_ok=True)

    def _load_config(self):
        '''Load the configuration and store it into self._config.

        It will:

        #. Load the global configuration
        #. Load the configuration common to all portal:

            #. the _common.dist.toml file
            #. the _common.prod.toml file if it exists
            #. the _common.dev.toml file if ``self.type == 'dev'`` and if it exists

        #. Load the portal specific configuration if ``self.portal is not None``. It follows the
           same rules as the common file (dist -> prod -> dev).
        #. Add any complementary keys to self._config that are not in the config files:

            - type
            - portal
            - prod (bool)
            - infra_dir: the absolute path to the current customer infra dir
            - infra_name: the base name of infra dir, eg customer-infra
            - mapserver_ows_host: the host of mapserver (used to generate the print configuration).
              **Only is portal is not None.**
            - prod_git_repos_location: location of the productions git repositories on the server.
        '''
        global_config = self._load_config_from_file('config/global.toml', None)
        self._update_config(self._config, global_config, section_check=False)

        config_files_to_load = ['_common']
        if self.portal:
            config_files_to_load.append(self.portal)

        config_types_to_load = ['dist']
        if self.type == 'dev':
            config_types_to_load.append('dev')
        elif self.type == 'prod':
            config_types_to_load.append('prod')

        for config_type in config_types_to_load:
            for config_file in config_files_to_load:
                if not self.infra_dir and config_file == '_common':
                    continue

                portal_file = config_file != '_common' and config_type not in ('prod', 'dev')
                section_check = config_type != 'dist'
                cfg = self._load_config_from_file(
                    config_file,
                    config_type,
                    portal_file=portal_file,
                    prefix=self.infra_dir,
                    must_exists=portal_file)
                config_section_errors = ConfigSectionErrors(section=config_file, errors=[])
                self._update_config(
                    self._config,
                    cfg,
                    section_check=section_check,
                    errors=config_section_errors.errors)
                self.errors.append(config_section_errors)

        self._display_errors()

        # We need an object to initialize the recursion.
        self._format_templates(self._config)

        self._config['type'] = self.type
        self._config['portal'] = self.portal
        self._config['prod'] = self.type == 'prod'
        # If portal is None (eg creating template cache), we don't have a mapserver section and we
        # don't need mapserver_ows_host.
        if self.portal:
            self._config['mapserver_ows_host'] = urlparse(self._config['mapserver']['PORTAL_BASE_OWS']).hostname
        # Make output path absolute
        self._config['infra_dir'] = realpath(self.infra_dir)
        self._config['infra_name'] = basename(self._config['infra_dir'])
        self._config['prod_git_repos_location'] = self.prod_git_repos_location

    def _load_config_from_file(self, cfg_file, type, portal_file=False, prefix='', must_exists=True):
        '''Load the config file and override keys with those from prod or dev if needed.

        Args:
            cfg_file (str): either a path to an existing file or a category of files, eg _common.
            protal_file (bool): if true, the config file will be checked against
                _template.dist.toml.
        '''
        if exists(cfg_file):
            cfg_path = cfg_file
        else:
            cfg_path = self._get_config_path(cfg_file, type=type, prefix=prefix)

        try:
            cfg = self._load_config_file(cfg_path, type, prefix=prefix)
            logging.debug('Loaded config file: ' + cfg_path)
        except FileNotFoundError as e:
            logging.debug('Config file not found: ' + cfg_path)
            if must_exists:
                logging.error('Config file must exist: ' + cfg_path)
                logging.error('Exiting')
                sys.exit(1)
            else:
                cfg = {}

        if portal_file:
            self._check_portal_config_with_portal_template(cfg, cfg_file)

        return cfg

    def _load_config_file(self, cfg_path, type='dist', prefix=''):
        '''Load the file from the disk and parse it with the toml module.
        '''

        with open(cfg_path, 'r') as cfg:
            return toml.load(cfg)

    def _get_config_path(self, cfg_file, type='dist', prefix=''):
        '''Transform a catogory of file like _common into an actual path we can open.

        Args:
            cfg_file (str): category of file.
            type (str): type of file to get (dest, dev or prod).
        '''
        ext = '.{type}.toml'.format(type=type)
        return path(prefix, 'config', type, cfg_file, ext=ext)

    def _format_templates(self, locations):
        '''Replace {type} and {portal} by their value in each list or dict it finds.
        '''
        for key, value in locations.items():
            if isinstance(value, str):
                locations[key] = self._format_template(value)
            elif isinstance(value, list):
                for index, list_value in enumerate(value):
                    value[index] = self._format_template(list_value)
            elif isinstance(value, dict):
                self._format_templates(value)

    def _format_template(self, location):
        '''Replace the {type}, {portal}, {domain} by their value.
        '''
        self.domain = self._config.get('vhost', {}).get('domain', '')
        if isinstance(location, str):
            return location.format(
                type=self.type,
                portal=self.portal,
                infra_dir=self.infra_dir,
                domain=self.domain,
            )
        else:
            return location

    def _update_config(self, dest, src, depth=0, section_check=True, section=None, errors=None):
        '''Recursively update a dict while checking for inconsistancies.

        Args:
            dest (dict): the destination dict.
            src (dict): the source dict.
            depth (int): the current level of recursivity. Default: 0.
            section_check (bool): whether or not to check for new config sections or new keys. If
                ``depth == 0`` it will report the additions as sections. If ``depth > 0`` it will
                report the additions as keys. Default: True.
            section (str): the name of the current section. Used to provide a more hepful message
                in case of errors. Default: None.
            errors (list): the list of found errors. Default: None.
        '''
        self._check_config(
            dest,
            src,
            depth=depth,
            section_check=section_check,
            section=section,
            errors=errors)

        for key, value in src.items():
            depth += 1
            self._check_value_type(key, value, dest, errors=errors)

            if isinstance(value, dict):
                if section:
                    current_section = '{section}.{subsection}'.format(section=section, subsection=key)
                else:
                    current_section = key

                self._update_config(
                    dest.setdefault(key, {}),
                    value,
                    depth=depth,
                    section_check=section_check,
                    section=current_section,
                    errors=errors)
            else:
                dest[key] = value

    def _check_config(self, dest, src, depth=0, section_check=True, section=None, errors=None):
        '''Check that the source is coherent with the destination. If incoherences are found, they
        are reported.

        Args:
            dest (dict): the destination dict.
            src (dict): the source dict.
            depth (int): the current level of recursivity. Default: 0.
            section_check (bool): whether or not to check for new config sections or new keys. If
                ``depth == 0`` it will report the additions as sections. If ``depth > 0`` it will
                report the additions as keys. Default: True.
            section (str): the name of the current section. Used to provide a more hepful message
                in case of errors. Default: None.
            errors (list): the list of found errors. Default: None.
        '''
        if errors is None:
            errors = []

        if len(dest) != 0:
            if depth == 0:
                if not all([isinstance(value, dict) for value in src.values()]):
                    top_level_keys = [key for key, value in src.items()
                                      if not isinstance(value, dict)]
                    errors.append(ConfigErrors(
                        header='Adding global keys (All keys should be in a section)',
                        errors=top_level_keys))
                if 'src' in src:
                    errors.append(ConfigErrors(
                        header='Modifying global src section. Keys to be changed',
                        errors=src['src'].keys()))
                if 'dest' in src:
                    errors.append(ConfigErrors(
                        header='Modifying global dest section. Keys to be changed',
                        errors=src['dest'].keys()))
                if 'print' in src:
                    if 'mapHeight' in src['print']:
                        errors.append(
                            ConfigErrors(header='Modifying print.mapHeight',
                            errors=[src['print']['mapHeight']]))
                    if 'mapWidth' in src['print']:
                        errors.append(ConfigErrors(
                            header='Modifying print.mapWidth',
                            errors=[src['print']['mapWidth']]))

            if section_check and depth == 0:
                dist_sections = set(dest.keys())
                src_sections = set(src.keys())
                if not src_sections.issubset(dist_sections):
                    added_sections = [section_name for section_name in src_sections - dist_sections
                                      if isinstance(src[section_name], dict)]
                    if added_sections:
                        errors.append(ConfigErrors(
                            header='Adding sections',
                            errors=added_sections))

            if depth > 0 and section_check:
                dist_keys = set(dest.keys())
                src_keys = set(src.keys())
                if section in self.optional_values:
                    src_keys -= self.optional_values[section]

                if not src_keys.issubset(dist_keys):
                    errors.append(ConfigErrors(
                        header='Adding keys (section: {})'.format(section),
                        errors=src_keys - dist_keys))

    def _check_value_type(self, src_key, src_value, dest, errors=None):
        '''Verify that to the source key correspond a value with the same type as the dest value
        for this key.

        Args:
            src_key (str): the source key.
            src_value (any): the sourve value.
            dest (dict): the destination dict.
            errors (list): the list of found errors. Default: None.
        '''
        if errors is None:
            errors = []

        if src_key in dest and not type(src_value) == type(dest[src_key]):
            cfg_errors = ConfigErrors(
                header='Changing the type of key',
                errors=['{} from {} to {}'.format(src_key, type(dest[src_key]), type(src_value))])
            errors.append(cfg_errors)

    def _check_portal_config_with_portal_template(self, portal_config, cfg_file):
        '''Verify that a portal configuration file is coherent with the template.
        '''
        # Override with client specific template if it exists
        custom_template_config_path = path(
            self._config['src']['base_include'],
            'config/_template.dist.toml')
        custom_template_config_path = self._format_template(custom_template_config_path)
        if exists(custom_template_config_path):
            template_config = self._load_config_file(custom_template_config_path)
            logging.debug('Loaded template file: ' + custom_template_config_path + ' (template, values not loaded)')
        else:
            logging.error('Template file not found: ' + custom_template_config_path)
        config_file_errors = ConfigFileErrors(
            base=custom_template_config_path,
            file=cfg_file,
            errors=[])
        self.errors.append(config_file_errors)
        self._update_config(template_config, portal_config, errors=config_file_errors.errors)

    def _display_errors(self):
        '''Display all the found errors for each config file on stderr.
        '''
        for config_file_errors in self.errors:
            if config_file_errors.errors:
                if isinstance(config_file_errors, ConfigFileErrors):
                    self._display_config_file_errors(config_file_errors)
                elif isinstance(config_file_errors, ConfigSectionErrors):
                    self._display_config_section_errors(config_file_errors)

    def _display_config_file_errors(self, config_file_errors):
        '''Display the errors of one config file on stderr.
        '''
        message = 'Difference between the base "{base}" and the file "{file}"'\
            .format(base=config_file_errors.base, file=config_file_errors.file)
        logging.warn(message)

        for config_errors in config_file_errors.errors:
            self._display_config_errors(config_errors)

        logging.warn('')

    def _display_config_errors(self, config_errors):
        '''Display the errors on stderr'
        '''
        if config_errors.header:
            logging.warn('* {header}'.format(header=config_errors.header))

        for error in config_errors.errors:
            logging.warn('** ERROR: {error}'.format(error=error))

    def _display_config_section_errors(self, config_section_errors):
        '''Display the config section errors on stderr.
        '''
        message = 'Difference while merging the file from the "{}" category in the main configuration'\
            .format(config_section_errors.section)
        logging.warn(message)

        for config_errors in config_section_errors.errors:
            self._display_config_errors(config_errors)

        logging.warn('')

    @property
    def config(self):
        '''Access to the row config dict.
        '''
        return self._config

    def get(self, *args, **kwargs):
        '''Forward to self.config.get
        '''
        return self._config.get(*args, **kwargs)

    def __getitem__(self, key):
        if key not in self._config:
            return
        return self._config[key]

    def __setitem__(self, key, value):
        self._config[key] = value

    def __str__(self):
        return str(self._config)

    def __repr__(self):
        return str(self)
