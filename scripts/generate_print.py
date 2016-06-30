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
