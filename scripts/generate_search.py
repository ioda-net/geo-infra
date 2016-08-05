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
import re

from glob import glob
from os.path import basename, exists, splitext

from generate_utils import Generate


class GenerateSearchConfig(Generate):
    '''Generate either the search configuration for one portal or the global search configuration.
    '''

    #: Regexp to exclude the layer config file when generating the global configuration.
    layer_search_template = re.compile(r'search/search-layers.in.conf')
    #: Regexp to exclude the portal config files when generating the global configuration.
    portal_search_template = re.compile(r'portal-.*\.in$')
    find_alias_re_template = r'(.+) {infra} {portal}$'

    def generate(self):
        '''Generate the search configuration for one portal.
        '''
        self.config['search']['langs'] = self._get_langs_tsv_files()
        
        portal_name = self.config['geoportal']['name']

        self.render(self.src['search_db'], self.dest['search_portal'], self.config)
        self.render(self.src['search_portal_layers'], self.dest['search_portal'], self.config)
        self.render(self.src['search_portal_locations'], self.dest['template_search_portal_locations'], self.config, dest_is_file=True)

        self.config['geoportal']['name'] = portal_name

    def _get_langs_tsv_files(self):
        langs = []
        for tsv in glob(self.src['search_tsv_files']):
            name, _ = splitext(basename(tsv))
            _, lang = name.split('_')
            langs.append(lang)

        return langs

    def generate_global(self):
        '''Generate the global configuration for search.
        '''
        os.makedirs(self.dest['search'], exist_ok=True)
        for template in glob(self.src['search']):
            self.render(template, self.dest['search'], self.config)
