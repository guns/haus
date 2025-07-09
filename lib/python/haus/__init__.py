# Copyright (c) 2023 Sung Pae <self@sungpae.com>

"""
Scripting helper functions.
"""

import importlib
import importlib.machinery
import importlib.util
import os
import shlex
import subprocess
import sys
from types import ModuleType
from typing import IO, Any, NoReturn, Optional, Sequence
from urllib import request

from . import http_ua, ls_colors, sgr

DEFAULT_SGR = ("x48", "bold")

get_random_user_agent = http_ua.get_random_user_agent

LSColors = ls_colors.LSColors
parse_ls_colors = ls_colors.parse_ls_colors

format = sgr.format  # noqa: A001
print = sgr.print  # noqa: A001

try:
    regex = importlib.import_module("regex")
except ModuleNotFoundError:
    regex = importlib.import_module("re")


def run(
    cmd: Sequence[str],
    styles: Sequence[str] = DEFAULT_SGR,
    file: IO[Any] = sys.stderr,
    sep: Optional[str] = " ",
    end: Optional[str] = "\n",
    *,
    flush: bool = False,
    **kwargs: Any,
) -> subprocess.CompletedProcess[Any]:
    """
    Print cmd to stderr with sgr codes, then execute subprocess.run(cmd, **kwargs).
    """
    print("> " + shlex.join(cmd), styles, file=file, sep=sep, end=end, flush=flush)
    return subprocess.run(cmd, **kwargs)


def execvp(
    cmd: Sequence[str],
    styles: Sequence[str] = DEFAULT_SGR,
    file: IO[Any] = sys.stderr,
    **kwargs: Any,
) -> NoReturn:
    """
    Print cmd to stderr with sgr codes, then execute os.execvp().
    """
    print("> " + shlex.join(cmd), styles, file=file, **kwargs)
    prg, *args = cmd
    os.execvp(prg, args)


def urlopen(url: str, headers: Optional[dict[str, str]] = None, **kwargs: Any) -> Any:
    """
    Execute an HTTP request to url with a recent User-Agent header.
    """
    ua = get_random_user_agent("Firefox")
    if ua is None:
        raise RuntimeError("User-Agent search failed")

    if headers is None:
        headers = {"User-Agent": ua}
    elif "User-Agent" not in headers:
        headers["User-Agent"] = ua

    req = request.Request(url, headers=headers, **kwargs)
    return request.urlopen(req)


def import_path(path: str) -> ModuleType:
    """
    Import a python module from a path. Useful for loading python modules from
    files that lack a ".py" extension.
    """
    fname, _ = os.path.splitext(os.path.basename(path))
    loader = importlib.machinery.SourceFileLoader(fname, path)
    modspec = importlib.util.spec_from_loader(fname, loader)

    if modspec is None:
        raise ModuleNotFoundError(f"Failed to load module from {path}")

    mod = importlib.util.module_from_spec(modspec)
    loader.exec_module(mod)
    return mod
