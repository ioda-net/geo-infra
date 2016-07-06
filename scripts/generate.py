#!/usr/bin/env python3

'''Main script used to generate the files for mapinfra.

Call this script with the ``--help`` argument for more details.
'''


import argparse
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


REQUIRE_PORTAL = set((
    '--map', '-m',
    '--json', '-j',
    '--help-site',
    '--print', '-p',
    '--search', '-s',
    '--copy-img', '-i',
    '--clean', '-c',
    '--config',
))
REQUIRE_TYPE = set((
    '--search-global',
))
REQUIRE_TYPE.update(REQUIRE_PORTAL)
REQUIRE_INFRA_DIR = set(REQUIRE_PORTAL)
REQUIRE_SEARCH_GOLBAL = set((
    '--customer-infra-dir',
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
    config = GenerateConfig(portal=args.portal, type=args.type, infra_dir=args.infra_dir)
    kwargs = {
        'type': args.type,
        'portal': args.portal,
        'verbose': args.verbose,
        'ssl_validation': args.ssl_verify,
        'config': config,
    }

    if args.config:
        print(json.dumps(config.config))

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
            search_generator.generate_global(args.customer_infra_dir)

    if args.gen_images:
        _verbose('Generate images', args)
        GenerateImages(**kwargs).generate()


def _verbose(task, args):
    if args.verbose:
        print(task, end='')

    if args.verbose and args.type:
        print(' for type', args.type, end='')

    if args.verbose and args.portal:
        print(' for portal', args.portal, end='')

    if args.verbose:
        print()


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
        nargs='?',
        type=int,
        const=1,
        default=0)
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
        '--customer-infra-dir',
        help='Directory containing all the customer infrastructures.',
        dest='customer_infra_dir',
        required=search_global_required)
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
        help=_complete_help('Print the configuration on stdin', '--config'),
        dest='config',
        action='store_true')

    args = parser.parse_args()
    main(args)
