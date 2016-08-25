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

'''Helper class and functions to generate the configuration of a portal.
'''


import collections
import json
import logging
import os
import shutil
import sys

from glob import glob
from http.server import CGIHTTPRequestHandler, HTTPServer
from jinja2cli.cli import render
from os.path import abspath, basename, exists, isdir, join, samefile
from threading import Thread
from urllib.parse import urlparse


class SilentCGIHTTPRequestHandler(CGIHTTPRequestHandler):
    '''Helper class to silence output of CGIHTTPRequestHandler.CGIHTTPRequestHandler.

    Prevent requests to be logged to stdout.'''
    def log_request(self, *args, **kwargs):
        pass


def cgi_server(address='', port=8888):
    '''Start a silent cgi server forever.

    If you call this function directly, it will block the main thread until you stop it with Ctl-C.
    '''
    httpd = HTTPServer((address, port), SilentCGIHTTPRequestHandler)
    httpd.serve_forever()


def start_cgi_server(address='', port=8888):
    '''Start the cgi server in a dedicated thread.

    See also:
        :func:`cgi_server` the function used to start the cgi server.
    '''
    t = Thread(target=cgi_server, daemon=True, kwargs={'address': address, 'port': port})
    t.start()


def is_url(path):
    '''Return true if the argument has an 'http' or 'https' scheme.
    '''
    return urlparse(path).scheme in ('http', 'https')


def path(*paths, ext=''):
    '''Join path and append extension.

    Args:
        paths: the list of path to join.
        ext (str): the extension to append at the end of the path. Default: ''.
    '''
    new_path = join(*paths)

    return new_path + ext


def save_json(filename, content, pretty=False):
    '''Save a python dict in a json file.

    Args:
        filename (str): the path of the file in which to save the content.
        content (dict): the python dict object to dump as json
        pretty (bool): whether or not to save the json in a easily readable way. Default: False.
    '''
    with open(filename, 'w') as jsonfile:
        indent = 4 if pretty else None
        # "separators=(',', ': ')" is required to avoid a trailing
        # whitespace in python < 3.4
        json.dump(
            content,
            jsonfile,
            indent=indent,
            sort_keys=True,
            ensure_ascii=False,
            separators=(',', ': '))


class Generate:
    '''Utilitary class for all generate type classes.

    Args:
        portal (str): the name of the portal used to generate.
        type (str): the type for which to generate. Must be either dev or prod.
        verbose (bool): print verbose messages.
        ssl_validation (bool): whether or not to verify certificates for https
        config (generate_config.GenerateConfig): the configuration for the portal.
    '''

    #: The languages to use if no languages are specified in the configuration.
    DEFAULT_LANGS = ('fr', 'de')

    def __init__(self, portal=None, type=None, verbose=False, ssl_validation=True, config=None):
        self.config = config
        self.portal = portal
        self.type = type
        self.pretty = type == 'dev'
        self.ssl_validation = ssl_validation
        self.verbose = verbose

        self.dest = self.config['dest']
        self.src = self.config['src']
        self.langs = self.config\
            .get('geoportal', {})\
            .get('langs', self.DEFAULT_LANGS)

    def path(self, *paths, ext=''):
        '''Alias to :func:`path`
        '''
        return path(*paths, ext=ext)

    def save_json(self, filename, content):
        '''Alias to :func:`save_json`
        '''
        save_json(filename, content, pretty=self.pretty)

    def report_errors(self, errors, header=None):
        '''Print a list of errors to stderr.

        Args:
            errors (List[str]): list of errors to display.
            header (str): an optional header to print before the errors. Default: None.
        '''
        if errors:
            if header:
                logging.error('** ' + header)
            if isinstance(errors, list):
                errors = '\n'.join(errors)
            logging.error(errors)

    def copy(self, src, dest, copy_dir=True, copy_dir_content=False):
        '''Copy files or directories from one location to another.

        Args:
            src (Union[str, list, tuple, set]): the source of the copy. If it is iterable and not a
                string, the function will recurse for each element. If it is a string, each element in
                the resulting glob is copied.
            dest (str): the path to destination folder.
            copy_dir (bool): whether or not to copy directories. If this option is true and src is a
                directory, src will be copied as a directory (with all its content) into dest. The
                result of the copy will be dest/src/. Default: True.
            copy_dir_content (bool): if this option is True and src is a directory, the content of
                src will be copied into dest. Default: False.
        '''
        if isinstance(src, collections.Iterable) and not isinstance(src, str):
            for elt in src:
                self.copy(elt, dest, copy_dir=copy_dir, copy_dir_content=copy_dir_content)
        elif copy_dir_content and isdir(src):
            self.copy(
                self.path(src, '*'),
                dest,
                copy_dir=copy_dir,
                copy_dir_content=copy_dir_content)
        else:
            for elt in glob(src):
                self._copy(elt, dest, copy_dir=copy_dir)

    def _copy(self, src, dest, copy_dir=True):
        if isdir(src) and copy_dir:
            self._copy_dir(src, dest)
        elif not isdir(src):
            shutil.copy(src, dest)

    def _copy_dir(self, src, dest):
        name = basename(src)
        dest = self.path(dest, name)
        self.remove(dest)
        shutil.copytree(src, dest)

    def remove(self, src):
        '''Remove the given path (file or directory).

        The source is only removed if it is under the output directory of the current portal. It
        will not remove the directory of the current portal. If you try to remove something else, a
        warning is printed instead.
        '''
        src = abspath(src)

        # Don't try to remove if src doesn't exist
        if not exists(src):
            return

        # We can only remove things under {type}/{portal}/* (output dir)
        # We manually check that the path looks good with self.type and self.portal and is not a
        # hidden file or folder (like .git)
        if self.type in src and \
                self.portal in src and \
                '/.' not in src and \
                src.startswith(self.dest['output']) and \
                not samefile(src, self.dest['output']):
            if isdir(src):
                shutil.rmtree(src)
            else:
                os.remove(src)
        else:
            message = '*** WARNING: Trying to remove {} which is not under {} or is hidden'\
                .format(src, self.dest['output'])
            logging.warn(message)

    def clean(self):
        '''Remove all files and directories in the ouput dir of the portal.
        '''
        for f in glob(self.path(self.dest['output'], '*')):
            self.remove(f)

    def render(self, template_path, dest_folder, data, dest_is_file=False, extensions=None):
        '''Render a template with jinja2 and default markup.

        Args:
            template_path (str): the path to the template.
            dest_folder (str): where to save the result.
            data (dict): data used to render the template.
            dest_is_file (bool): indicate if dest_folder is a file. Default: False.
            extensions (list): list of jinja2 extensions to use. Default: None.
        '''
        if extensions is None:
            extensions = []

        if not isinstance(data, dict):
            data = data.config

        if dest_is_file:
            dest_path = dest_folder
        else:
            rendered_filename = basename(template_path)\
                .replace(self.src['base_include'], '')\
                .replace('.in', '')
            dest_path = self.path(dest_folder, rendered_filename)

        with open(dest_path, 'w') as dest_file:
            content = render(template_path, data, extensions)
            dest_file.write(content.decode('utf-8'))
