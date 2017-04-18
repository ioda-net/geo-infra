#!/usr/bin/env python3

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

'''Render document with jinja2 and ``${var}`` as a template syntax.

Call this script with ``--help`` to view the full help message.
'''

import argparse
import htmlmin
import os
import re
import sys

from copy import deepcopy
from datetime import datetime

if sys.version_info.minor < 5:
    # glob2 (https://pypi.python.org/pypi/glob2) supports ** expansions. Added in std lib in 3.5.
    from glob2 import glob
else:
    from glob import glob
    # By default python 3.5 is not recursive, we use functools.partial to make sure it is
    from functools import partial
    glob = partial(glob, recursive=True)
from jinja2 import Environment, FileSystemLoader

from generate import PORTAL_CHOICES
from generate_config import GenerateConfig


REQUIRE_PORTAL = set((
    '--index',
    '--plugins',
    '--appcache',
))

REQUIRE_TYPE = set((
    '--test',
))
REQUIRE_TYPE.update(REQUIRE_PORTAL)
REQUIRE_INFRA_DIR = set(REQUIRE_TYPE)


def main(args):
    config = GenerateConfig(portal=args.portal, type=args.type, infra_dir=args.infra_dir)
    config['version'] = str(datetime.now()).split(' ')[0]
    front_dir = args.front_dir

    if args.index:
        template_path = os.path.abspath(os.path.join(front_dir, config['src']['geo_front3']['index']))
        out_dir_path = os.path.abspath(os.path.join(front_dir, config['dest']['output']))

        for device in config['front']['build']['devices']:
            config['device'] = device
            out_file_path = os.path.join(out_dir_path, device + '.html')
            os.makedirs(out_dir_path, exist_ok=True)
            render(template_path, out_file_path, config.config)

    if args.plugins:
        template_path = os.path.abspath(os.path.join(front_dir, config['src']['geo_front3']['plugins_template']))
        out_path = os.path.abspath(os.path.join(front_dir, config['dest']['geo_front3']['plugins_file']))
        plugins = {
            'activated_plugins': config['front']['default_values'].get('plugins', []),
            'available_plugins': _get_available_plugins(front_dir, config),
        }
        render(template_path, out_path, plugins)

    if args.template_cache:
        template_path = os.path.abspath(os.path.join(front_dir, config['src']['geo_front3']['template_cache_module']))
        out_path = os.path.abspath(os.path.join(front_dir, config['dest']['geo_front3']['template_cache_module']))
        template_cache_config = {
            'partials': _get_partials(front_dir, config)
        }
        render(template_path, out_path, template_cache_config)

    if args.appcache:
        template_path = os.path.abspath(os.path.join(front_dir, config['src']['geo_front3']['appcache']))
        out_path = os.path.abspath(os.path.join(front_dir, config['dest']['geo_front3']['appcache']))
        appcache_config = deepcopy(config.config)
        appcache_config['version'] = ''
        render(template_path, out_path, appcache_config)

    if args.test:
        _render_karma_conf(front_dir, config)
        _render_protractor_conf(front_dir, config)


def render(
        template_path,
        out_file_path,
        data,
        variable_start_string="${",
        variable_end_string="}"):
    '''Render a template with specified variable start and variable end

    Args:
        template_path: The absolute path to the template.
        out_file_path: The absolute path to the output file.
        config: A :class:`generate_config.GenerateConfig` instance.
        variable_start_string: The string to look for at the start of a variable. Default: '${'.
        variable_end_string: The string to look for at the end of a variable. Default: '}'.
    '''
    env = Environment(
        loader=FileSystemLoader(os.path.dirname(template_path)),
        keep_trailing_newline=True,
        variable_start_string=variable_start_string,
        variable_end_string=variable_end_string
    )
    env.globals['environ'] = os.environ.get

    output = env.get_template(os.path.basename(template_path)).render(data)

    with open(out_file_path, 'w') as out_file:
        out_file.write(output)


def _render_karma_conf(front_dir, config):
    karma_config = deepcopy(config.config)
    template_path = os.path.join(
        front_dir,
        karma_config['src']['geo_front3']['karma_conf_template'])
    template_path = os.path.abspath(template_path)

    out_file_path = os.path.join(
        front_dir,
        karma_config['dest']['geo_front3']['karma_conf'])
    out_file_path = os.path.abspath(out_file_path)

    render(template_path, out_file_path, karma_config)


def _render_protractor_conf(front_dir, config):
    template_path = os.path.join(
        front_dir,
        config['src']['geo_front3']['protractor_conf_template'])
    template_path = os.path.abspath(template_path)

    out_file_path = os.path.join(
        front_dir,
        config['dest']['geo_front3']['protractor_conf'])
    out_file_path = os.path.abspath(out_file_path)

    render(template_path, out_file_path, config.config)


def _get_available_plugins(front_dir, config):
    available_plugins = {}
    plugins_path = os.path.abspath(os.path.join(front_dir, config['src']['geo_front3']['plugins']))
    for plugin in glob(plugins_path):
        if os.path.isfile(plugin):
            plugin_name, _ = os.path.splitext(os.path.basename(plugin))
            with open(plugin, 'r') as plugin_file:
                available_plugins[plugin_name] = plugin_file.read()

    return available_plugins


def _get_partials(front_dir, config):
    partials = {}
    partials_pathes = []
    path_to_replace = os.path.join(front_dir, 'src/')
    for path in config['src']['geo_front3']['partials']:
        partials_pathes.append(os.path.join(front_dir, path))

    partials_files = []
    for path in partials_pathes:
        partials_files.extend(glob(path))

    for partial in partials_files:
        with open(partial, 'r') as partial_file:
            partial_content = partial_file.read()
            partial_content = re.sub(r"'", r"\'", partial_content)
            partial_content = re.sub(r'\n', '', partial_content)
            partial_content = htmlmin.minify(
                partial_content,
                remove_comments=False,
                remove_optional_attribute_quotes=False)

            partial_name = partial.replace(path_to_replace, '')

            partials[partial_name] = partial_content

    return partials

if __name__ == '__main__':
    script_args = set(sys.argv)
    portal_required = len(REQUIRE_PORTAL & script_args) != 0
    type_required = len(REQUIRE_TYPE & script_args) != 0
    infra_dir_required = len(REQUIRE_INFRA_DIR & script_args) != 0

    parser = argparse.ArgumentParser(description='Generate configuration files')
    parser.add_argument(
        '-p', '--portal',
        help='The name of the portal to use',
        dest='portal',
        choices=PORTAL_CHOICES,
        required=portal_required)
    parser.add_argument(
        '-t', '--type',
        help='type (dev or prod)',
        dest='type',
        choices=['dev', 'prod'],
        required=type_required)
    parser.add_argument(
        '-d', '--infra-dir',
        dest='infra_dir',
        required=infra_dir_required)
    parser.add_argument(
        '--front-dir',
        help='the path to the front directory',
        dest='front_dir',
        required=True)
    parser.add_argument(
        '--index',
        help='Generate index.html, mobile.htm and embded.html for the frontend.'
             ' Require --type and --portal.',
        dest='index',
        action='store_true')
    parser.add_argument(
        '--plugins',
        help='Generate js/Gf3Plugins.js for the frontend.'
             ' Require --type and --portal.',
        dest='plugins',
        action='store_true')
    parser.add_argument(
        '--template-cache',
        help='Generate src/TemplateCacheModule.js for the frontend.',
        dest='template_cache',
        action='store_true')
    parser.add_argument(
        '--appcache',
        help='Generate src/geoadmin.appcache for the frontend.',
        dest='appcache',
        action='store_true')
    parser.add_argument(
        '--test',
        help='Generate test config files for karma and portractor. Requires --type.',
        dest='test',
        action='store_true')

    args = parser.parse_args()
    main(args)
