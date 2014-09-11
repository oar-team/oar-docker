import click
from oardocker.cli import pass_context, pass_state, invoke_after_stop


@click.command('destroy')
@click.confirmation_option('-f', '--force',
                           prompt="Are you sure you want to destroy all images?")
@pass_state
@pass_context
@invoke_after_stop
def cli(ctx, state):
    """Stop containers and remove all images"""
    for image in ctx.get_images(state):
        ctx.remove_image(image)
