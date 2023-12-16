# Copyright (c) 2023 Sung Pae <self@sungpae.com>

"""
Module for obtaining a recent HTTP User-Agent.
"""

import json
import os
import random
import re
import time
from pathlib import Path
from typing import NamedTuple, Optional
from urllib import request

UA_SOURCE_URL = "https://www.useragents.me/api"
UA_CACHE_PATH = os.path.expanduser("~/.cache/http_ua.json")
SECS_PER_WEEK = 7 * 24 * 60 * 60


class UserAgentsList(NamedTuple):
    time: float
    data: list[str]

    def find(self, pattern: str) -> Optional[str]:
        """
        Return the first User-Agent that matches pattern.
        """
        for ua in self.data:
            if re.search(pattern, ua):
                return ua

        return None

    def random(self, pattern: Optional[str] = None) -> Optional[str]:
        """
        Return a random User-Agent, optionally matching pattern.
        """
        user_agents = self.data

        if pattern:
            regexp = re.compile(pattern)
            user_agents = [ua for ua in self.data if regexp.search(ua)]

        if len(user_agents) == 0:
            return None

        return random.sample(user_agents, 1)[0]


def fetch_user_agents_list() -> UserAgentsList:
    """
    Fetch user agents list from UA_SOURCE_URL.
    """
    resp = json.loads(request.urlopen(UA_SOURCE_URL).read())
    return UserAgentsList(time=time.time(), data=[x["ua"] for x in resp["data"]])


def get_user_agents_list() -> UserAgentsList:
    """
    Return a UserAgentsList object.

    Reads from UA_CACHE_PATH. If the cache file is not present or if 4 weeks
    have passed since it was last updated, a new set of user agents is fetched
    and cached from UA_SOURCE_URL.
    """
    ualist = None

    if os.path.exists(UA_CACHE_PATH):
        try:
            ualist = UserAgentsList(**json.loads(Path(UA_CACHE_PATH).read_text()))
        except json.decoder.JSONDecodeError:
            pass

    if ualist is None or time.time() - ualist.time > 4 * SECS_PER_WEEK:
        ualist = fetch_user_agents_list()
        os.makedirs(os.path.dirname(UA_CACHE_PATH), mode=0o700, exist_ok=True)
        with open(UA_CACHE_PATH, "w") as f:
            f.write(json.dumps(ualist._asdict()))

    return ualist


def get_random_user_agent(pattern: Optional[str] = None) -> str:
    """
    Return a random user agent matching pattern.
    Raises an exception if no matching user agent is found.
    """
    ua = get_user_agents_list().random(pattern)
    if ua is None:
        raise RuntimeError("Failed to find a User-Agent matching %r" % pattern)
    return ua
