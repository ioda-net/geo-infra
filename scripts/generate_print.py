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

import glob

from generate_utils import Generate


class GeneratePrintConfig(Generate):
    '''Generate MFP configuration and copy the print logos.
    '''
    def generate(self):
        self._generate_print_config()
        self._generate_print_logo()

    def _generate_print_config(self):
        for template in glob.glob(self.src['print']):
            self.render(template, self.dest['print'], self.config)

    def _generate_print_logo(self):
        self.copy(self.src['print_logo'], self.dest['print'])
