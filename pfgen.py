#!/usr/bin/env python

from __future__ import print_function

"""
Puppetfile generator
"""

import os
import sys
import json
import argparse
from github import Github
from configparser import SafeConfigParser
from distutils.version import LooseVersion

def importRepo(username, reponame):
    print("repo: "+username+"/"+reponame)

def importUser(username):
    print("user: "+username)

if __name__ == '__main__':
    try:
        basedir = sys.argv[1]
    except IndexError:
        basedir = '.'

    config = SafeConfigParser()
    config.read(basedir+'/pfgen.config')

    try:
        GH_TOKEN = config.get('github', 'token').strip('"').strip()
    except:
        sys.exit("ERROR: PAT is mandatory")

    try:
        debug = config.getboolean('github', 'debug')
    except:
        debug=False

    for section in config.sections():
        if section!="github":
            if "/" in section:
                section_parts = section.split('/')
                importRepo(section_parts[0], section_parts[1])
            else:
                importUser(section)
