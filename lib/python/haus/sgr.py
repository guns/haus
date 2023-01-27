# Copyright (c) 2011-2023 Sung Pae <self@sungpae.com>

"""
Module for working with ANSI SGR codes.

http://www.inwap.com/pdp10/ansicode.txt
http://en.wikipedia.org/wiki/ANSI_escape_code#graphics
"""

import builtins
import os
import sys
from typing import IO, Any, List

CODES = {
    "reset": "0",
    "bold": "1",
    "nobold": "21",
    "dim": "2",
    "nodim": "22",
    "italic": "3",
    "noitalic": "23",
    "underline": "4",
    "nounderline": "24",
    "slowblink": "5",
    "noblink": "25",
    "rapidblink": "6",
    "reverse": "7",
    "noreverse": "27",
    "conceal": "8",
    "noconceal": "28",
    "strikeout": "9",
    "nostrikeout": "29",
    "fraktur": "20",
    "nofraktur": "23",
    "black": "30",
    "BLACK": "40",
    "red": "31",
    "RED": "41",
    "green": "32",
    "GREEN": "42",
    "yellow": "33",
    "YELLOW": "43",
    "blue": "34",
    "BLUE": "44",
    "magenta": "35",
    "MAGENTA": "45",
    "cyan": "36",
    "CYAN": "46",
    "white": "37",
    "WHITE": "47",
    "default": "39",
    "DEFAULT": "49",
    "frame": "51",
    "noframe": "54",
    "encircle": "52",
    "noencircle": "54",
    "overline": "53",
    "nooverline": "55",
    "ideogram_underline": "60",
    "ideogram_double_underline": "61",
    "ideogram_overline": "62",
    "ideogram_double_overline": "63",
    "ideogram_stress": "64",
}


def _init() -> None:
    if "x0" not in CODES:
        for n in range(256):
            CODES[f"x{n}"] = f"38;5;{n}"
            CODES[f"X{n}"] = f"48;5;{n}"


def format(msg: str, styles: List[str] = [], file: IO[Any] = sys.stdout) -> str:
    """
    Wrap msg in SGR escape sequences if file is a TTY.

        sgr.format("hello world.", ["green", "bold"], file=sys.stderr)
        sgr.format("hello world.", ["x46", "X248"]) # 256 color table
    """
    if os.isatty(file.fileno()):
        return f"\033[{';'.join([CODES.get(s, s) for s in styles])}m{msg}\033[m"
    else:
        return msg


def print(
    msg: str, styles: List[str] = [], file: IO[Any] = sys.stdout, **kwargs: Any
) -> None:
    """
    Print msg to file with SGR escape sequences if file is a TTY.

        sgr.print("hello world.", ["green", "bold"], file=sys.stderr)
        sgr.print("hello world.", ["x46", "X248"]) # 256 color table
    """
    builtins.print(format(msg, styles, file=file), file=file, **kwargs)


_init()
del _init
