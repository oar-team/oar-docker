# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import click
from ..context import pass_context, on_started, on_finished
from ..actions import execute


@click.command('connect')
@click.option('-l', '--user', default="docker")
@click.option('-w', '--workdir', default="~")
@click.option('-s', '--shell', default="bash")
@click.argument('hostname', required=False, default="frontend")
@pass_context
@on_finished(lambda ctx: ctx.state.dump())
@on_started(lambda ctx: ctx.assert_valid_env())
def cli(ctx, user, workdir, shell, hostname):
    """Connect to a node."""
    cmd = ["cat /etc/motd && %s" % shell]
    execute(ctx, user, hostname, cmd, workdir, tty=True)
