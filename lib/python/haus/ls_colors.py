# Copyright (c) 2011-2023 Sung Pae <self@sungpae.com>

"""
LS_COLORS module.
"""

import os
import re
import stat
import sys
from enum import Enum
from typing import IO, Dict, NamedTuple

from haus import sgr

RE_ALL_ZEROS = re.compile(r"\A0+\Z")


class LSColors(NamedTuple):
    """
    File type -> SGR code mappings.
    Names, defaults, and comments are from dircolors(1).
    """

    normal: str = ""  # no color code at all
    file: str = ""  # regular file: use no color at all
    reset: str = ""  # reset to "normal" color
    dir: str = "01;34"  # directory
    link: str = "01;36"  # symbolic link
    multihardlink: str = ""  # regular file with more than one link
    fifo: str = "40;33"  # pipe
    sock: str = "01;35"  # socket
    door: str = "01;35"  # door
    blk: str = "40;33;01"  # block device driver
    chr: str = "40;33;01"  # character device driver
    orphan: str = "40;31;01"  # symlink to nonexistent file, or non-stat'able file ...
    missing: str = ""  # ... and the files they point to
    setuid: str = "37;41"  # file that is setuid (u+s)
    setgid: str = "30;43"  # file that is setgid (g+s)
    capability: str = ""  # file with capability (very expensive to lookup)
    sticky_other_writable: str = "30;42"  # dir that is sticky and other-writable
    other_writable: str = "34;42"  # dir that is other-writable (o+w) and not sticky
    sticky: str = "37;44"  # dir with the sticky bit set (+t) and not other-writable
    exec: str = "01;32"  # This is for files with execute permission
    extensions: Dict[str, str] = {}

    def format(self, path: str, st: os.stat_result, file: IO = sys.stdout) -> str:
        ftype = get_ftype(path, st)
        code = getattr(self, ftype.name)

        if self.extensions and RE_ALL_ZEROS.search(code):
            _, ext = os.path.splitext(path)
            code = self.extensions.get(ext, "")

        return sgr.format(path, code, file=file)


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


def parse_ls_colors(string: str) -> LSColors:
    if string.find("=") > -1:
        return _parse_gnu_ls_colors(string)
    else:
        return _parse_bsd_ls_colors(string)


def _parse_gnu_ls_colors(string: str) -> LSColors:
    d = {}
    ext = {}

    for entry in [e for e in string.split(":") if len(e) == 2]:
        key, code = entry.split("=", 1)
        if prop := DIR_COLORS_ABBREVS.get(key):
            d[prop.name] = code
        elif key.startswith("."):
            ext[key] = code

    return LSColors(extensions=ext, **d)


def _parse_bsd_ls_colors(string: str) -> LSColors:
    raise NotImplementedError


def get_ftype(path: str, st: os.stat_result) -> FTYPE:
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
