import os

from generate_utils import Generate


class GenerateVhosts(Generate):
    def generate(self):
        template_path = self.config['src']['vhost']
        out_file = self.config['dest']['vhost']
        os.makedirs(os.path.dirname(out_file), exist_ok=True)
        self.render(template_path, out_file, self.config.config, dest_is_file=True)
