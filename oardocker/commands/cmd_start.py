# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import os
import click
import socket

from ..actions import deploy
from ..context import pass_context, on_started, on_finished


def print_webservices_info(ctx, port_bindings_offset, port_bindings_to_any):
    infos = []
    if "net_services" in ctx.state.manifest.keys():
        net_services = ctx.state.manifest["net_services"]
    elif "web_services" in ctx.state.manifest.keys():
        # try "web_services", for backward compatibility
        net_services = ctx.state.manifest["web_services"]
    else:
        raise Exception("Cannot find a 'net_services' or 'web_services' entry in the manifest.json file")
    max_key_length = max((len(x[0]) for x in net_services)) + 2
    for item in net_services:
        key_title = ('{:>%s}' % max_key_length).format(item[0])
        if len(item) < 3:
            item.append("80")
        if len(item) < 4:
            item.append("http://")
        url = "%s%s:%s%s" % (item[3],
                             socket.gethostname() if port_bindings_to_any else "localhost",
                             port_bindings_offset + int(item[2]),
                             item[1])
        infos.append("%s: %s" % (key_title, url))

        pass
    max_line_length = max((len(line.strip('\n')) for line in infos))
    infos.append("\n%s\n" % ("*" * max_line_length))
    infos.insert(0, ('\n{:*^%d}\n' % max_line_length).format(' Network Services '))
    print_infos = '\n'.join(infos)
    click.echo(print_infos)


@click.command('start')
@click.option('-n', '--nodes', type=int, default=3, help="The cluster size")
@click.option('-v', '--volume', 'volumes', multiple=True,
              help="Bind mount a volume (e.g.: -v /host:/container)")
@click.option('-e', '--env', 'envs', multiple=True,
              help="Set environment variables")
@click.option('-X', '--enable-x11', is_flag=True, default=False,
              help="Allow containers to display X11 applications")
@click.option('--port-bindings-offset', type=int,
              help="Set the offset for the port bindings", default=40000,
              show_default=True)
@click.option('-g', '--port_bindings-to-any', is_flag=True,
              help="Make port bindings listen to any (0.0.0.0)")
@pass_context
@on_finished(lambda ctx: ctx.state.dump())
@on_started("stop")
@on_started(lambda ctx: ctx.assert_valid_env())
def cli(ctx, nodes, volumes, envs, enable_x11, port_bindings_offset, port_bindings_to_any):
    """Create and start the nodes"""
    env = {}
    volumes = list(volumes)
    for item in envs:
        key, value = item.strip().split("=")
        env[key] = value
    if enable_x11:
        env["DISPLAY"] = os.environ["DISPLAY"]
        volumes.append("/tmp/.X11-unix:/tmp/.X11-unix")
    with open(ctx.nodes_file, "w") as fd:
        fd.write('\n'.join(("node%d" % i for i in range(1, nodes + 1))))
        fd.write('\n')
    deploy(ctx, nodes, volumes, port_bindings_offset, port_bindings_to_any, "latest",
           "oardocker install", env)
    print_webservices_info(ctx, port_bindings_offset, port_bindings_to_any)
