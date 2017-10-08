# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import click
from ..actions import install
from ..context import pass_context, on_started, on_finished


@click.command('install')
@click.argument('src')
@pass_context
@on_finished(lambda ctx: ctx.state.dump())
@on_finished("clean")
@on_started("stop")
@on_started(lambda ctx: ctx.assert_valid_env())
def cli(ctx, src):
    """Install and configure OAR from src"""
    install(ctx, src,
            needed_tag="base",
            tag="latest",
            parent_cmd="oardocker build")
