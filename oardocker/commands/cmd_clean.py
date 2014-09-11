import click
from oardocker.cli import pass_context, pass_state


@click.command('clean')
@pass_state
@pass_context
def cli(ctx, state):
    """Remove all stopped containers and untagged images"""
    removed = click.style("removed", fg="blue")
    for container in ctx.get_containers(state):
        if not container.is_running:
            image_name = container.dictionary['Config']['Image']
            container.remove(v=False, link=False, force=True)
            ctx.log("Container %s --> %s" % (container.name, removed))

    for image in ctx.get_images(state):
        image_name = ', '.join(image["RepoTags"])
        # remove untagged image
        if image_name == "<none>:<none>":
            ctx.remove_image(image, force=True)
