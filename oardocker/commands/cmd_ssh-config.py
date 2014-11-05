import click
from oardocker.cli import pass_context, pass_state, deprecated_cmd
from oardocker.actions import generate_ssh_config


@click.command('ssh-config')
@pass_state
@pass_context
@deprecated_cmd()
def cli(ctx, state):
    """Output OpenSSH valid ssh config [deprecated]"""
    generate_ssh_config(ctx, state)
    with open(ctx.ssh_config, "r") as ssh_config:
        click.echo(ssh_config.read())
