import click
from oardocker.cli import pass_context, pass_state

from oardocker.utils import empty_file


@click.command('stop')
@pass_state
@pass_context
def cli(ctx, state):
    """Stop and remove all containers"""
    stopped = click.style("Stopped", fg="red")
    removed = click.style("Removed", fg="blue")
    for container in ctx.get_containers(state):
        name = container.name
        image_name = container.dictionary['Config']['Image']
        container.kill()
        container.stop()
        ctx.log("Container %s --> %s" % (name, stopped))
        container.remove(v=False, link=False, force=True)
        ctx.log("Container %s --> %s" % (name, removed))
        # remove untagged image
        if not image_name.startswith(ctx.prefix):
            ctx.docker.remove_image(image_name, force=True)
    empty_file(ctx.ssh_config)
    empty_file(ctx.dnsfile)
