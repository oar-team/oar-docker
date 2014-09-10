import click
from oarcluster.cli import pass_context
from oarcluster.utils import touch


@click.command('init')
@click.option('-f', '--force', is_flag=True, help='Overwrite existing env')
@pass_context
def cli(ctx, force):
    """Initialize a new environment."""
    ctx.copy_tree(ctx.templates_dir, ctx.envdir, force)
    touch(ctx.dnsfile)
    ctx.log('Initialized oarcluster environment in %s',
            click.format_filename(ctx.envdir))
