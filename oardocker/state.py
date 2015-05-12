# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import json
import os.path as op
import pprint

from io import open
from .utils import touch
from .compat import iteritems


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
    DEFAULTS = {"images": [], "containers": [], "dns": {}}

    def __init__(self, ctx, state_file, dns_file):
        dict.__init__(self, self.DEFAULTS)
        self.ctx = ctx
        self.state_file = state_file
        self.dns_file = dns_file
        self.load()

    def load(self):
        if op.isfile(self.state_file):
            try:
                with open(self.state_file, 'rt') as json_file:
                    self.update(json.loads(json_file.read()))
            except:
                pass

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

    def dump(self):
        if op.isdir(self.ctx.envdir):
            self.update_list_containers()
            self.update_list_images()
            touch(self.state_file)
            if op.isdir(op.dirname(self.state_file)):
                with open(self.state_file, "w", encoding='utf8') as json_file:
                    json_file.write(json.dumps(self, ensure_ascii=False))

    def update_etc_hosts(self, container=None):
        if container is not None:
            container.inspect()
            ipaddress = container.dictionary["NetworkSettings"]["IPAddress"]
            hostname = container.dictionary["Config"]["Hostname"]
            self["dns"][hostname] = ipaddress
        hosts = ("%s %s" % (ip, name) for name, ip in iteritems(self["dns"]))
        touch(self.dns_file)
        with open(self.dns_file, "w") as fd:
            fd.write(LOCAL_HOSTS + '\n'.join(hosts) + '\n')

    def empty_etc_hosts(self):
        self["dns"] = {}
        self.update_etc_hosts()

    def __str__(self):
        return pprint.pprint(self)
