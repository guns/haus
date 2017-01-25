# ============================================================================
# FILE: base.py
# AUTHOR: Shougo Matsushita <Shougo.Matsu at gmail.com>
# License: MIT license
# ============================================================================

from abc import abstractmethod
import denite.util


class Base(object):

    def __init__(self, vim):
        self.vim = vim
        self.name = 'base'
        self.syntax_name = ''
        self.kind = 'base'
        self.matchers = ['matcher_fuzzy']
        self.sorters = ['sorter_sublime']
        self.converters = []
        self.context = {}
        self.vars = {}

    def highlight(self):
        pass

    def define_syntax(self):
        self.vim.command(
            'syntax region ' + self.syntax_name + ' start=// end=/$/ '
            'contains=deniteMatchedRange contained')

    @abstractmethod
    def gather_candidate(self, context):
        pass

    def debug(self, expr):
        denite.util.debug(self.vim, expr)