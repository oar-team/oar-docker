import click
from ..context import pass_context, on_started, on_finished


@click.command('clean')
@pass_context
@on_finished(lambda ctx: ctx.state.dump())
@on_started(lambda ctx: ctx.assert_valid_env())
def cli(ctx):
    """Remove all stopped containers and untagged images"""
    removed = click.style("removed", fg="blue")
    for container in ctx.docker.get_containers():
        if not container.is_running:
            image_name = container.dictionary['Config']['Image']
            container.remove(v=False, link=False, force=True)
            ctx.log("Container %s --> %s" % (container.name, removed))

    already_printed = False
    for image in ctx.docker.get_images():
        image_name = ', '.join(image["RepoTags"])
        if image_name == "<none>:<none>":
            if not already_printed:
                ctx.log("Removing untagged images")
                already_printed = True
            ctx.docker.remove_image(image, force=True)
