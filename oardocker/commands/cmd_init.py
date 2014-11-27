import os
import click
from oardocker.cli import pass_context, VARIANTS, TEMPLATES_PATH
from oardocker.utils import touch


@click.command('init')
@click.option('-f', '--force', is_flag=True, help='Overwrite existing env')
@click.option('-e', '--env', default="wheezy",
              help='Use variant X of the Dockerfiles [default: wheezy]',
              type=click.Choice(VARIANTS))
@pass_context
def cli(ctx, force, env):
    """Initialize a new environment."""
    templates_dir = os.path.join(TEMPLATES_PATH, env)
    ctx.copy_tree(templates_dir, ctx.envdir, force)
    touch(ctx.dnsfile)
    touch(ctx.ssh_config)
    ctx.log('Initialized oardocker environment in %s',
            click.format_filename(ctx.envdir))
    with open(ctx.env_file, "w+") as fd:
        fd.write(env)
