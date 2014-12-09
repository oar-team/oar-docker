import click
from oardocker.cli import pass_context, pass_state
from oardocker.actions import execute


@click.command('exec')
@click.option('-l', '--user', default="docker")
@click.option('-w', '--workdir', default="~")
@click.argument('hostname', required=True)
@click.argument('cmd', nargs=-1)
@pass_state
@pass_context
def cli(ctx, state, user, workdir, hostname, cmd):
    """Run a command in an existing node."""
    execute(ctx, state, user, hostname, cmd, workdir)
