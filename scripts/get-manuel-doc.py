#!/usr/bin/env python3

import re

from glob import glob


def find_doc(task_file):
    manuel_doc = ''
    for task, doc in finder.findall(task_file.read()):
        manuel_doc += '## ' + task + '\n'
        manuel_doc += doc + '\n\n\n'

    return manuel_doc


if __name__ == '__main__':
    finder = re.compile(r'''^HELP\['([a-zA-Z-_]+)'\]="([^"]+)"''', re.DOTALL|re.MULTILINE)
    manuel_doc = '# Manuel\n'
    manuel_doc += 'To generate this file, use `python3 scripts/get-manuel-doc.py > docs/manuel.md`\n\n'

    with open('manuelfile', 'r') as manuelfile:
        manuel_doc += find_doc(manuelfile)

    for task_file in glob('tasks/*.sh'):
        with open(task_file, 'r') as task_file:
            manuel_doc += find_doc(task_file)

    print(manuel_doc.strip())
