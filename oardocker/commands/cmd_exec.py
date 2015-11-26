# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import click
from ..context import pass_context, on_started, on_finished
from ..actions import execute


@click.command('exec')
@click.option('-l', '--user', default="docker")
@click.option('-w', '--workdir', default="~")
@click.option('-t', '--tty/--no-tty', is_flag=True, default=True,
              help='Allocate a pseudo-TTY')
@click.argument('hostname', required=True)
@click.argument('cmd', nargs=-1)
@pass_context
@on_finished(lambda ctx: ctx.state.dump())
@on_started(lambda ctx: ctx.assert_valid_env())
def cli(ctx, user, workdir, tty, hostname, cmd):
    """Run a command in an existing node."""
    execute(ctx, user, hostname, cmd, workdir, tty)
