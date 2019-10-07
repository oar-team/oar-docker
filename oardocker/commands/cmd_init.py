# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import os
import os.path as op
import json
import random

from io import open

import click

from ..utils import copy_tree
from ..context import pass_context, on_finished
from ..compat import iterkeys


TEMPLATES_PATH = op.abspath(op.join(op.dirname(__file__), '..', 'templates'))
VARIANTS = {}
for dirpath in set(os.listdir(TEMPLATES_PATH)):
    manifest_file = os.path.join(TEMPLATES_PATH, dirpath, 'manifest.json')
    if op.isfile(manifest_file):
        with open(manifest_file, 'rt') as json_file:
            manifest = json.loads(json_file.read())
            VARIANTS[dirpath] = manifest


@click.command('init')
@click.option('-f', '--force', is_flag=True, help='Overwrite existing env')
@click.option('-e', '--env', default="buster",
              help='Use variant X of the Dockerfiles', show_default=True,
              type=click.Choice(list(iterkeys(VARIANTS))))
@pass_context
@on_finished(lambda ctx: ctx.state.dump())
def cli(ctx, force, env):
    """Initialize a new environment."""
    templates_dir = os.path.join(TEMPLATES_PATH, env)
    manifest = VARIANTS[env]
    overwrite = force
    for parent in manifest.get('parents', []):
        common_templates_dir = os.path.join(TEMPLATES_PATH, parent)
        copy_tree(common_templates_dir, ctx.envdir,
                  overwrite=overwrite,
                  ignore_if_exists=manifest['ignore_if_exists'])
        overwrite = True

    copy_tree(templates_dir, ctx.envdir,
              overwrite=overwrite,
              ignore_if_exists=manifest['ignore_if_exists'])
    ctx.log('Initialized oardocker environment in %s',
            click.format_filename(ctx.envdir))
    env_id = "%x" % random.getrandbits(32)
    ctx.init_workdir(env_name=env, env_id=env_id)
