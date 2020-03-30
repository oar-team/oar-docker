# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import json
import os.path as op
import pprint

from io import open
from .utils import touch


LOCAL_HOSTS = """
#############################
# Custom oardocker hosts file
#############################
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback

# Containers
"""


class State(dict):
    DEFAULTS = {"images": [], "containers": [], "network_id": None}
    DEFAULT_MANIFEST = {
        "parents": [
            "common"
        ],
        "ignore_if_exists": ["custom_setup.sh"],
        "install_script": "/root/install_oar.sh",
        "install_software_name": "OAR",
        "install_on": ["node", "frontend", "server"],
        "build_order": ["base", "rsyslog", "frontend", "node", "server"],
        "net_services": {
            "Python API": "/newoarapi",
            "Private Python API": "/newoarapi-priv",
            "Perl API": "/oarapi",
            "Private Perl API": "/oarapi-priv",
            "Monika": "/monika",
            "Drawgantt": "/drawgantt-svg/",
            "PhpPgAdmin": "/phppgadmin/"
        }
    }

    def __init__(self, ctx, state_file, manifest_file):
        dict.__init__(self, self.DEFAULTS)
        self.ctx = ctx
        self.state_file = state_file
        self.manifest_file = manifest_file
        self.manifest = {}
        self.load()

    def load(self):
        if op.isfile(self.state_file):
            try:
                with open(self.state_file, 'rt') as json_file:
                    self.update(json.loads(json_file.read()))
            except:
                pass
        if op.isfile(self.manifest_file):
            with open(self.manifest_file, 'rt') as json_file:
                self.manifest = json.loads(json_file.read())
        else:
            self.manifest = self.DEFAULT_MANIFEST.copy()

    def update_list_containers(self):
        containers = []
        for container in self.ctx.docker.get_containers():
            containers.append(container.short_id)
        self["containers"] = list(set(containers))

    def update_list_images(self):
        images = []
        for image in self.ctx.docker.get_images():
            images.append(image["Id"][:12])
        self["images"] = list(set(images))

    def fast_dump(self):
        if op.isdir(self.ctx.envdir):
            touch(self.state_file)
            if op.isdir(op.dirname(self.state_file)):
                with open(self.state_file, "w", encoding='utf8') as json_file:
                    json_file.write(json.dumps(self, ensure_ascii=False))

    def dump(self):
        if op.isdir(self.ctx.envdir):
            self.update_list_containers()
            self.update_list_images()
            touch(self.state_file)
            if op.isdir(op.dirname(self.state_file)):
                with open(self.state_file, "w", encoding='utf8') as json_file:
                    json_file.write(json.dumps(self, ensure_ascii=False))

    def __str__(self):
        return pprint.pprint(self)
