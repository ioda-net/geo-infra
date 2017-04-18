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

import csv
import logging

from io import StringIO
from urllib.request import urlopen

from generate_utils import Generate, is_url, save_json
from generate_utils import path as create_path


NON_LANGUAGE_KEYS = (
    'key', '', 'msgid',
    'comment', 'commentaire', 'comments', 'commentaires',
)


class Translator(Generate):
    '''Build the translation dictionnary used to translate the frontend.
    '''
    def __init__(self, files, verbose):
        self.files = files
        self.verbose = verbose

    def get_translations(
            self,
            ignore_file_name=None,
            delimiter=',',
            quotechar='"',
            output_folder=None,
            languages_to_save=None,
            pretty=True):
        '''Read the content of the translations files (on disk on from a URL) and save the
        constructed dict of translations in the specified output folder.

        If a work is on the ignore list, it will not go into the constructed translation dict.
        '''
        self.translations = {}
        self.ignore_list = self._get_ignore_list(
            ignore_file_name,
            delimiter=delimiter,
            quotechar=quotechar)
        self._process_files(delimiter=delimiter, quotechar=quotechar)
        if output_folder:
            self.save_translations(
                output_folder,
                languages_to_save=languages_to_save,
                pretty=pretty)

    def _get_ignore_list(self, file_name, quotechar='"', delimiter=','):
        ignore_list = []
        if file_name:
            with open(file_name, 'r') as ignore_csv:
                csvreader = csv.reader(
                    ignore_csv,
                    quotechar=quotechar,
                    delimiter=delimiter)
                for row in csvreader:
                    ignore_list.append(row[0])

        return ignore_list

    def _process_files(self, delimiter=',', quotechar='"'):
        for filename in self.files:
            logging.debug('Working on : ' + filename)

            csv_file, is_url = self._open_csv_file(filename)
            # file may not exists. In this case, csv_file is None
            if csv_file is None:
                continue

            csv_reader = csv.DictReader(
                csv_file,
                delimiter=delimiter,
                quotechar=quotechar)
            self._process_csv_file(csv_reader)
            self._close_csv_file(csv_file, is_url)

    def _open_csv_file(self, filename):
        if is_url(filename):
            try:
                resp = urlopen(filename)
                csv_file = StringIO(resp.read().decode('utf-8'))
            except:
                logging.warn('Could not open {}'.format(filename))
                csv_file = None
        else:
            try:
                csv_file = open(filename, 'r')
            except FileNotFoundError:
                logging.warn('Could not open {}'.format(filename))
                csv_file = None

        return csv_file, is_url(filename)

    def _process_csv_file(self, csv_reader):
        if not self.translations:
            init_translations = self._init_translations(csv_reader.fieldnames)
            self.translations.update(init_translations)
        for row in csv_reader:
            if self.verbose >= 2:
                print ('\t\t', row)
            self._process_row(row)

    def _process_row(self, row):
        json_key = row.get('key', None) or row.get('msgid', None) or row.get('', None)
        if json_key is not None and json_key not in self.ignore_list:
            langs_translations = [(key.lower(), value)
                                  for key, value in row.items()
                                  if self._is_language_key(key)]
            for lang, traduction in langs_translations:
                traduction = traduction if traduction else json_key
                self.translations[lang][json_key] = traduction

    def _is_language_key(self, key):
        return key is not None and key.lower() not in NON_LANGUAGE_KEYS

    def _init_translations(self, fieldnames):
        return {lang.lower(): {} for lang in fieldnames if self._is_language_key(lang)}

    def _close_csv_file(self, csv_file, is_url):
        if not is_url:
            csv_file.close()

    def save_translations(self, output_folder, languages_to_save=None, pretty=True):
        '''Save the translation files in the JSON format for usage in the frontend.
        '''
        if languages_to_save is None:
            languages_to_save = self.translations.keys()
        for lang in languages_to_save:
            json_file = create_path(output_folder, lang.lower(), ext='.json')
            save_json(json_file, self.translations[lang], pretty=pretty)


class CatalogTranslator:
    '''Allow the user to access function design to translate the layers catalog.

    To acces to the translate function for a language, use ``catalogTranslatro[lang]``. This
    function will then take the text to translate as an argument and return its translation.

    Args:
        src_catalog_translations (str): path to the CSV file that contains the translations for the
            catalog.
    '''
    def __init__(self, src_catalog_translations, delimiter=',', quotechar='"'):
        self._generate_catalog_translations(
            src_catalog_translations,
            delimiter=delimiter,
            quotechar=quotechar)
        self.langs = set()
        for translations in self.translations.values():
            self.langs.update(translations.keys())

    def _generate_catalog_translations(
            self,
            src_catalog_translations,
            delimiter=',',
            quotechar='"'):
        with open(src_catalog_translations, 'r') as translations_file:
            self.translations = {}
            csv_reader = csv.DictReader(
                translations_file,
                delimiter=delimiter,
                quotechar=quotechar)
            for row in csv_reader:
                key = row['key'] if 'key' in row else row['']
                self.translations[key] = {}
                for lang in row:
                    if lang not in NON_LANGUAGE_KEYS:
                        self.translations[key][lang] = row[lang]

    def __getitem__(self, lang):
        def translate(input_text):
            if input_text in self.translations and \
                    self.translations.get(input_text, {}).get(lang, ''):
                return self.translations[input_text][lang]
            else:
                return input_text
        return translate
