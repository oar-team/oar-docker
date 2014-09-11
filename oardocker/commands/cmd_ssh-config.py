import click
from oardocker.cli import pass_context, pass_state
from oardocker.actions import generate_ssh_config


@click.command('ssh-config')
@pass_state
@pass_context
def cli(ctx, state):
    """Output OpenSSH valid configuration to connect to the machine."""
    generate_ssh_config(ctx, state)
    with open(ctx.ssh_config, "r") as ssh_config:
        click.echo(ssh_config.read())
