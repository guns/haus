# Copyright (c) 2023 Sung Pae <self@sungpae.com>

"""
Scripting helper functions.
"""

import importlib
import os
import shlex
import subprocess
import sys
from typing import IO, Any, Dict, NoReturn, Optional, Sequence
from urllib import request

from haus import http_ua, ls_colors, sgr

get_random_user_agent = http_ua.get_random_user_agent
LSColors = ls_colors.LSColors
parse_ls_colors = ls_colors.parse_ls_colors
format = sgr.format
print = sgr.print

try:
    regex = importlib.import_module("regex")
except ModuleNotFoundError:
    regex = importlib.import_module("re")


def run(
    cmd: Sequence[str],
    sgr: Sequence[str] = ["x48", "bold"],
    /,
    file: IO[Any] = sys.stderr,
    sep: Optional[str] = " ",
    end: Optional[str] = "\n",
    flush: bool = False,
    **kwargs: Any,
) -> subprocess.CompletedProcess[Any]:
    """
    Print cmd to stderr with sgr codes, then execute subprocess.run(cmd, **kwargs).
    """
    print("> " + shlex.join(cmd), sgr, file=file, sep=sep, end=end, flush=flush)
    return subprocess.run(cmd, **kwargs)


def execvp(
    cmd: Sequence[str],
    sgr: Sequence[str] = ["x48", "bold"],
    /,
    file: IO[Any] = sys.stderr,
    **kwargs: Any,
) -> NoReturn:
    """
    Print cmd to stderr with sgr codes, then execute os.execvp().
    """
    print("> " + shlex.join(cmd), sgr, **kwargs)
    prg, *args = cmd
    os.execvp(prg, args)


def urlopen(
    url: str, headers: Optional[Dict[str, str]] = None, **kwargs: Any
) -> request._UrlopenRet:
    """
    Execute an HTTP request to url with a recent User-Agent header.
    """
    if headers is None:
        ua = get_random_user_agent("Linux")
        if ua is None:
            raise RuntimeError("User-Agent search failed")
        headers = {"User-Agent": ua}

    req = request.Request(url, headers=headers, **kwargs)
    return request.urlopen(req)
