# Copyright (c) 2011-2023 Sung Pae <self@sungpae.com>

"""
LS_COLORS module.
"""

import os
import stat
import sys
from enum import Enum
from typing import IO, Any, List, Mapping, NamedTuple, Optional

from haus import sgr


class LSColors(NamedTuple):
    """
    File type -> SGR code mappings.
    Names, defaults, and comments are from dircolors(1).
    """

    normal: List[str] = []
    file: List[str] = []
    reset: List[str] = []
    dir: List[str] = ["01;34"]  # directory
    link: List[str] = ["01;36"]  # symbolic link
    multihardlink: List[str] = []  # regular file with more than one link
    fifo: List[str] = ["40;33"]  # pipe
    sock: List[str] = ["01;35"]  # socket
    door: List[str] = ["01;35"]  # door
    blk: List[str] = ["40;33;01"]  # block device driver
    chr: List[str] = ["40;33;01"]  # character device driver
    orphan: List[str] = ["40;31;01"]  # broken symlink or non-stat'able file
    missing: List[str] = []  # ... and the files they point to
    setuid: List[str] = ["37;41"]  # file that is setuid (u+s)
    setgid: List[str] = ["30;43"]  # file that is setgid (g+s)
    capability: List[str] = []  # file with capability (very expensive to lookup)
    sticky_other_writable: List[str] = ["30;42"]  # dir: sticky and other-writable
    other_writable: List[str] = ["34;42"]  # dir: !sticky and other-writable
    sticky: List[str] = ["37;44"]  # dir: sticky and not other-writable
    exec: List[str] = ["01;32"]  # This is for files with execute permission
    extensions: Mapping[str, List[str]] = {}

    def format(self, path: str, st: os.stat_result, file: IO[Any] = sys.stdout) -> str:
        ftype = get_ftype(path, st)
        styles = getattr(self, ftype.name)

        if not styles and self.extensions:
            _, ext = os.path.splitext(path)
            styles = self.extensions.get(ext, "")

        return sgr.format(path, styles, file=file)


FTYPE = Enum(
    "FTYPE",
    (
        "normal",
        "file",
        "reset",
        "dir",
        "link",
        "multihardlink",
        "fifo",
        "sock",
        "door",
        "blk",
        "chr",
        "orphan",
        "missing",
        "setuid",
        "setgid",
        "capability",
        "sticky_other_writable",
        "other_writable",
        "sticky",
        "exec",
    ),
)

DIR_COLORS_ABBREVS = {
    "no": FTYPE.normal,
    "fi": FTYPE.file,
    "rs": FTYPE.reset,
    "di": FTYPE.dir,
    "ln": FTYPE.link,
    "mh": FTYPE.multihardlink,
    "pi": FTYPE.fifo,
    "so": FTYPE.sock,
    "do": FTYPE.door,
    "bd": FTYPE.blk,
    "cd": FTYPE.chr,
    "or": FTYPE.orphan,
    "mi": FTYPE.missing,
    "su": FTYPE.setuid,
    "sg": FTYPE.setgid,
    "ca": FTYPE.capability,
    "tw": FTYPE.sticky_other_writable,
    "ow": FTYPE.other_writable,
    "st": FTYPE.sticky,
    "ex": FTYPE.exec,
}


def parse_ls_colors(string: Optional[str]) -> LSColors:
    """
    Parse an LS_COLORS environment string. Returns an object with default
    values if string is None or empty.
    """
    if string:
        if string.find("=") > -1:
            return _parse_gnu_ls_colors(string)
        else:
            return _parse_bsd_ls_colors(string)

    return LSColors()


def _parse_gnu_ls_colors(string: str) -> LSColors:
    d = {}
    ext = {}

    for entry in [e for e in string.split(":") if "=" in e]:
        key, style = entry.split("=", 1)
        if prop := DIR_COLORS_ABBREVS.get(key):
            d[prop.name] = [style]
        elif key.startswith("."):
            ext[key] = [style]

    return LSColors(extensions=ext, **d)


def _parse_bsd_ls_colors(string: str) -> LSColors:
    raise NotImplementedError


def get_ftype(path: str, st: Optional[os.stat_result]) -> FTYPE:
    if st is None:
        return FTYPE.missing

    elif stat.S_ISREG(st.st_mode):
        if st.st_mode & stat.S_ISUID:
            return FTYPE.setuid
        elif st.st_mode & stat.S_ISGID:
            return FTYPE.setgid
        # elif ...:
        #     return FTYPE.capability
        elif st.st_mode & 0o111:
            return FTYPE.exec
        elif st.st_nlink > 1:
            return FTYPE.multihardlink
        else:
            return FTYPE.file

    elif stat.S_ISDIR(st.st_mode):
        sticky = st.st_mode & stat.S_ISVTX
        other_wr = st.st_mode & stat.S_IWOTH

        if sticky and other_wr:
            return FTYPE.sticky_other_writable
        elif other_wr:
            return FTYPE.other_writable
        elif sticky:
            return FTYPE.sticky
        else:
            return FTYPE.dir

    elif stat.S_ISLNK(st.st_mode):
        if os.path.exists(os.path.realpath(path)):
            return FTYPE.link
        else:
            return FTYPE.orphan

    # Special files
    elif stat.S_ISFIFO(st.st_mode):
        return FTYPE.fifo
    elif stat.S_ISSOCK(st.st_mode):
        return FTYPE.sock
    elif stat.S_ISCHR(st.st_mode):
        return FTYPE.chr
    elif stat.S_ISBLK(st.st_mode):
        return FTYPE.blk
    elif stat.S_ISDOOR(st.st_mode):
        return FTYPE.door
    else:
        return FTYPE.missing
