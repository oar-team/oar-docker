import click
from oardocker.cli import pass_context, pass_state
from oardocker.actions import execute


@click.command('connect')
@click.option('-l', '--user', default="docker")
@click.option('-w', '--workdir', default="~")
@click.option('-s', '--shell', default="bash")
@click.argument('hostname', required=False, default="frontend")
@pass_state
@pass_context
def cli(ctx, state, user, workdir, shell, hostname):
    """Connect to a node."""
    cmd = ["cat /etc/motd", "&&", shell]
    execute(ctx, state, user, hostname, cmd, workdir)
