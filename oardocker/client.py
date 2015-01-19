# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import time
import click
import docker

from sh import bash
from subprocess import call

from oardocker.utils import find_executable
from oardocker.container import Container


class Docker(object):

    def __init__(self, ctx, docker_host, docker_binary):
        self.docker_host = docker_host
        self.docker_exe = find_executable(docker_binary)
        self.ctx = ctx
        self.api = docker.Client(base_url=self.docker_host, timeout=10)

    def cli(self, call_args, _iter=False):
        if self.docker_exe is None:
            raise click.ClickException("Cannot find docker executable in your"
                                       " PATH")
        args = call_args[:]
        args.insert(0, self.docker_exe)
        if _iter:
            shell_args = ' '.join(args)
            self.ctx.vlog("Running '%s'" % shell_args)
            return bash("-c", shell_args, _iter=True)
        else:
            return call(args)

    def remove_image(self, image, force=True):
        image_name = ', '.join(image["RepoTags"])
        image_id = image["Id"]
        self.api.remove_image(image_id, force=force)
        removed = click.style("Removed", fg="blue")
        self.ctx.log("Image %s (%s) --> %s" % (image_id, image_name, removed))

    def save_image(self, image_id, repository, tag):
        saved = click.style("Saved", fg="green")
        image_name = "%s:%s" % (repository, tag)
        self.api.tag(image_id, repository=repository, tag=tag, force=True)
        self.ctx.log("Image %s (%s) --> %s" % (image_id, image_name, saved))

    def get_containers(self):
        state_containers = self.ctx.state["containers"]
        containers = self.api.containers(quiet=False, all=True,
                                         trunc=False, latest=False)
        for container in containers:
            cid = container["Id"][:12]
            cname = ''.join(container["Names"][:12]).lstrip("/")
            if not cid in state_containers and not cname in state_containers:
                continue
            yield Container(self, container)

    def get_images(self):
        state_images = [i[:12] for i in self.ctx.state["images"]]
        images = self.api.images(name=None, quiet=False,
                                 all=False, viz=False)
        for image in images:
            if not image["Id"][:12] in state_images:
                continue
            yield image

    def generate_container_name(self):
        return "%s_%s" % (self.ctx.prefix, time.time())