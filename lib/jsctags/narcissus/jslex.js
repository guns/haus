/* vim: set sw=4 ts=8 et tw=78: */
/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Narcissus JavaScript engine.
 *
 * The Initial Developer of the Original Code is
 * Brendan Eich <brendan@mozilla.org>.
 * Portions created by the Initial Developer are Copyright (C) 2004
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

/*
 * Narcissus - JS implemented in JS.
 *
 * Lexical scanner.
 */

var m_jsdefs = require('./jsdefs');
var assignOps = m_jsdefs.assignOps;
var keywords = m_jsdefs.keywords;
var opTypeNames = m_jsdefs.opTypeNames;
var tokenIds = m_jsdefs.tokenIds;
var tokens = m_jsdefs.tokens;

eval(m_jsdefs.defineTokenConstants());

// Build up a trie of operator tokens.
var opTokens = {};
for (var op in opTypeNames) {
    if (op === '\n' || op === '.')
        continue;

    var node = opTokens;
    for (var i = 0; i < op.length; i++) {
        var ch = op[i];
        if (!(ch in node))
            node[ch] = {};
        node = node[ch];
        node.op = op;
    }
}

// file ptr, path to file, line number -> Tokenizer
exports.Tokenizer = function(s, f, l) {
    this.cursor = 0;
    this.source = String(s);
    this.tokens = [];
    this.tokenIndex = 0;
    this.lookahead = 0;
    this.scanNewlines = false;
    this.scanOperand = true;
    this.filename = f || "";
    this.lineno = l || 1;
}

exports.Tokenizer.prototype = {
    get done() {
        return this.peek() == END;
    },

    get token() {
        return this.tokens[this.tokenIndex];
    },

    match: function (tt) {
        return this.get() == tt || this.unget();
    },

    mustMatch: function (tt) {
        if (!this.match(tt))
            throw this.newSyntaxError("Missing " + tokens[tt].toLowerCase());
        return this.token;
    },

    peek: function () {
        var tt, next;
        if (this.lookahead) {
            next = this.tokens[(this.tokenIndex + this.lookahead) & 3];
            tt = (this.scanNewlines && next.lineno != this.lineno)
                 ? NEWLINE
                 : next.type;
        } else {
            tt = this.get();
            this.unget();
        }
        return tt;
    },

    peekOnSameLine: function () {
        this.scanNewlines = true;
        var tt = this.peek();
        this.scanNewlines = false;
        return tt;
    },

    // Eats comments and whitespace.
    skip: function () {
        var input = this.source;
        for (;;) {
            var ch = input[this.cursor++];
            var next = input[this.cursor];
            if (ch === '\n' && !this.scanNewlines) {
                this.lineno++;
            } else if (ch === '/' && next === '*') {
                this.cursor++;
                for (;;) {
                    ch = input[this.cursor++];
                    if (ch === undefined)
                        throw this.newSyntaxError("Unterminated comment");

                    if (ch === '*') {
                        next = input[this.cursor];
                        if (next === '/') {
                            this.cursor++;
                            break;
                        }
                    } else if (ch === '\n') {
                        this.lineno++;
                    }
                }
            } else if (ch === '/' && next === '/') {
                this.cursor++;
                for (;;) {
                    ch = input[this.cursor++];
                    if (ch === undefined)
                        return;

                    if (ch === '\n') {
                        this.lineno++;
                        break;
                    }
                }
            } else if (ch !== ' ' && ch !== '\t' && ch !== '\r') {
                this.cursor--;
                return;
            }
        }
    },

    // Lexes the exponential part of a number, if present. Returns true iff an
    // exponential part was found.
    lexExponent: function() {
        var input = this.source;
        var next = input[this.cursor];
        if (next === 'e' || next === 'E') {
            this.cursor++;
            ch = input[this.cursor++];
            if (ch === '+' || ch === '-')
                ch = input[this.cursor++];

            if (ch < '0' || ch > '9')
                throw this.newSyntaxError("Missing exponent");

            do {
                ch = input[this.cursor++];
            } while (ch >= '0' && ch <= '9');
            this.cursor--;

            return true;
        }

        return false;
    },

    lexZeroNumber: function (ch) {
        var token = this.token, input = this.source;
        token.type = NUMBER;

        ch = input[this.cursor++];
        if (ch === '.') {
            do {
                ch = input[this.cursor++];
            } while (ch >= '0' && ch <= '9');
            this.cursor--;

            this.lexExponent();
            token.value = parseFloat(token.start, this.cursor);
        } else if (ch === 'x' || ch === 'X') {
            do {
                ch = input[this.cursor++];
            } while ((ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') ||
                     (ch >= 'A' && ch <= 'F'));
            this.cursor--;

            token.value = parseInt(input.substring(token.start, this.cursor));
        } else if (ch >= '0' && ch <= '7') {
            do {
                ch = input[this.cursor++];
            } while (ch >= '0' && ch <= '7');
            this.cursor--;

            token.value = parseInt(input.substring(token.start, this.cursor));
        } else {
            this.cursor--;
            this.lexExponent();     // 0E1, &c.
            token.value = 0;
        }
    },

    lexNumber: function (ch) {
        var token = this.token, input = this.source;
        token.type = NUMBER;

        var floating = false;
        do {
            ch = input[this.cursor++];
            if (ch === '.' && !floating) {
                floating = true;
                ch = input[this.cursor++];
            }
        } while (ch >= '0' && ch <= '9');

        this.cursor--;

        var exponent = this.lexExponent();
        floating = floating || exponent;

        var str = input.substring(token.start, this.cursor);
        token.value = floating ? parseFloat(str) : parseInt(str);
    },

    lexDot: function (ch) {
        var token = this.token, input = this.source;
        var next = input[this.cursor];
        if (next >= '0' && next <= '9') {
            do {
                ch = input[this.cursor++];
            } while (ch >= '0' && ch <= '9');
            this.cursor--;

            this.lexExponent();

            token.type = NUMBER;
            token.value = parseFloat(token.start, this.cursor);
        } else {
            token.type = DOT;
            token.assignOp = null;
            token.value = '.';
        }
    },

    lexString: function (ch) {
        var token = this.token, input = this.source;
        token.type = STRING;

        var hasEscapes = false;
        var delim = ch;
        ch = input[this.cursor++];
        while (ch !== delim) {
            if (ch === '\\') {
                hasEscapes = true;
                this.cursor++;
            }
            ch = input[this.cursor++];
        }

        token.value = (hasEscapes)
                      ? eval(input.substring(token.start, this.cursor))
                      : input.substring(token.start + 1, this.cursor - 1);
    },

    lexRegExp: function (ch) {
        var token = this.token, input = this.source;
        token.type = REGEXP;

        do {
            ch = input[this.cursor++];
            if (ch === '\\') {
                this.cursor++;
            } else if (ch === '[') {
                do {
                    if (ch === undefined)
                        throw this.newSyntaxError("Unterminated character class");

                    if (ch === '\\')
                        this.cursor++;

                    ch = input[this.cursor++];
                } while (ch !== ']');
            } else if (ch === undefined) {
                throw this.newSyntaxError("Unterminated regex");
            }
        } while (ch !== '/');

        do {
            ch = input[this.cursor++];
        } while (ch >= 'a' && ch <= 'z');

        this.cursor--;

        token.value = eval(input.substring(token.start, this.cursor));
    },

    lexOp: function (ch) {
        var token = this.token, input = this.source;

        // A bit ugly, but it seems wasteful to write a trie lookup routine for
        // only 3 characters...
        var node = opTokens[ch];
        var next = input[this.cursor];
        if (next in node) {
            node = node[next];
            this.cursor++;
            next = input[this.cursor];
            if (next in node) {
                node = node[next];
                this.cursor++;
                next = input[this.cursor];
            }
        }

        var op = node.op;
        if (assignOps[op] && input[this.cursor] === '=') {
            this.cursor++;
            token.type = ASSIGN;
            token.assignOp = tokenIds[opTypeNames[op]];
            op += '=';
        } else {
            token.type = tokenIds[opTypeNames[op]];
            if (this.scanOperand) {
                switch (token.type) {
                  case PLUS:    token.type = UNARY_PLUS;    break;
                  case MINUS:   token.type = UNARY_MINUS;   break;
                }
            }

            token.assignOp = null;
        }

        token.value = op;
    },

    // FIXME: Unicode escape sequences
    // FIXME: Unicode identifiers
    lexIdent: function (ch) {
        var token = this.token, input = this.source;

        do {
            ch = input[this.cursor++];
        } while ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') ||
                 (ch >= '0' && ch <= '9') || ch === '$' || ch === '_');

        this.cursor--;  // Put the non-word character back.

        var id = input.substring(token.start, this.cursor);
        token.type = keywords[id] || IDENTIFIER;
        token.value = id;
    },

    // void -> token type
    // It consumes input *only* if there is no lookahead.
    // Dispatch to the appropriate lexing function depending on the input.
    get: function () {
        var token;
        while (this.lookahead) {
            --this.lookahead;
            this.tokenIndex = (this.tokenIndex + 1) & 3;
            token = this.tokens[this.tokenIndex];
            if (token.type != NEWLINE || this.scanNewlines)
                return token.type;
        }

        this.skip();

        this.tokenIndex = (this.tokenIndex + 1) & 3;
        token = this.tokens[this.tokenIndex];
        if (!token)
            this.tokens[this.tokenIndex] = token = {};

        var input = this.source;
        if (this.cursor >= input.length)
            return token.type = END;

        token.start = this.cursor;
        token.lineno = this.lineno;

        var ch = input[this.cursor++];
        if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') ||
                ch === '$' || ch === '_') {
            this.lexIdent(ch);
        } else if (this.scanOperand && ch === '/') {
            this.lexRegExp(ch);
        } else if (ch in opTokens) {
            this.lexOp(ch);
        } else if (ch === '.') {
            this.lexDot(ch);
        } else if (ch >= '1' && ch <= '9') {
            this.lexNumber(ch);
        } else if (ch === '0') {
            this.lexZeroNumber(ch);
        } else if (ch === '"' || ch === "'") {
            this.lexString(ch);
        } else if (this.scanNewlines && ch === '\n') {
            token.type = NEWLINE;
            token.value = '\n';
            this.lineno++;
        } else {
            throw this.newSyntaxError("Illegal character " + ch.charCodeAt(0));
        }

        token.end = this.cursor;
        return token.type;
    },

    // void -> undefined
    // match depends on unget returning undefined.
    unget: function () {
        if (++this.lookahead == 4) throw "PANIC: too much lookahead!";
        this.tokenIndex = (this.tokenIndex - 1) & 3;
    },

    newSyntaxError: function (m) {
        var e = new SyntaxError(m, this.filename, this.lineno);
        e.source = this.source;
        e.cursor = this.cursor;
        e.fileName = this.filename;
        e.lineNumber = this.lineno;
        return e;
    }
};

