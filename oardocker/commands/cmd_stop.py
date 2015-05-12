# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import click
from ..context import pass_context, on_started, on_finished


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
        image_name = container.dictionary['Config']['Image']
        container.kill("SIGINT")
        container.wait()
        ctx.log("Container %s --> %s" % (name, stopped))
        container.remove(v=False, link=False, force=True)
        ctx.log("Container %s --> %s" % (name, removed))
        # remove untagged image
        if not image_name.startswith(ctx.prefix):
            ctx.docker.remove_image(image_name, force=True)
    ctx.state.empty_etc_hosts()
