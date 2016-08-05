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

import copy
import csv
import logging
import os
import re
import requests

from bs4 import BeautifulSoup
from glob import glob
from io import BytesIO
from os.path import basename, exists, splitext
from PIL import Image
from urllib.parse import quote, unquote
from urllib.parse import urlparse

from generate_utils import Generate


class GenerateHelpConfig(Generate):
    '''Generate the help website and fetch texts and images from Swisstopo.
    '''

    #: Regexp used to detect the links to the Swisstopo website so we can correct them.
    HELP_GEO_ADMIN_REGEXP = re.compile(r'(?:https?:)?//help.geo.admin.ch/([^ ])')
    #: Regexp used to convert images from jpg to png.
    JEPG_TO_PNG_REGEXP = re.compile(r'\.(jpg|jpeg)')
    #: URLS pointing to the text in each languages.
    TEXT_URLS = {
        'en': 'https://www.googleapis.com/fusiontables/v1/query?key=AIzaSyDT7wmEx97gAG5OnPwKyz2PnCx3yT4j7C0&sql=select+*+from+1Tx2VSM1WHZfDXzf8rweRLG1kd23AA4aw8xnZ_3c+where+col5+%3D+%27en%27+order+by+col8&_=1442242212913',
        'fr': 'https://www.googleapis.com/fusiontables/v1/query?key=AIzaSyDT7wmEx97gAG5OnPwKyz2PnCx3yT4j7C0&sql=select+*+from+1Tx2VSM1WHZfDXzf8rweRLG1kd23AA4aw8xnZ_3c+where+col5+%3D+%27fr%27+order+by+col8&_=1444823149806',
        'it': 'https://www.googleapis.com/fusiontables/v1/query?key=AIzaSyDT7wmEx97gAG5OnPwKyz2PnCx3yT4j7C0&sql=select+*+from+1Tx2VSM1WHZfDXzf8rweRLG1kd23AA4aw8xnZ_3c+where+col5+%3D+%27it%27+order+by+col8&_=1444823166829',
        'de': 'https://www.googleapis.com/fusiontables/v1/query?key=AIzaSyDT7wmEx97gAG5OnPwKyz2PnCx3yT4j7C0&sql=select+*+from+1Tx2VSM1WHZfDXzf8rweRLG1kd23AA4aw8xnZ_3c+where+col5+%3D+%27de%27+order+by+col8&_=1444823120334',
    }
    #: Where to download the special pages.
    SPECIAL_PAGES_URLS = {
        'parameter': {
            'de': 'https://raw.githubusercontent.com/geoadmin/web-geoadmin-help/master/htdocs/special/parameter.html',
            'fr': 'https://raw.githubusercontent.com/geoadmin/web-geoadmin-help/master/htdocs/special/parameter_fr.html',
            'en': 'https://raw.githubusercontent.com/geoadmin/web-geoadmin-help/master/htdocs/special/parameter_en.html',
        },
        'shortcuts': {
            'en': 'https://raw.githubusercontent.com/geoadmin/web-geoadmin-help/master/htdocs/shortcuts.html',
        }
    }
    #: Convent the name of a special page to its id.
    SPECIAL_PAGES_NAME_TO_ID = {
        'parameter': 54,
        'shortcuts': 69,
    }
    #: The template for help files used in the front end to display help.
    FRONT_HELP_TEMPLATE = {
        "kind": "fusiontables#sqlresponse",
        "columns": [
            "id",
            "Title",
            "Content",
            "Legend",
            "Image",
            "lang",
            "RST Content",
            "HTML Content",
            "sort",
            "group"
        ],
        "rows": [
            [
                "{id}",
                "Recherche de données (catalogue)",
                "Sous \"Changer thème\" vous trouverez l'ensemble des géodonnées disponibles classées par thèmes. Lorsque vous sélectionnez un jeu de données (en cliquant sur le cercle à droite), celui-ci est directement affiché.",
                "",
                "//help.geo.admin.ch/img/32f.jpg",
                "fr",
                "",
                "",
                "15",
                "submenu3"
            ]
        ]
    }

    #: Contains the id of the help texts to ignore
    ignores = None

    def fetch_original_content(self):
        '''Fetch the help content (texts and images) from Swisstopo.

        #. Fetch the special pages and format them for inclusion in the CSV files.
        #. Fetch the texts.
        #. Append the special pages.
        #. Correct the link in the texts and save them in CSV files.
        #. Fetch the images, convert them to PNG and save them.
        '''
        special_pages = self._fetch_original_special_pages()
        for lang, url in self.TEXT_URLS.items():
            content = requests.get(url, verify=self.ssl_validation).json()
            self._append_special_pages(content['rows'], special_pages, lang=lang)
            self._save_text(lang, content['rows'])
            self._save_images(content['rows'])

    def _fetch_original_special_pages(self):
        special_pages = {}
        for name, special_pages_url in self.SPECIAL_PAGES_URLS.items():
            for lang, url in special_pages_url.items():
                page = requests.get(url, verify=self.ssl_validation).text
                id = self.SPECIAL_PAGES_NAME_TO_ID[name]
                pages_lang = special_pages.setdefault(id, {})
                pages_lang[lang] = self._format_special_page(page)

        return special_pages

    def _format_special_page(self, page):
        soup = BeautifulSoup(page, 'html.parser')
        page_content = ''
        for content in soup.body.contents:
            page_content += str(content)

        return page_content

    def _append_special_pages(self, rows, special_pages, lang='en'):
        for row in rows:
            row_id = int(row[0])
            if row_id in special_pages and row_id == 69:
                row[2] = special_pages[row_id]['en']
            elif row_id in special_pages:
                default_page = special_pages[row_id]['en']
                row[2] += special_pages[row_id].get(lang, default_page)

    def _save_text(self, lang, content):
        rows = [
            ['id', 'sort', 'title', 'content', 'legend', 'image']
        ]
        for row in content:
            sort = row[8]
            row = row[:-5]
            for i, text in enumerate(row):
                row[i] = unquote(text)

            self._fix_images_link(row)

            row.insert(1, sort)
            rows.append(row)

        filename = self.path(self.src['help_original_texts_folder'], lang, ext='.csv')
        with open(filename, 'w', newline='') as helpfile:
            csvwriter = csv.writer(helpfile, delimiter=',', quotechar='"')
            csvwriter.writerows(rows)

    def _fix_images_link(self, row):
        for i, text in enumerate(row):
            text = self.HELP_GEO_ADMIN_REGEXP.sub(r'/help/\1', text)
            text = self.JEPG_TO_PNG_REGEXP.sub(r'.png', text)
            row[i] = text

    def _save_images(self, helpcontent):
        # Some images can be_fix_images_link present mutliple times in help content. We only
        # need to download them once.
        images = set()
        for row in helpcontent:
            src = row[4]
            if src:
                src = "https:" + src if not urlparse(src).scheme else src
                images.add(src)

            content = unquote(row[2])
            soup = BeautifulSoup(content, 'html.parser')
            for img in soup.find_all('img'):
                src = img.get('src')
                src = "https:" + src if not urlparse(src).scheme else src
                images.add(src)

        images_folder = self.src['help_original_images_folder']
        os.makedirs(images_folder, exist_ok=True)
        for img in images:
            img = self._correct_images_url(img)
            response = requests.get(img, verify=self.ssl_validation)
            if response.status_code != 200:
                self.report_errors('Error for ' + img)
                continue
            img_content = BytesIO(response.content)
            image_name = img.split('/')[-1]
            logging.info('Getting : ' + image_name)
            image_name, _ = splitext(image_name)
            image_name += '.png'
            filename = self.path(images_folder, image_name)
            image = Image.open(img_content)
            image.save(filename, 'PNG')

    def _correct_images_url(self, src):
        return src.replace('////', '//')

    def generate(self):
        '''Generate the help website and its content.

        #. Copy the static files.
        #. Copy the image (swisstopo's then the ones of the portal).
        #. Generate the help texts (for the website and for the frontend).
        #. Generate the lang files which defines which langs are available on the website.
        '''
        self.ignores = self._get_text_ignores()

        # Copy site files
        dest = self.dest['help']
        self.copy(self.src['help'], dest, copy_dir=False)

        # Copy images
        dest = self.dest['help_images']
        self.copy(self.src['help_original_images_folder'], dest, copy_dir_content=True)
        self.copy(self.src['help_images_folder'], dest, copy_dir_content=True)
        background_images = self.path(self.src['help_portal_folder'], '*.jpg')
        self.copy(background_images, self.dest['help'])

        # Texts
        self._generate_help_texts()

        # Langs
        self._generate_langs_config()

    def _get_text_ignores(self):
        ignores_common = self.path(self.src['help_common_folder'], 'ignores.csv')
        ignores = self._process_ignores_file(ignores_common)
        ignores_portal = self.path(self.src['help_portal_folder'], 'ignores.csv')
        ignores.update(self._process_ignores_file(ignores_portal))

        return ignores

    def _process_ignores_file(self, filename):
        ignores = set()
        if exists(filename):
            with open(filename, 'r') as common_ignores:
                for row in csv.DictReader(common_ignores):
                    ignores.add(row['id'])

        return ignores

    def _generate_help_texts(self):
        texts = self._read_help_texts(self.src['help_original_texts_folder'])
        portal_texts = self._read_help_texts(self.src['help_texts_folder'])
        for lang in texts:
            if lang in portal_texts:
                texts[lang].update(portal_texts[lang])

        for lang in portal_texts:
            if lang not in texts:
                texts[lang] = portal_texts[lang]

        self._save_help_texts(texts)

    def _read_help_texts(self, src):
        texts = {}
        src = self.path(src, '*.csv')
        for helpfilename in glob(src):
            lang, ext = splitext(basename(helpfilename))
            texts[lang] = {}
            with open(helpfilename, 'r') as helpfile:
                reader = csv.DictReader(helpfile)
                for row in reader:
                    row['isTitle'] = row['content'] == '#'
                    id = row['id']
                    texts[lang][id] = row

        return texts

    def _save_help_texts(self, texts):
        for lang, help_texts in texts.items():
            help_texts = [help_text for help_text in help_texts.values()
                          if help_text['id'] not in self.ignores]
            help_texts.sort(key=lambda x: int(x.get('sort', 1000)))

            self._save_help_texts_front(lang, help_texts)

            dest = self.dest['help_texts']
            filename = self.path(dest, lang, ext='.json')
            self.save_json(filename, help_texts)

    def _save_help_texts_front(self, lang, help_texts):
        for text in help_texts:
            help_text = copy.deepcopy(self.FRONT_HELP_TEMPLATE)
            id = text['id']

            help_text['rows'][0] = [quote(text) for text in [
                id,
                text['title'],
                text['content'],
                text['legend'],
                text['image'],
                lang,
                text.get('RST Content', ''),
                text.get('HTML Content', ''),
                text['sort'],
                text.get('group', ''),
            ]]

            dest = self.path(
                self.dest['help_texts'],
                '{id}-{lang}.json'.format(id=id, lang=lang))
            self.save_json(dest, help_text)

    def _generate_langs_config(self):
        dest = self.path(self.dest['help'], 'langs.json')
        self.save_json(dest, self.langs)
