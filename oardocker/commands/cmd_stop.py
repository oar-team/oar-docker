# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import click
from ..context import pass_context, on_started, on_finished


TO_KILL = ["rsyslog"]


@click.command('stop')
@pass_context
@on_finished(lambda ctx: ctx.state.dump())
@on_started(lambda ctx: ctx.assert_valid_env())
def cli(ctx):
    """Stop and remove all nodes"""
    stopped = click.style("Stopped", fg="red")
    removed = click.style("Removed", fg="blue")
    for container in ctx.docker.get_containers():
        name = container.hostname
        node_name = ''.join([i for i in name if not i.isdigit()])
        image_name = container.dictionary['Config']['Image']
        if node_name in TO_KILL:
            container.stop(timeout=0)
        else:
            container.stop(timeout=5)
            # container.execute("poweroff", "root", "/", False)
            # container.wait()
        ctx.log("Container %s --> %s" % (name, stopped))
        container.remove(v=False, link=False, force=True)
        ctx.log("Container %s --> %s" % (name, removed))
        ctx.state['containers'].remove(container.short_id)
        ctx.state.fast_dump()
        # remove untagged image
        if not image_name.startswith(ctx.prefix):
            ctx.docker.remove_image(image_name, force=True)
    ctx.docker.remove_network()
