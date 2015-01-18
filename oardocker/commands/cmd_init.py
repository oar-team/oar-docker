import os
import os.path as op
import click

from ..utils import copy_tree
from ..context import pass_context, on_finished


TEMPLATES_PATH = op.abspath(op.join(op.dirname(__file__), '..', 'templates'))
VARIANTS = os.listdir(TEMPLATES_PATH)


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
    copy_tree(templates_dir, ctx.envdir, force)
    ctx.log('Initialized oardocker environment in %s',
            click.format_filename(ctx.envdir))
    with open(ctx.env_file, "w+") as fd:
        fd.write(env)
