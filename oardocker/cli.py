# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import os
import os.path as op
import sys
import click

from . import VERSION
from .context import pass_context, CONTEXT_SETTINGS

click.disable_unicode_literals_warning = True


class OardockerCLI(click.MultiCommand):

    def list_commands(self, ctx):
        cmd_folder = op.abspath(op.join(op.dirname(__file__), 'commands'))
        commands = []
        for filename in os.listdir(cmd_folder):
            if filename.endswith('.py') and filename.startswith('cmd_'):
                commands.append(filename[4:-3])
        commands.sort()
        return commands

    def get_command(self, ctx, name):
        if sys.version_info[0] == 2:
            name = name.encode('ascii', 'replace')
        if name in self.list_commands(ctx):
            mod = __import__('oardocker.commands.cmd_' + name,
                             None, None, ['cli'])
            return mod.cli


@click.command(cls=OardockerCLI, context_settings=CONTEXT_SETTINGS, chain=True)
@click.option('--workdir', type=click.Path(exists=True, file_okay=False,
                                           resolve_path=True),
              help='Changes the folder to operate on.')
@click.option('--docker-host', default="unix://var/run/docker.sock",
              help="The docker socket [default: unix://var/run/docker.sock].")
@click.option('--cgroup-path', default="/sys/fs/cgroup",
              help="The cgroup file system path [default: /sys/fs/cgroup].")
@click.option('--docker-binary', default="docker",
              help="The docker client binary [default: docker].")
@click.option('--verbose', is_flag=True, default=False,
              help="Verbose mode.")
@click.option('--debug', is_flag=True, default=False,
              help="Enable debugging")
@click.version_option(version=VERSION)
@pass_context
def cli(ctx, workdir, docker_host, cgroup_path, docker_binary, verbose, debug):
    """Manage a small OAR developpement cluster with docker."""
    if workdir is not None:
        ctx.workdir = workdir
    ctx.docker_host = docker_host
    ctx.cgroup_path = cgroup_path
    ctx.docker_binary = docker_binary
    ctx.verbose = verbose
    ctx.debug = debug
    ctx.update()


def main(args=sys.argv[1:]):
    cli(args)
