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

'''Main script used to generate the files for a portal.

Call this script with the ``--help`` argument for more details.
'''


import argparse
import logging
import json
import sys

from glob import glob
from os.path import basename, join

from generate_help import GenerateHelpConfig
from generate_map_files import GenerateMapFiles
from generate_images import GenerateImages
from generate_json import GenerateJsonConfig
from generate_print import GeneratePrintConfig
from generate_search import GenerateSearchConfig
from generate_utils import Generate
from generate_config import GenerateConfig
from generate_vhosts import GenerateVhosts


REQUIRE_PORTAL = set((
    '--map', '-m',
    '--json', '-j',
    '--help-site',
    '--print', '-p',
    '--search', '-s',
    '--copy-img', '-i',
    '--clean', '-c',
    '--vhost',
))
REQUIRE_TYPE = set((
    '--search-global',
    '--config',
))
REQUIRE_TYPE.update(REQUIRE_PORTAL)
REQUIRE_INFRA_DIR = set((
    '--search-global',
))
REQUIRE_INFRA_DIR.update(REQUIRE_PORTAL)
REQUIRE_SEARCH_GOLBAL = set((
    '--search-global',
))

#: The list of all possible portals.
def fill_portal_choices():
    index = -1
    if '--infra-dir' in sys.argv:
        index = sys.argv.index('--infra-dir')
    elif '-d' in sys.argv:
        index = sys.argv.index('-d')

    infra_dir_index = index + 1
    if index > 0 and infra_dir_index < len(sys.argv):
        infra_dir = sys.argv[infra_dir_index]
        return [basename(portal).split('.')[0] for portal in glob(join(infra_dir, 'config/dist/*.dist.toml'))
                   if '_common.dist.toml' not in portal]

    return []


PORTAL_CHOICES = fill_portal_choices()


def main(args):
    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    elif args.verbose:
        logging.basicConfig(level=logging.INFO)
    else:
        logging.basicConfig(level=logging.WARNING)

    config = GenerateConfig(
        portal=args.portal,
        type=args.type,
        infra_dir=args.infra_dir,
        prod_git_repos_location=args.prod_git_repos_location,
    )
    kwargs = {
        'type': args.type,
        'portal': args.portal,
        'verbose': args.verbose,
        'ssl_validation': args.ssl_verify,
        'config': config,
    }

    if args.config:
        cfg = json.dumps(
            config.config,
            indent=4,
            sort_keys=True,
            ensure_ascii=False,
            separators=(',', ': '))
        print(cfg)
        sys.exit(0)

    if args.clean:
        _verbose('Clean', args)
        Generate(**kwargs).clean()

    # Prepare folder for portal
    if args.portal is not None and args.type is not None and args.infra_dir is not None:
        _verbose('Create output dirs', args)
        config.create_output_dirs()

    if args.gen_map:
        _verbose('Generate map files', args)
        GenerateMapFiles(**kwargs).generate()

    if args.gen_json:
        _verbose('Generate JSON config', args)
        GenerateJsonConfig(**kwargs).generate()

    if args.gen_help_site or args.fetch_help:
        help_creator = GenerateHelpConfig(**kwargs)
        if args.gen_help_site:
            _verbose('Generate help site', args)
            help_creator.generate()
        if args.fetch_help:
            _verbose('Fetching help content', args)
            help_creator.fetch_original_content()

    if args.gen_print:
        _verbose('Generate print config', args)
        GeneratePrintConfig(**kwargs).generate()

    if args.gen_search or args.gen_search_global:
        search_generator = GenerateSearchConfig(**kwargs)
        if args.gen_search:
            _verbose('Generate search config', args)
            search_generator.generate()
        if args.gen_search_global:
            _verbose('Generate global search config', args)
            search_generator.generate_global()

    if args.gen_images:
        _verbose('Generate images', args)
        GenerateImages(**kwargs).generate()

    if args.gen_vhosts:
        _verbose('Generate vhosts', args)
        GenerateVhosts(**kwargs).generate()


def _verbose(task, args):
    msg = task

    if args.type:
        msg += ' for type ' + args.type

    if args.portal:
        msg += ' for portal ' + args.portal

    logging.info(msg)


def _complete_help(help_message, argument):
    if argument in REQUIRE_PORTAL:
        help_message = help_message + ' Requires --portal.'

    if argument in REQUIRE_TYPE:
        help_message = help_message + ' Requires --type.'

    return help_message


if __name__ == "__main__":
    script_args = set(sys.argv)
    portal_required = len(REQUIRE_PORTAL & script_args) != 0
    type_required = len(REQUIRE_TYPE & script_args) != 0
    infra_dir_required = len(REQUIRE_INFRA_DIR & script_args) != 0
    search_global_required = len(REQUIRE_SEARCH_GOLBAL & script_args) != 0

    parser = argparse.ArgumentParser(description='Generate configuration files')
    parser.add_argument(
        '-v', '--verbose',
        help='Verbose mode',
        dest='verbose',
        action='store_true')
    parser.add_argument(
        '--debug',
        help='Debug mode. Print debug messages.',
        dest='debug',
        action='store_true')
    parser.add_argument(
        '--no-ssl-verify',
        help='Disable SSL cert validation when fetching content',
        dest='ssl_verify',
        action='store_false')
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
        '--map', '-m',
        help=_complete_help('Generate map files.', '--map'),
        dest='gen_map',
        action='store_true')
    parser.add_argument(
        '--json', '-j',
        help=_complete_help('Generate json files.', '--json'),
        dest='gen_json',
        action='store_true')
    parser.add_argument(
        '--help-site',
        help=_complete_help('Generate the help website.', '--help-site'),
        dest='gen_help_site',
        action='store_true')
    parser.add_argument(
        '--help-update', '-u',
        help=_complete_help('Update the help texts and images from swisstopo', '--help-update'),
        dest='fetch_help',
        action='store_true')
    parser.add_argument(
        '--print',
        help=_complete_help('Generate MapFish Print files.', '--print'),
        dest='gen_print',
        action='store_true')
    parser.add_argument(
        '--search', '-s',
        help=_complete_help('Generate search files.', '--search'),
        dest='gen_search',
        action='store_true')
    parser.add_argument(
        '--search-global',
        help=_complete_help('Generate global search configuration.', '--search-global'),
        dest='gen_search_global',
        action='store_true')
    parser.add_argument(
        '--prod-git-repos-location',
        help='Location of the productions git repositories on the server. This is used to '
             'generate production vhost and search.',
        dest='prod_git_repos_location')
    parser.add_argument(
        '--copy-img', '-i',
        help=_complete_help('Copy the images.', '--copy-img'),
        dest='gen_images',
        action='store_true')
    parser.add_argument(
        '--clean', '-c',
        help=_complete_help('Clean the output dir for the specified portal', '--clean'),
        dest='clean',
        action='store_true')
    parser.add_argument(
        '--config',
        help=_complete_help('Print the configuration on stdin and exit', '--config'),
        dest='config',
        action='store_true')
    parser.add_argument(
        '--vhost',
        help=_complete_help('Generate the vhosts', '--vhost'),
        dest='gen_vhosts',
        action='store_true')

    args = parser.parse_args()
    main(args)
