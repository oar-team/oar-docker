import click
from oardocker.cli import pass_context, pass_state, invoke_after_stop, \
    invoke_before_clean
from oardocker.actions import install


@click.command('install')
@click.argument('src')
@pass_state
@pass_context
@invoke_after_stop
@invoke_before_clean
def cli(ctx, state, src):
    """Install and configure OAR from src"""
    install(ctx, state, src,
            needed_tag="base",
            tag="latest",
            parent_cmd="build")
