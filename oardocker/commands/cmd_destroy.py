# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import click
from ..context import pass_context, on_started, on_finished


@click.command('destroy')
@click.confirmation_option('-f', '--force',
                           prompt="Are you sure you want to destroy "
                                  "all images?")
@pass_context
@on_finished(lambda ctx: ctx.state.dump())
@on_started("stop")
@on_started(lambda ctx: ctx.assert_valid_env())
def cli(ctx):
    """Stop containers and remove all images"""
    for image in ctx.docker.get_images():
        ctx.docker.remove_image(image)
