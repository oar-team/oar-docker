import os
import click
from oarcluster.cli import pass_context
from oarcluster.utils import touch


@click.command('ssh')
@click.argument('machine', required=False, default="frontend")
@pass_context
def cli(ctx, machine):
    """Connect to machine via SSH."""
    touch(ctx.ssh_config)
    os.system('ssh -vvv -F %s %s' % (ctx.ssh_config, machine))
