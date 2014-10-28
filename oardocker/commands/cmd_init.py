import click
import os.path as op
from oardocker.cli import pass_context
from oardocker.utils import touch
import uuid


@click.command('init')
@click.option('-f', '--force', is_flag=True, help='Overwrite existing env')
@pass_context
def cli(ctx, force):
    """Initialize a new environment."""
    ctx.copy_tree(ctx.templates_dir, ctx.envdir, force)
    touch(ctx.dnsfile)
    touch(ctx.ssh_config)
    ctx.log('Initialized oardocker environment in %s',
            click.format_filename(ctx.envdir))
    if not op.exists(ctx.envid_file) or op.getsize(ctx.envid_file) == 0:
        identifier = uuid.uuid5(uuid.NAMESPACE_URL, ctx.envid_file)
        with open(ctx.envid_file, "w+") as fd:
            fd.write("%s" % identifier)
