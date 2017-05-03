#!/usr/bin/env python3

import re

from glob import glob


def find_doc(task_file, commands, commands_to_doc):
    for task, doc in finder.findall(task_file.read()):
        commands.append(task)
        commands_to_doc[task] = doc


if __name__ == '__main__':
    finder = re.compile(r'''^HELP\['([a-zA-Z-_]+)'\]="([^"]+)"''', re.DOTALL|re.MULTILINE)
    manuel_doc = '# Manuel\n'
    manuel_doc += 'To generate this file, use *python3 scripts/get-manuel-doc.py > docs/manuel.md*\n\n'
    commands_to_doc = {}
    commands = []

    with open('manuelfile', 'r') as manuelfile:
        find_doc(manuelfile, commands, commands_to_doc)

    for task_file in glob('tasks/*.sh'):
        with open(task_file, 'r') as task_file:
            find_doc(task_file, commands, commands_to_doc)

    commands.sort()
    for cmd in commands:
        manuel_doc += '## ' + cmd + '\n'
        manuel_doc += commands_to_doc[cmd] + '\n\n\n'

    print(manuel_doc.strip())
