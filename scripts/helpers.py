"""Taken from chsdi.lib.helpers"""


import unicodedata


def format_search_text(input_str):
    return remove_accents(
        escape_sphinx_syntax(input_str)
    )


def remove_accents(input_str):
    if input_str is None:  # pragma: no cover
        return input_str
    input_str = input_str.translate(str.maketrans({
        'Ü': 'ue',
        'ä': 'ae',
        'Ä': 'ae',
        'ö': 'oe',
        'Ö': 'oe',
        'ü': 'ue',
        'â': 'a',
        'à': 'a',
        'ê': 'e',
        'è': 'e',
        'é': 'e',
        'ù': 'u',
    }))
    # Different from lib helper to please sphinx
    return unicodedata.normalize('NFD', input_str)


def escape_sphinx_syntax(input_str):
    if input_str is None:  # pragma: no cover
        return input_str
    return input_str.translate(str.maketrans({
        '|': r'\|',
        '!': r'\!',
        '@': r'\@',
        '&': r'\&',
        '~': r'\~',
        '^': r'\^',
        '=': r'\=',
        '/': r'\/',
        '(': r'\(',
        ')': r'\)',
        ']': r'\]',
        '[': r'\[',
        '*': r'\*',
        '<': r'\<',
        '$': r'\$',
        '"': r'\"',
    }))
