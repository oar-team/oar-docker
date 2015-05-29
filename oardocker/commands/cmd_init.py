# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import os
import os.path as op
import random

import click

from ..utils import copy_tree
from ..context import pass_context, on_finished


TEMPLATES_PATH = op.abspath(op.join(op.dirname(__file__), '..', 'templates'))
VARIANTS = set(os.listdir(TEMPLATES_PATH)) - set(["common"])


@click.command('init')
@click.option('-f', '--force', is_flag=True, help='Overwrite existing env')
@click.option('-e', '--env', default="wheezy",
              help='Use variant X of the Dockerfiles [default: wheezy]',
              type=click.Choice(VARIANTS))
@pass_context
@on_finished(lambda ctx: ctx.state.dump())
def cli(ctx, force, env):
    """Initialize a new environment."""
    templates_dir = os.path.join(TEMPLATES_PATH, env)
    common_templates_dir = os.path.join(TEMPLATES_PATH, "common")
    ignore = ["custom_setup.sh"]
    copy_tree(common_templates_dir, ctx.envdir,
              overwrite=force, ignore_if_exists=ignore)
    copy_tree(templates_dir, ctx.envdir,
              overwrite=True, ignore_if_exists=ignore)
    ctx.log('Initialized oardocker environment in %s',
            click.format_filename(ctx.envdir))
    env_id = "%x" % random.getrandbits(32)
    ctx.init_workdir(env_name=env, env_id=env_id)
