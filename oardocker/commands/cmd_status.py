import click
import arrow
from oardocker.cli import pass_context, pass_state
from tabulate import tabulate
from oardocker.utils import human_filesize


def get_containers_table(ctx, state):
    containers = ctx.get_containers(state)
    rows = []
    for c in containers:
        image_name = c.dictionary['Config']['Image']
        created = arrow.get(c.dictionary['Created']).humanize()
        if c.is_running:
            status = click.style(c.human_readable_state, fg="green")
        else:
            status = click.style(c.human_readable_state, fg="red")
        rows.append([c.hostname, c.ip, status, c.human_readable_ports,
                    c.short_id, image_name, created])
    if not rows:
        rows.append(["", "", "", "", "", "", ""])
    return rows, ["Containers", "IP", "Status", "Ports", "ID", "Image",
                  "Created"]


def get_images_table(ctx, state):
    images = ctx.get_images(state)
    rows = []
    for im in images:
        name = im["RepoTags"][0]
        comment = ctx.docker.inspect_image(im["Id"])["Comment"]
        imgid = im["Id"][:12]
        created = arrow.get(im['Created']).humanize()
        virtsize = im["VirtualSize"]
        rows.append([name, imgid, created, human_filesize(virtsize), comment])
    if not rows:
        rows.append(["", "", "", "", ""])
    return rows, ["Images", "ID", "Created", "Virtual Size", "Comment"]


@click.command('status')
@pass_state
@pass_context
def cli(ctx, state):
    """Output status of the cluster"""
    images_table, images_headers = get_images_table(ctx, state)
    click.echo(tabulate(images_table, headers=images_headers))
    click.echo("")
    c_table, c_headers = get_containers_table(ctx, state)
    click.echo(tabulate(c_table, headers=c_headers))
