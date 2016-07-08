import os
import re

from glob import glob
from os.path import exists, splitext

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
        infra_dir = self.config['infra_dir'].split('/')[-1]
        self.config['search']['customer'] = infra_dir.replace('-infra', '')
        
        portal_name = self.config['geoportal']['name']
        self.config['search']['name'] = portal_name
        self._load_alias(infra_dir)

        self.render(self.src['search_db'], self.dest['search_portal'], self.config)
        self.render(self.src['search_portal_layers'], self.dest['search_portal'], self.config)
        self.render(self.src['search_portal_locations'], self.dest['template_search_portal_locations'], self.config, dest_is_file=True)

        self.config['geoportal']['name'] = portal_name

    def _get_langs_tsv_files(self):
        langs = []
        for tsv in glob(self.src['tsv_files']):
            name, _ = splitext(tsv)
            _, lang = name.split('_')
            langs.append(lang)

        return langs

    def _load_alias(self, infra_dir):
        if exists('.aliases'):
            find_alias_re = self.find_alias_re_template.format(
                infra=infra_dir,
                portal=self.config.portal)
            with open('.aliases', 'r') as alias_file:
                aliases = alias_file.read()
            match = re.search(find_alias_re, aliases, re.M)
            if match:
                self.config['geoportal']['name'] = match.group(1)

    def generate_global(self, customer_infra_dir):
        '''Generate the global configuration for search.
        '''
        os.makedirs(self.dest['search'], exist_ok=True)
        self.config['search']['customer_infra_dir'] = customer_infra_dir
        for template in glob(self.src['search']):
            self.render(template, self.dest['search'], self.config)
