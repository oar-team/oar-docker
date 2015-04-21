# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import time
import click
import docker

from sh import bash
from subprocess import call

from oardocker.utils import find_executable
from oardocker.container import Container


DEFAULT_DOCKER_API_VERSION = "1.15"


class Docker(object):

    def __init__(self, ctx, docker_host, docker_binary):
        self.docker_host = docker_host
        self.docker_exe = find_executable(docker_binary)
        self.ctx = ctx
        self.api = docker.Client(base_url=self.docker_host, timeout=10,
                                 version=DEFAULT_DOCKER_API_VERSION)

    def cli(self, call_args, _iter=False):
        if self.docker_exe is None:
            raise click.ClickException("Cannot find docker executable in your"
                                       " PATH")
        args = call_args[:]
        args.insert(0, self.docker_exe)
        shell_args = ' '.join(args)
        self.ctx.vlog("Running : %s" % shell_args)
        if _iter:
            return bash("-c", shell_args, _iter=True)
        else:
            return call(args)

    def remove_image(self, image, force=True):
        image_name = ', '.join(image["RepoTags"])
        image_id = image["Id"]
        self.api.remove_image(image_id, force=force)
        removed = click.style("Removed", fg="blue")
        self.ctx.log("Image %s (%s) --> %s" % (image_name, image_id, removed))

    def save_image(self, image_id, repository, tag):
        saved = click.style("Saved", fg="green")
        image_name = "%s:%s" % (repository, tag)
        self.api.tag(image_id, repository=repository, tag=tag, force=True)
        self.ctx.log("Image %s (%s) --> %s" % (image_name, image_id, saved))

    def get_containers(self):
        state_containers_ids = [i[:12] for i in self.ctx.state["containers"]]
        containers = self.api.containers(quiet=False, all=True,
                                         trunc=False, latest=False)
        for container in containers:
            cid = container["Id"][:12]
            cname = ''.join(container["Names"] or []).lstrip("/")
            if (cid not in state_containers_ids
                    and cname not in self.ctx.state["containers"]):
                continue
            yield Container(self, container)

    def get_images(self):
        state_images_ids = [i[:12] for i in self.ctx.state["images"]]
        images = self.api.images(name=None, quiet=False,
                                 all=False, viz=False)
        for image in images:
            image_id = image["Id"][:12]
            image_name = image["RepoTags"][0]
            if (image_id not in state_images_ids
                    and image_name not
                    in self.ctx.state["images"]):
                continue
            yield image

    def generate_container_name(self):
        return "%s_%s" % (self.ctx.prefix, time.time())
