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

import logging
import os
import re
import sys

from collections import namedtuple
from generate_utils import Generate
from os.path import exists, dirname


MapInclude = namedtuple('MapIncludes', 'name origin')


class GenerateMapFiles(Generate):
    '''Create the mapfiles based on the template in the portal folder and the configuration.
    '''
    def generate(self):
        includes = self._get_map_to_include()
        self._generate_map_files(includes)

    def _get_map_to_include(self):
        portal_dir = self.path(self.src['base_include'], 'portals')
        origin = self.path(portal_dir, self.portal, ext='.map.in')
        if not exists(origin):
            origin = self.path(portal_dir, self.portal, ext='.in.map')
        included_map = re.compile(r'''^\s*(?:(?!#))INCLUDE\s+["'](.*)["']''', re.M)

        files_to_parse = [MapInclude(name=origin, origin=origin)]
        files_parsed = []

        while len(files_to_parse) > 0:
            current_include = files_to_parse.pop()
            current_file, origin = current_include
            files_parsed.append(current_file)

            if not exists(current_file):
                msg = '** ERROR in file ' + origin + ' include of ' + current_file + \
                    ' which doen\'t exists.'
                logging.error(msg)
                sys.exit(2)

            with open(current_file) as map_template:
                content = map_template.read()
                for include in included_map.findall(content):
                    if include not in files_parsed:
                        include = self.path(self.src['base_include'], include[3:], ext='.in')
                        files_to_parse.append(MapInclude(name=include, origin=current_file))

        return files_parsed

    def _generate_map_files(self, includes):
        for map_template in includes:
            folder = dirname(map_template).replace(self.src['base_include'], '')
            folder = self.path(self.dest['map'], folder)
            if not exists(folder):
                os.makedirs(folder, exist_ok=True)
            self.render(map_template, folder, self.config)
